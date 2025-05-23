import 'package:flutter/material.dart';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart'; // Use the correct import for flutter_client_sse
import 'dart:async';
import 'package:shimmer/shimmer.dart';
import '../widgets/wardrobe_visualization_widget.dart'; // <-- Import the new widget

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

  // Add this class in your file, outside of any existing classes
class StylePaginationHeader extends StatelessWidget {
  final String title;
  final int currentIndex;
  final int totalStyles;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool isLoading;

  const StylePaginationHeader({
    Key? key,
    required this.title,
    required this.currentIndex,
    required this.totalStyles,
    required this.onPrevious,
    required this.onNext,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Don't show pagination controls if there are no styles
    final bool showControls = totalStyles > 0 && !isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          if (showControls) 
            Row(
              children: [
                // Previous button
                IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: currentIndex > 0 ? onPrevious : null,
                  color: currentIndex > 0 ? Theme.of(context).primaryColor : Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 5),
                  iconSize: 24,
                ),
                
                // Page indicator (e.g. "1/3")
                Text(
                  "${currentIndex + 1}/$totalStyles",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                // Next button
                IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: currentIndex < totalStyles - 1 ? onNext : null,
                  color: currentIndex < totalStyles - 1 ? Theme.of(context).primaryColor : Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(minWidth: 24, minHeight: 24),
                  iconSize: 24,
                ),
              ],
            ),
          if (isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final AuthService authService = AuthService();

  /// Main product
  Map<String, dynamic>? productDoc;
  bool isLoadingProduct = true;

  /// Similar products
  List<Map<String, dynamic>> similarProducts = [];
  bool isLoadingSimilar = true;

  /// Recommended outfits
  List<dynamic> recommendedOutfits = [];
  bool isLoadingOutfits = false;
  StreamSubscription<SSEModel>? _outfitSubscription; // Add this line

  /// Matching wardrobe items
  Map<String, dynamic>? matchingWardrobeItemsData;
  bool isLoadingWardrobeItems = true; // <-- CHANGE: Initialize to true

  /// Clothing preferences (likes & dislikes)
  Map<String?, dynamic> clothingLikes = {};
  Map<String?, dynamic> clothingDislikes = {};

  /// Disliked items waiting for new recommendation
  Set<String> _loadingReplacementIds = {};

  /// User's gender code (M, F, or null)
  String? userGenderCode;
  bool isLoadingGender = true;

  // Add these variables in the _ProductDetailPageState class
int _currentStyleIndex = 0; // Track which style is currently shown

// Methods to handle pagination
void _nextStyle() {
  setState(() {
    if (_currentStyleIndex < recommendedOutfits.length - 1) {
      _currentStyleIndex++;
    }
  });
}

void _previousStyle() {
  setState(() {
    if (_currentStyleIndex > 0) {
      _currentStyleIndex--;
    }
  });
}

  @override
  void dispose() {
    // Cancel subscription when widget is disposed
    _outfitSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // 1) Fetch main product by ID
    _fetchProductDoc();
    // 2) Also fetch user's existing likes/dislikes
    getClothingPreferences();
    // 3) Fetch user's gender
    _fetchUserGender();
  }

  /// Fetch the user's gender from the API
  Future<void> _fetchUserGender() async {
    setState(() => isLoadingGender = true);

    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final uri = Uri.parse('$baseUrl/user/gender');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userGenderCode = data['gender_code'];
          isLoadingGender = false;
        });
        debugPrint('User gender fetched: $userGenderCode');
      } else {
        throw Exception('Failed to load user gender');
      }
    } catch (error) {
      debugPrint('Error fetching user gender: $error');
      setState(() => isLoadingGender = false);
    }
  }
  // Add this function to your class to better understand the structure
// of the data coming from the SSE events

  void _debugSSEDataStructure(dynamic eventData) {
    debugPrint('==== SSE DATA STRUCTURE DEBUG ====');

    // Check style_name
    if (eventData.containsKey('style_name')) {
      debugPrint('style_name: ${eventData['style_name']}');
    } else {
      debugPrint('style_name field missing');
    }

    // Check style_index
    if (eventData.containsKey('style_index')) {
      debugPrint('style_index: ${eventData['style_index']}');
    } else {
      debugPrint('style_index field missing');
    }

    // Check style_outfits
    if (eventData.containsKey('style_outfits')) {
      final outfits = eventData['style_outfits'] as List<dynamic>? ?? [];
      debugPrint('style_outfits count: ${outfits.length}');

      // Check the first outfit if available
      if (outfits.isNotEmpty) {
        final firstOutfit = outfits[0];
        debugPrint('First outfit keys: ${firstOutfit.keys.join(', ')}');

        // Check for top_items
        if (firstOutfit.containsKey('top_items')) {
          final topItems = firstOutfit['top_items'] as List<dynamic>? ?? [];
          debugPrint('top_items count: ${topItems.length}');

          // Check the first item
          if (topItems.isNotEmpty) {
            final firstItem = topItems[0];
            debugPrint('First item keys: ${firstItem.keys.join(', ')}');
            debugPrint('First item id: ${firstItem['id']}');
            debugPrint('First item name: ${firstItem['name']}');
            debugPrint('First item category: ${firstItem['category']}');
          }
        } else {
          debugPrint('top_items field missing in first outfit');
        }

        // Check for other item lists
        final bottomItems = firstOutfit['bottom_items'] as List<dynamic>? ?? [];
        debugPrint('bottom_items count: ${bottomItems.length}');

        final shoeItems = firstOutfit['shoe_items'] as List<dynamic>? ?? [];
        debugPrint('shoe_items count: ${shoeItems.length}');
      }
    } else {
      debugPrint('style_outfits field missing');
    }

    debugPrint('==== END DEBUG ====');
  }

// Add this call to your SSE event handler, right after parsing the event data:
// _debugSSEDataStructure(eventData);

  /// Grab user's saved clothing preferences.
  Future<void> getClothingPreferences() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/getclothingprefs'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          clothingLikes =
              Map<String, dynamic>.from(jsonResponse['clothing_likes'] ?? {});
          clothingDislikes = Map<String, dynamic>.from(
              jsonResponse['clothing_dislikes'] ?? {});
        });
      }
    } catch (error) {
      debugPrint('Error fetching clothing preferences: $error');
    }
  }

  /// Step 1: Fetch the main product by ID
  Future<void> _fetchProductDoc() async {
    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final uri = Uri.parse('$baseUrl/shop/item/${widget.productId}');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productDoc = data;
          isLoadingProduct = false;
        });

        // --- TRIGGER OTHER FETCHES HERE ---
        // Now that we have productDoc, fetch related data
        // We don't need to wait for similar/recommended before fetching wardrobe
        fetchSimilarProducts();
        fetchRecommendedOutfits();
        _fetchMatchingWardrobeItems(); // <--- ADD THIS CALL HERE

      } else {
         // Handle product fetch error
        setState(() {
           isLoadingProduct = false;
           isLoadingWardrobeItems = false; // Also stop wardrobe loading if product fails
         });
        throw Exception('Failed to load product detail (${response.statusCode})');
      }
    } catch (error) {
      debugPrint('Error fetching product detail: $error');
      // Ensure loading states are reset on error
      setState(() {
        isLoadingProduct = false;
        isLoadingWardrobeItems = false; // Stop wardrobe loading on error
      });
    }
  }
  /// Step 2: fetch similar items
  Future<void> fetchSimilarProducts() async {
    if (productDoc == null) return;
    setState(() => isLoadingSimilar = true);

    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final String productId = productDoc!['id'] ?? '';
    final uri = Uri.parse('$baseUrl/shop/similar_items?id=$productId&n=5');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          similarProducts = data.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
              'url': item['image_url'] ?? '',
              'label': item['name'] ?? '',
              'price': item['price']?.toString() ?? '',
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load similar products');
      }
    } catch (error) {
      debugPrint('Error fetching similar products: $error');
    } finally {
      setState(() => isLoadingSimilar = false);
    }
  }

  Future<void> fetchRecommendedOutfits() async {
    if (productDoc == null) return;

    // Cancel existing subscription if there is one
    if (_outfitSubscription != null) {
      await _outfitSubscription!.cancel();
      _outfitSubscription = null;
    }

    setState(() {
      isLoadingOutfits = true;
      // Clear existing recommendations to avoid stale data
      recommendedOutfits = [];
    });

    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final String productId = productDoc!['id'] ?? '';
    
    // Wait for gender to be loaded if it's still loading
    if (isLoadingGender) {
      await Future.delayed(Duration(milliseconds: 300));
    }
    
    // Build URL with gender parameter if available
    String url = '$baseUrl/fast-item-outfit-search-with-style-stream?item_id=$productId';
    if (userGenderCode != null) {
      url += '&gender=$userGenderCode';
      debugPrint('Adding gender filter: $userGenderCode');
    }

    debugPrint('Starting SSE connection for product: $productId with URL: $url');

    try {
      final stream = SSEClient.subscribeToSSE(
        method: SSERequestType.GET,
        url: url,
        header: {
          'Accept': 'text/event-stream',
          'Authorization': 'Bearer $token',
          'Cache-Control': 'no-cache',
          'Connection': 'keep-alive',
        },
      );

      _outfitSubscription = stream.listen(
        (sseEvent) {
          // Fix the substring error by safely logging the data
          final dataPreview = sseEvent.data != null
              ? (sseEvent.data!.length > 50
                  ? sseEvent.data!.substring(0, 50) + '...'
                  : sseEvent.data!)
              : 'null';
          debugPrint('SSE Event received: $dataPreview');

          if (sseEvent.data != null && mounted) {
            try {
              final eventData = json.decode(sseEvent.data!);
              debugPrint('Parsed SSE data successfully');
              _debugSSEDataStructure(eventData);
              // Check if this is the final "done" event
              if (eventData['done'] == true) {
                debugPrint('Received done event, ending SSE processing');
                _outfitSubscription?.cancel();
                _outfitSubscription = null;

                // Important: update UI state to show content
                if (mounted) {
                  setState(() {
                    isLoadingOutfits = false;
                    debugPrint(
                        'Set isLoadingOutfits to false, have ${recommendedOutfits.length} items');
                  });
                }
                return;
              }

              if (mounted) {
                setState(() {
                  final index = recommendedOutfits.indexWhere(
                    (s) => s['style_index'] == eventData['style_index'],
                  );

                  if (index >= 0) {
                    final existingStyle = recommendedOutfits[index];
                    final newStyle = eventData;

                    for (int i = 0;
                        i < existingStyle['style_outfits'].length;
                        i++) {
                      final existingOutfit = existingStyle['style_outfits'][i];
                      final newOutfit = newStyle['style_outfits'][i];

                      List<String> keys = [
                        'top_items',
                        'bottom_items',
                        'shoe_items',
                        'jacket_items',
                        'accessory_items',
                        'dress_items'
                      ];

                      for (var key in keys) {
                        if (existingOutfit.containsKey(key)) {
                          List<dynamic> existingItems = existingOutfit[key];
                          List<dynamic> newItems = newOutfit[key];
                          for (int j = 0; j < existingItems.length; j++) {
                            final existingItem = existingItems[j];
                            if (existingItem != null &&
                                existingItem.containsKey('locked') &&
                                existingItem['locked'] == true) {
                              continue;
                            }
                            if (j < newItems.length) {
                              existingItems[j] = newItems[j];
                            }
                          }
                        }
                      }
                    }
                    recommendedOutfits[index] = existingStyle;
                    debugPrint(
                        'Merged new eventData into existing style at index "$index", locked items untouched.');
                  } else {
                    recommendedOutfits.add(eventData);
                    debugPrint(
                        'Added new style, now have ${recommendedOutfits.length} styles');
                  }

                  // Still loading but trigger UI update to show the items we have
                  setState(() {});
                });
              }
            } catch (e) {
              debugPrint('Error parsing SSE data: $e');
              // Don't leave the UI in a loading state if there's an error
              if (mounted) {
                setState(() => isLoadingOutfits = false);
              }
            }
          }
        },
        onError: (error) {
          debugPrint('SSE Error: $error');
          if (mounted) {
            setState(() => isLoadingOutfits = false);
          }
        },
        onDone: () {
          debugPrint('SSE Connection closed normally');
          _outfitSubscription = null;

          // Make sure we're not stuck in loading state when done
          if (mounted && isLoadingOutfits) {
            setState(() {
              isLoadingOutfits = false;
              debugPrint('Stream closed, set loading state to false');
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Exception setting up SSE connection: $e');
      if (mounted) {
        setState(() => isLoadingOutfits = false);
      }
    }
  }

  String _getImageUrl(Map<String, dynamic> item) {
    final cropped = item['cropped_image_url']?.toString() ?? '';
    final regular = item['image_url']?.toString() ?? '';
    return cropped.isNotEmpty ? cropped : regular;
  }

  /// -- Likes/Dislikes toggling & updates --
  void toggleLike(String? itemName) {
    bool isAdded = false;
    if (clothingDislikes.containsKey(itemName)) {
      // If the user disliked it, remove that first
      clothingDislikes.remove(itemName);
      updateClothingDislikes(itemName!, false, []);
    }
    if (clothingLikes.containsKey(itemName)) {
      // Un-like it
      clothingLikes.remove(itemName);
    } else {
      // Add a like
      clothingLikes[itemName] = true;
      isAdded = true;
    }
    updateClothingLikes(itemName!, isAdded);
  }

  void toggleDislike(
      String? itemName,
      String? itemCategory,
      BuildContext context,
      String? clothingType,
      String? otherTags,
      String? color,
      String? id,
      ) async {
    if (clothingLikes.containsKey(itemName)) {
      clothingLikes.remove(itemName);
      updateClothingLikes(itemName!, false);
    }

    if (clothingDislikes.containsKey(itemName)) {
      clothingDislikes.remove(itemName);
      await updateClothingDislikes(itemName!, false, []);
    } else {
      String? feedbackData = await _feedbackFormBuilder(context);

      if (feedbackData == null) {
        debugPrint('Feedback form cancelled; not triggering dislike.');
        return;
      }

      List<dynamic> feedbackList = [itemCategory, itemName];
      if (feedbackData == "Type of item") {
        feedbackList.add("Type of item");
        feedbackList.add(clothingType);
      } else if (feedbackData == "Style") {
        feedbackList.add("Style");
        feedbackList.add(otherTags);
      } else if (feedbackData == "Colour") {
        feedbackList.add("Colour");
        feedbackList.add(color);
      }

      clothingDislikes[itemName] = true;
      await updateClothingDislikes(itemName!, true, feedbackList);

      if (clothingDislikes.containsKey(itemName)) {
        setState(() {
          _loadingReplacementIds.add(id!);
        });

        await _fetchReplacementItem(
          startingId: productDoc!['id'],
          previousRecId: id!,
          dislikeReason: feedbackList.toString(),
          itemName: itemName,
        );

        setState(() {
          _loadingReplacementIds.remove(id);
        });
      }
    }
  }

  Future<void> updateClothingLikes(String itemName, bool isAdded) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    Map<String, bool> updatedClothingLikesItem = {itemName: isAdded};
    String jsonData = jsonEncode(updatedClothingLikesItem);

    final response = await http.post(
      Uri.parse('$baseUrl/profile/updateclothinglikes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonData,
    );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      debugPrint(responseJson["detail"]);
      throw Exception(responseJson["detail"]);
    }
  }

  Future<void> updateClothingDislikes(
    String itemName,
    bool isAdded,
    List<Object?> feedbackList,
  ) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    Map<String, dynamic> updatedClothingDislikesItem;
    if (isAdded) {
      updatedClothingDislikesItem = {itemName: true, "feedback": feedbackList};
    } else {
      updatedClothingDislikesItem = {itemName: false};
    }

    String jsonData = jsonEncode(updatedClothingDislikesItem);

    final response = await http.post(
      Uri.parse('$baseUrl/profile/updateclothingdislikes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonData,
    );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      debugPrint(responseJson["detail"]);
      throw Exception(responseJson["detail"]);
    }
  }

  Future<String?> _feedbackFormBuilder(BuildContext context) async {
    String? selectedOption;

    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('What did you dislike about this item?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text("Type of item"),
                    value: "Type of item",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text("Style"),
                    value: "Style",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: Text("Colour"),
                    value: "Colour",
                    groupValue: selectedOption,
                    onChanged: (value) {
                      setState(() {
                        selectedOption = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                // TextButton(
                //   onPressed: () => Navigator.pop(context, null),
                //   child: Text('Cancel'),
                // ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, selectedOption);
                  },
                  child: Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _fetchReplacementItem({
    required String startingId,
    required String previousRecId,
    required String dislikeReason,
    required String itemName,
  }) async {
    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final uri = Uri.parse(
        '$baseUrl/catalogue/feedback_recommendation?starting_id=$startingId&previous_rec_id=$previousRecId&dislike_reason=$dislikeReason');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final rec = json.decode(response.body);
        final formattedRec = {
          'id': rec['_id'] ?? '',
          'image_url': rec['image_url'] ?? '',
          'cropped_image_url': rec['image_url'] ?? '',
          'name': rec['name'] ?? '',
          'label': rec['name'] ?? '',
          'price': rec['price']?.toString() ?? '0.0',
          'category': rec['category'] ?? '',
        };
        debugPrint("newRec" + formattedRec.toString());
        setState(() {
          bool replaced = false;
          for (var style in recommendedOutfits) {
            if (style is Map && style.containsKey('style_outfits')) {
              for (var outfit in style['style_outfits']) {
                List<String> keys = [
                  'top_items',
                  'bottom_items',
                  'shoe_items',
                  'jacket_items',
                  'accessory_items',
                  'dress_items'
                ];
                for (var key in keys) {
                  if (outfit.containsKey(key)) {
                    List<dynamic> items = outfit[key];
                    for (int i = 0; i < items.length; i++) {
                      if (items[i]['id'] == previousRecId) {
                        formattedRec['locked'] = true;
                        outfit[key][i] = formattedRec;
                        replaced = true;
                        break;
                      }
                    }
                  }
                  if (replaced) break;
                }
                if (replaced) break;
              }
            }
            if (replaced) break;
          }
        });
      } else {
        throw Exception('Failed to fetch replacement recommendation');
      }
    } catch (e) {
      debugPrint("Error fetching replacement recommendation: $e");
    }
  }

  /// Tracks a product click in the backend
  Future<void> _trackProductClick(String itemId) async {
    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;

    try {
      await http.post(
        Uri.parse('$baseUrl/catalogue/track-click/$itemId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      debugPrint('Product click tracked successfully');
    } catch (error) {
      debugPrint('Error tracking product click: $error');
      // Silent failure - don't disrupt user experience
    }
  }

  /// Opens the product URL in external browser and tracks the click
  Future<void> _openProductUrl(String urlString, String itemId) async {
    // First track the click
    await _trackProductClick(itemId);

    // Parse string to Uri
    final Uri url = Uri.parse(urlString);

    // Then open the URL using the url_launcher API
    try {
      final bool launched = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // Handle case where launch failed but no exception was thrown
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the product URL')),
        );
      }
    } catch (e) {
      // Handle any exceptions during launch
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open URL: $e')),
      );
    }
  }
 
  /// Fetch matching wardrobe items for the current shop item
  Future<void> _fetchMatchingWardrobeItems() async {
    // Don't start fetch if productDoc isn't loaded yet (safety check)
    if (productDoc == null) {
        debugPrint("Cannot fetch wardrobe items: productDoc is null.");
        // Ensure loading state is false if we can't proceed
        if (isLoadingWardrobeItems) {
            setState(() => isLoadingWardrobeItems = false);
        }
        return;
    }
    // Ensure isLoading is set to true *before* the async gap
    // Set state *only* if it's not already true to avoid unnecessary rebuilds
    if (!isLoadingWardrobeItems) {
       setState(() => isLoadingWardrobeItems = true);
    }
    debugPrint("Fetching matching wardrobe items...");

    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final String productId = productDoc!['id'] ?? '';

    if (productId.isEmpty) {
      debugPrint("Product ID is empty, cannot fetch matching items.");
      setState(() => isLoadingWardrobeItems = false);
      // Optionally show a message, but button state handles user feedback
      return;
    }

    final uri = Uri.parse('$baseUrl/catalogue/matching-wardrobe-items/$productId');
    debugPrint("Calling URL for wardrobe items: $uri");

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      debugPrint("Wardrobe Response Status Code: ${response.statusCode}");

      // Check if the widget is still mounted before updating state
      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint("Successfully fetched and decoded matching wardrobe items.");
        if (data is Map<String, dynamic> && data.containsKey('shop_item') && data.containsKey('matching_styles')) {
          setState(() {
            matchingWardrobeItemsData = data;
            isLoadingWardrobeItems = false; // Data loaded successfully
            debugPrint("State updated with matching wardrobe items data.");
          });
        } else {
          throw Exception('Invalid response structure from API');
        }
      } else {
        String errorDetail = 'Failed to load matching wardrobe items';
        try {
          final errorData = json.decode(response.body);
          errorDetail = errorData['detail'] ?? response.body;
        } catch (_) {
          errorDetail = response.body;
        }
        debugPrint("API Error fetching wardrobe items (${response.statusCode}): $errorDetail");
        throw Exception('API Error (${response.statusCode})');
      }
    } catch (error, stackTrace) {
      debugPrint('Error fetching matching wardrobe items: $error');
      debugPrint('Stack trace: $stackTrace');
       // Check if the widget is still mounted before updating state
      if (!mounted) return;
      setState(() => isLoadingWardrobeItems = false); // Stop loading on error

      // Optionally show a snackbar, but the button state might be enough feedback
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Could not load wardrobe items.')),
      // );
    }
  }


  /// Shows the modal with matching wardrobe items
  void _showWardrobeVisualizationModal(BuildContext context) {
    // Data should already be loading or loaded by the time this is clickable.
    // We pass the current state (data and loading flag) to the modal.
    // The modal's internal logic will handle displaying loading/data/error.

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (BuildContext context, ScrollController scrollController) {
            // Use StatefulBuilder ONLY IF the modal needs to trigger its OWN refresh.
            // For displaying pre-fetched data, it might not be necessary,
            // but WardrobeVisualizationWidget likely uses internal state for pagination, so keep it.
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter modalSetState) {
                // Pass the current state from _ProductDetailPageState
                // WardrobeVisualizationWidget will handle displaying based on these.
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('Visualize with Your Wardrobe', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(icon: Icon(Icons.close), onPressed: () => Navigator.pop(modalContext)),
                        ],
                      ),
                      Divider(),
                      Expanded(
                        child: WardrobeVisualizationWidget(
                          // Pass the data and loading state fetched by the page
                          visualizationData: matchingWardrobeItemsData,
                          isLoading: isLoadingWardrobeItems,
                          // Remove authService if not needed directly by WardrobeVisualizationWidget
                          // authService: authService, // Pass only if needed
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProduct) {
      return Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0, // fix bug of appbar changing colour when scrolling down the page
          title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (productDoc == null) {
      return Scaffold(
        appBar: AppBar(
          scrolledUnderElevation: 0, // fix bug of appbar changing colour when scrolling down the page
          title: Text("Error")),
        body: Center(child: Text('Product not found.')),
      );
    }

    final imageUrl = productDoc!['image_url'] ?? '';
    final name = productDoc!['name'] ?? '';
    final price = productDoc!['price'] ?? '';
    final retailerName = productDoc!['retailer'] ?? 'Brand Name';
    final tags = productDoc!['other_tags'] ?? [];

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0, // fix bug of appbar changing colour when scrolling down the page
        title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main product image with overlaid Like/Dislike
            Stack(
              children: [
                Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 400,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx, e, st) => Icon(Icons.error),
                ),
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.favorite,
                          color: clothingLikes.containsKey(name)
                              ? Colors.pink
                              : Colors.grey,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        onPressed: () {
                          setState(() {
                            toggleLike(name);
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.thumb_down,
                          color: clothingDislikes.containsKey(name)
                              ? Colors.red
                              : Colors.grey,
                          shadows: [
                            Shadow(
                              color: Colors.white.withOpacity(0.1),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        onPressed: () {
                          setState(() {
                            toggleDislike(
                              name,
                              productDoc!['category'],
                              context,
                              productDoc!['clothing_type'],
                              productDoc!['other_tags']?.toString(),
                              productDoc!['color']?.toString(),
                              productDoc!['id']?.toString(),
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Product info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    retailerName,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '\$${price.toString()}',
                    style: TextStyle(fontSize: 18, color: const Color(0xFFA47864)), // Primary brown instead of green
                  ),
                  SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () { // SHOP NOW button logic (unchanged)
                              final productUrl = productDoc!['product_url'] ?? '';
                              final productId = productDoc!['id'] ?? '';
                              if (productUrl.isNotEmpty) {
                                _openProductUrl(productUrl, productId);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('No product URL available')),
                                );
                              }
                            },
                            icon: Icon(Icons.shopping_bag),
                            label: Text('SHOP NOW'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFA47864),
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            // Conditionally disable based on loading state
                            onPressed: isLoadingWardrobeItems
                                ? null // Disable button while loading
                                : () {
                                    // Only show modal if not loading
                                    _showWardrobeVisualizationModal(context);
                                  },
                            icon: isLoadingWardrobeItems
                                ? SizedBox( // Show spinner instead of icon
                                    width: 18, // Adjust size as needed
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.0,
                                      color: Color(0xFFA47864), // Match theme
                                    ),
                                  )
                                : Icon(Icons.checkroom), // Original icon
                            label: isLoadingWardrobeItems
                                ? Text('LOADING...') // Loading text
                                : Text('VISUALIZE'), // Shortened text or keep 'VISUALIZE WITH...'
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFA47864),
                              side: BorderSide(color: const Color(0xFFA47864)),
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              // Optionally slightly grey out when disabled
                              disabledForegroundColor: const Color(0xFFA47864).withOpacity(0.5),
                              disabledMouseCursor: SystemMouseCursors.wait,
                            ),
                          ),
                        ),
                      ],
                    ),
                  SizedBox(height: 8),
                  Text(
                    'Tags:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 6.0,
                    children: (tags is List)
                        ? tags.map<Widget>((tag) {
                            return Chip(
                              label: Text(tag.toString()),
                              padding: EdgeInsets.all(2),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            );
                          }).toList()
                        : [],
                  ),
                  SizedBox(height: 4),

                  // Similar Items
                  Text(
                    'Similar Items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  isLoadingSimilar
                      ? Center(child: CircularProgressIndicator())
                      : (similarProducts.isNotEmpty
                          ? buildSimilarItems()
                          : Text('No similar items found')),
                  // Recommended Outfits
                  buildRecommendedOutfitsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSimilarItems() {
    return Container(
      height: 232,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: similarProducts.length,
        itemBuilder: (context, index) {
          final sp = similarProducts[index];
          return GestureDetector(
            onTap: () {
              // Navigate to detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(productId: sp['id']),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    sp['url'] ?? '',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => Icon(Icons.error),
                  ),
                  SizedBox(height: 8),
                  Text(sp['label'] ?? "",
                      style: TextStyle(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('\$${sp['price']}',
                        style: TextStyle(fontSize: 14, color: const Color(0xFFA47864)), // Primary brown instead of green
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCarousel(
      String category, List<dynamic> items, String currentItemId) {
    // Ensure items list is not empty before building
    if (items.isEmpty) {
        return SizedBox.shrink(); // Return empty widget if no items
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0), // Adjust padding if needed
          child: Text(
            category, // Use the category name directly (Title Case or as provided)
            style: TextStyle(
              fontSize: 16, // Slightly smaller than style name
              fontWeight: FontWeight.w600, // Semi-bold, less than main headers
              color: Colors.black.withOpacity(0.75), // Slightly muted color
            ),
          ),
        ),
        SizedBox(
          // Define a fixed height or calculate based on content if needed
          height: 230, // Increased height slightly to accommodate text better
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            // Using PageController can give snap behavior, standard controller is fine too
            // controller: PageController(viewportFraction: 0.8), // Example if snapping is desired
            // physics: const PageScrollPhysics(), // Use appropriate physics
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              // Handle potential nulls gracefully
               final itemId = item['id']?.toString() ?? '';
              final itemName = item['name']?.toString() ?? 'Unnamed Item';
              final isMainItem = itemId == currentItemId;

              // Ensure item has necessary data before rendering
               if (itemId.isEmpty) {
                 return SizedBox.shrink(); // Skip rendering if essential data missing
               }


              return Container(
                width: 160, // Keep item width consistent
                margin: EdgeInsets.only(right: 12), // Consistent spacing
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text left
                  children: [
                    // Image container with potential border for main item
                    Container(
                       height: 160, // Fixed height for image consistency
                       width: double.infinity, // Take full width of parent container
                       decoration: BoxDecoration(
                         border: isMainItem
                            ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.7), width: 2.5) // Use theme color
                            : null,
                         borderRadius: BorderRadius.circular(4), // Optional: slightly rounded corners
                       ),
                       child: ClipRRect( // Clip image to rounded corners if using borderRadius
                         borderRadius: BorderRadius.circular(isMainItem ? 2 : 4), // Adjust clipping based on border
                         child: GestureDetector( // Wrap image in GestureDetector
                            onTap: () {
                              if (!isMainItem && itemId.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailPage(productId: itemId),
                                  ),
                                );
                              }
                            },
                           child: Stack(
                             fit: StackFit.expand, // Make stack fill the container
                             children: [
                               Image.network(
                                 _getImageUrl(item),
                                 fit: BoxFit.cover, // Cover ensures the image fills the space
                                 errorBuilder: (ctx, e, st) => Container(
                                     color: Colors.grey[200],
                                     child: Icon(Icons.broken_image, color: Colors.grey[400])
                                 ),
                                 // Loading builder can be added for better UX
                                 loadingBuilder: (context, child, loadingProgress) {
                                     if (loadingProgress == null) return child;
                                     return Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.0,
                                          value: loadingProgress.expectedTotalBytes != null
                                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                                : null,
                                        ),
                                      );
                                   },
                               ),
                               // Like/Dislike Buttons (consider smaller icons/padding for carousel)
                               Positioned(
                                 right: 0,
                                 bottom: 0,
                                 child: Container( // Add background for better visibility
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                                      ),
                                      borderRadius: BorderRadius.only(bottomRight: Radius.circular(4))
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          padding: EdgeInsets.all(4), // Reduced padding
                                          constraints: BoxConstraints(), // Remove default constraints
                                          iconSize: 20, // Smaller icon
                                          icon: Icon(
                                            Icons.favorite,
                                            color: clothingLikes.containsKey(item['name'])
                                                ? Colors.pinkAccent
                                                : Colors.white.withOpacity(0.8),
                                            shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)],
                                          ),
                                          onPressed: () {
                                            setState(() { toggleLike(item['name']); });
                                          },
                                        ),
                                        IconButton(
                                           padding: EdgeInsets.all(4),
                                           constraints: BoxConstraints(),
                                           iconSize: 20,
                                           icon: Icon(
                                             Icons.thumb_down,
                                             color: clothingDislikes.containsKey(item['name'])
                                                 ? Colors.redAccent
                                                 : Colors.white.withOpacity(0.8),
                                             shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 2)],
                                           ),
                                           onPressed: () {
                                             setState(() {
                                               toggleDislike(
                                                 item['name'], item['category'], context,
                                                 item['clothing_type']?.toString(), item['other_tags']?.toString(),
                                                 item['color']?.toString(), item['id']?.toString(),
                                               );
                                             });
                                           },
                                        ),
                                      ],
                                    ),
                                 ),
                               ),
                               // Loading indicator overlay for replacement
                               if (_loadingReplacementIds.contains(item['id']))
                                 Positioned.fill(
                                   child: Container(
                                      color: Colors.black.withOpacity(0.5),
                                      child: Center(child: CircularProgressIndicator(color: Colors.white)),
                                   ),
                                 ),
                             ],
                           ),
                         ),
                       ),
                    ),
                    // Text below the image
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0, bottom: 2.0), // Adjust spacing
                      child: Text(
                        itemName, // Use the retrieved name
                        maxLines: 2, // Allow two lines for longer names
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500), // Slightly bolder than default
                      ),
                    ),
                    // Optional: Price or Brand
                    // Text(
                    //   '\$${item['price']?.toString() ?? 'N/A'}',
                    //   style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    // ),
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16), // Add space after each carousel
      ],
    );
  }
  Widget _buildStyleSkeleton(String styleName) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 200,
              height: 24,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(3, (index) => _buildItemSkeleton()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSkeleton() {
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: 8),
      child: Column(
        children: [
          Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              width: 160,
              height: 160,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: 100,
            height: 16,
            color: Colors.grey[200],
          ),
        ],
      ),
    );
  }

Widget buildRecommendedOutfitsSection() {
  final mainCategory = productDoc?['category']?.toLowerCase() ?? '';
  final mainItemId = productDoc?['id'] ?? '';

  try {
    // Filter recommendedOutfits to only include styles with outfits
    final validOutfitStyles = recommendedOutfits.where((style) {
      final styleOutfits = style['style_outfits'] as List<dynamic>? ?? [];
      return styleOutfits.isNotEmpty;
    }).toList();

    // Determine the total number of valid styles
    final int totalStyles = validOutfitStyles.length;

    // Ensure _currentStyleIndex is valid
    if (_currentStyleIndex >= totalStyles && totalStyles > 0) {
      _currentStyleIndex = totalStyles - 1;
    }

    // Create the style pagination header
    final paginationHeader = StylePaginationHeader(
      // Keep the main title reasonably prominent
      title: 'Recommended Outfits', // Title Case is standard
      currentIndex: _currentStyleIndex,
      totalStyles: totalStyles,
      onPrevious: _previousStyle,
      onNext: _nextStyle,
      isLoading: isLoadingOutfits,
    );

    // If there are no styles yet, or we're still loading initial data
    if (totalStyles == 0) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          paginationHeader,
          // Add a divider even when loading/empty for consistency
        Divider(height: 0, thickness: 1, indent: 0, endIndent: 0), // Added Divider
        SizedBox(height: 4),
          // Show appropriate loading UI or empty state
          if (isLoadingOutfits)
            _buildStyleSkeleton("Loading Style...")
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0), // Added padding
              child: Text(
                'No outfit recommendations available yet.',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ),
        ],
      );
    }

    // Get the current style to display
    final currentStyle = validOutfitStyles[_currentStyleIndex];
    // Use style name directly, ensure it's not null/empty
    final styleName = currentStyle['style_name']?.toString() ?? 'Style';
    final styleOutfits = currentStyle['style_outfits'] as List<dynamic>? ?? [];

    // Collect all items across all base recommendations for the current style
    List<dynamic> allItems = [];
    for (final outfit in styleOutfits) {
      // Process all item categories
      final categories = [
        'top_items', 'bottom_items', 'shoe_items',
        'jacket_items', 'accessory_items', 'dress_items'
      ];

      for (final category in categories) {
        final items = outfit[category] as List<dynamic>? ?? [];
        if (items.isNotEmpty) {
          allItems.addAll(items);
        }
      }
    }
    // De-duplicate items
    final seenIds = <String>{};
    allItems.retainWhere((item) => seenIds.add(item['id'] as String));

    // Categorize items into all six categories
    List<dynamic> tops = [];
    List<dynamic> bottoms = [];
    List<dynamic> dresses = [];
    List<dynamic> shoes = [];
    List<dynamic> outerwear = [];
    List<dynamic> accessories = [];

    for (final item in allItems) {
      final category = item['category']?.toLowerCase() ?? '';
      switch (category) {
        case 'tops':
          tops.add(item); 
        case 'bottoms':
          bottoms.add(item);
        case 'dresses':
          dresses.add(item); 
        case 'shoes':
          shoes.add(item); 
        case 'outerwear':
        case 'jackets': // Handle potential variations
          outerwear.add(item); 
        case 'accessories':
          accessories.add(item);
      }
    }

    // Add main item to its category (ensure it's not added twice if already present)
    final mainItemAlreadyAdded = allItems.any((item) => item['id'] == mainItemId);
    if (!mainItemAlreadyAdded) {
        switch (mainCategory) {
            case 'tops': tops.insert(0, productDoc!); 
            case 'bottoms': bottoms.insert(0, productDoc!); 
            case 'dresses': dresses.insert(0, productDoc!); 
            case 'shoes': shoes.insert(0, productDoc!); 
            case 'outerwear': case 'jackets': outerwear.insert(0, productDoc!); 
            case 'accessories': accessories.insert(0, productDoc!); 
        }
    }


    // Define carousel configurations based on main category logic (adjust names slightly for UI)
    List<Map<String, dynamic>> carouselConfigs = [];
    switch (mainCategory) {
        case 'tops':
            carouselConfigs = [
                {'category': 'Outerwear', 'items': outerwear},
                {'category': 'Bottoms', 'items': bottoms},
                {'category': 'Shoes', 'items': shoes},
                {'category': 'Accessories', 'items': accessories},
            ];
        case 'bottoms':
            carouselConfigs = [
                {'category': 'Tops', 'items': tops},
                {'category': 'Outerwear', 'items': outerwear},
                {'category': 'Shoes', 'items': shoes},
                {'category': 'Accessories', 'items': accessories},
            ];
        case 'dresses':
             carouselConfigs = [
                {'category': 'Outerwear', 'items': outerwear},
                {'category': 'Shoes', 'items': shoes},
                {'category': 'Accessories', 'items': accessories},
            ];
        case 'outerwear':
        case 'jackets':
            carouselConfigs = [
                {'category': 'Tops', 'items': tops},
                {'category': 'Bottoms', 'items': bottoms},
                {'category': 'Dresses', 'items': dresses},
                {'category': 'Shoes', 'items': shoes},
                {'category': 'Accessories', 'items': accessories},
            ];
        case 'shoes':
            carouselConfigs = [
                {'category': 'Tops', 'items': tops},
                {'category': 'Bottoms', 'items': bottoms},
                {'category': 'Outerwear', 'items': outerwear},
                {'category': 'Dresses', 'items': dresses},
                {'category': 'Accessories', 'items': accessories},
            ];
        case 'accessories':
             carouselConfigs = [
                {'category': 'Tops', 'items': tops},
                {'category': 'Bottoms', 'items': bottoms},
                {'category': 'Outerwear', 'items': outerwear},
                {'category': 'Dresses', 'items': dresses},
                {'category': 'Shoes', 'items': shoes},
            ];
        default: // Fallback: Show all available categories
            carouselConfigs = [
                {'category': 'Tops', 'items': tops},
                {'category': 'Bottoms', 'items': bottoms},
                {'category': 'Outerwear', 'items': outerwear},
                {'category': 'Dresses', 'items': dresses},
                {'category': 'Shoes', 'items': shoes},
                {'category': 'Accessories', 'items': accessories},
            ];
            // Remove the main category itself from the list if needed, though often it's fine to show
            carouselConfigs.removeWhere((c) => c['category'].toLowerCase() == mainCategory);
    }


    // Filter out carousels with empty items
    carouselConfigs.retainWhere((config) => (config['items'] as List).isNotEmpty);

    // Return the styled layout with the pagination header at the top
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Style pagination header with controls
        paginationHeader,
        // Divider below the main header
        Divider(height: 0, thickness: 1, indent: 0, endIndent: 0), // Added Divider
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 0.1), // Add space below style name
          child: Text(
            styleName, 
            style: TextStyle(
              fontSize: 18, // Slightly smaller than main header
              fontWeight: FontWeight.w500, // Medium weight, not bold
              color: Colors.black87, // Slightly softer than pure black
            ),
          ),
        ),

        // Display each category carousel for the current style
        ...carouselConfigs.map((config) {
          return _buildCategoryCarousel(
            config['category'], // Use the display name
            config['items'] as List<dynamic>,
            mainItemId,
          );
        }).toList(),
      ],
    );
  } catch (e, stacktrace) { // Catch specific error and stacktrace
    debugPrint('Error building recommended outfits: $e');
    debugPrint('Stacktrace: $stacktrace'); // Log stacktrace for better debugging
    // Return a more informative error state UI
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 0, thickness: 1, indent: 0, endIndent: 0), // Added Divider
        StylePaginationHeader(
          title: 'Recommended Outfits',
          currentIndex: 0, totalStyles: 0,
          onPrevious: (){}, onNext: (){}, // Provide dummy functions
          isLoading: false,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Error loading recommendations.', style: TextStyle(color: Colors.red.shade700)),
              SizedBox(height: 4),
              Text('Details: ${e.toString()}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              SizedBox(height: 8),
              ElevatedButton.icon(
                icon: Icon(Icons.refresh),
                label: Text('Try Again'),
                onPressed: fetchRecommendedOutfits, // Call fetch again
                 style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black87,
                  ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
  Widget buildOutfitCard(dynamic outfit) {
    final styleName = outfit['style'];
    final outfitName = outfit['name'];
    final outfitItems = outfit['items'] as List<dynamic>? ?? [];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 20.0),
      padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 30.0),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(styleName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(outfitName,
              style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          SizedBox(height: 8),

          // Show top/bottom/shoes layout
          OutfitStackWidget(
            originalDoc: productDoc!,
            outfitItems: outfitItems,

            // Hand off likes/dislikes from parent
            clothingLikes: clothingLikes,
            clothingDislikes: clothingDislikes,

            // Hand off toggles from parent
            onToggleLike: toggleLike,
            onToggleDislike:
                (itemName, itemCategory, clothingType, otherTags, color, id) {
              toggleDislike(itemName, itemCategory, context, clothingType,
                  otherTags, color, id);
            },
          ),
        ],
      ),
    );
  }
}

class OutfitStackWidget extends StatefulWidget {
  final Map<String, dynamic> originalDoc;
  final List<dynamic> outfitItems;

  // From the parent
  final Map<String?, dynamic> clothingLikes;
  final Map<String?, dynamic> clothingDislikes;

  final Function(String? itemName) onToggleLike;
  final Function(
    String? itemName,
    String? itemCategory,
    String? clothingType,
    String? otherTags,
    String? color,
    String? id,
  ) onToggleDislike;

  const OutfitStackWidget({
    Key? key,
    required this.originalDoc,
    required this.outfitItems,
    required this.clothingLikes,
    required this.clothingDislikes,
    required this.onToggleLike,
    required this.onToggleDislike,
  }) : super(key: key);

  @override
  State<OutfitStackWidget> createState() => _OutfitStackWidgetState();
}

class _OutfitStackWidgetState extends State<OutfitStackWidget> {
  final AuthService authService = AuthService();

  Map<String, dynamic>? topsDoc;
  Map<String, dynamic>? bottomsDoc;
  Map<String, dynamic>? shoesDoc;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _assignOriginalDoc();
    _fetchMatchedItems();
  }

  void _assignOriginalDoc() {
    final originalCat =
        widget.originalDoc['category']?.toString().toLowerCase() ?? '';
    if (originalCat == 'tops') {
      topsDoc = widget.originalDoc;
    } else if (originalCat == 'bottoms') {
      bottomsDoc = widget.originalDoc;
    } else if (originalCat == 'shoes') {
      shoesDoc = widget.originalDoc;
    }
  }

  /// For each item in the outfit, fetch its doc by ID and assign to tops/bottoms/shoes
  Future<void> _fetchMatchedItems() async {
    final fetchFutures = <Future>[];

    for (final outfitItem in widget.outfitItems) {
      final matchData = outfitItem['match'];
      if (matchData == null) continue;

      final matchedId = matchData['id'];
      if (matchedId == null || matchedId.isEmpty) continue;

      fetchFutures.add(_fetchSingleDoc(matchedId));
    }

    try {
      await Future.wait(fetchFutures);
    } catch (e) {
      debugPrint("Error in _fetchMatchedItems: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchSingleDoc(String itemId) async {
    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final uri = Uri.parse('$baseUrl/shop/item/$itemId');

    try {
      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final doc = json.decode(response.body);
        final cat = doc['category']?.toString().toLowerCase() ?? '';
        if (cat == 'tops') {
          topsDoc = doc;
        } else if (cat == 'bottoms') {
          bottomsDoc = doc;
        } else if (cat == 'shoes') {
          shoesDoc = doc;
        }
      } else {
        debugPrint("Failed to fetch item doc $itemId: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching item doc $itemId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlot(topsDoc, "tops"),
        SizedBox(height: 8),
        _buildSlot(bottomsDoc, "bottoms"),
        SizedBox(height: 8),
        _buildSlot(shoesDoc, "shoes"),
      ],
    );
  }

  Widget _buildSlot(Map<String, dynamic>? doc, String placeholder) {
    if (doc == null) {
      return Container(
        margin: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width * 0.08),
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: Text("No $placeholder"),
      );
    }

    final cropped = doc['cropped_image_url'] ?? '';
    final fallback = doc['image_url'] ?? '';
    final imageUrl = (cropped.isNotEmpty) ? cropped : fallback;

    // Determine width based on category
    final category = doc['category']?.toString().toLowerCase() ?? '';
    final double sidePadding;

    if (category == 'bottoms') {
      sidePadding = MediaQuery.of(context).size.width * 0.18;
    } else if (category == 'shoes') {
      sidePadding = MediaQuery.of(context).size.width * 0.25;
    } else {
      sidePadding = MediaQuery.of(context).size.width * 0.1;
    }

    final itemName = doc['name']?.toString();
    final itemCategory = doc['category']?.toString();
    final clothingType = doc['clothing_type']?.toString();
    final otherTags = doc['other_tags']?.toString();
    final color = doc['color']?.toString();
    final id = doc['id']?.toString();

    return Container(
      margin: EdgeInsets.symmetric(horizontal: sidePadding),
      child: Stack(
        children: [
          // The product image
          GestureDetector(
            onTap: () {
              final itemId = doc['id'] ?? '';
              if (itemId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailPage(productId: itemId),
                  ),
                );
              }
            },
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, st) => Container(
                height: 220,
                color: Colors.grey[300],
                alignment: Alignment.center,
                child: Text("Error loading image"),
              ),
            ),
          ),

          // Like/Dislike icons (overlaid at the bottom-right)
          Positioned(
            right: 8,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.favorite,
                    color: widget.clothingLikes.containsKey(itemName)
                        ? Colors.pink
                        : Colors.grey[700],
                  ),
                  onPressed: () {
                    setState(() {
                      widget.onToggleLike(itemName);
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.thumb_down,
                    color: widget.clothingDislikes.containsKey(itemName)
                        ? Colors.red
                        : Colors.grey[700],
                  ),
                  onPressed: () {
                    setState(() {
                      widget.onToggleDislike(
                        itemName,
                        itemCategory,
                        clothingType,
                        otherTags,
                        color,
                        id,
                      );
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
