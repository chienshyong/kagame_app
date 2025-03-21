import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
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

  /// Clothing preferences (likes & dislikes)
  Map<String?, dynamic> clothingLikes = {};
  Map<String?, dynamic> clothingDislikes = {};

  @override
  void initState() {
    super.initState();
    // 1) Fetch main product by ID
    _fetchProductDoc();
    // 2) Also fetch user’s existing likes/dislikes
    getClothingPreferences();
  }

  /// Grab user’s saved clothing preferences.
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
        // Then fetch similar & recommended
        await fetchSimilarProducts();
        await fetchRecommendedOutfits();
      } else {
        throw Exception('Failed to load product detail');
      }
    } catch (error) {
      debugPrint('Error fetching product detail: $error');
      setState(() => isLoadingProduct = false);
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

  /// Step 3: fetch recommended outfits
  Future<void> fetchRecommendedOutfits() async {
    if (productDoc == null) return;
    setState(() => isLoadingOutfits = true);

    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final String productId = productDoc!['id'] ?? '';
    final uri =
        Uri.parse('$baseUrl/shop/item-outfit-search?item_id=$productId');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recommendedOutfits = data['outfits'] ?? [];
        });
      } else {
        throw Exception('Failed to load recommended outfits');
      }
    } catch (error) {
      debugPrint('Error fetching recommended outfits: $error');
    } finally {
      setState(() => isLoadingOutfits = false);
    }
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
  ) async {
    // If user had liked it, remove the like
    if (clothingLikes.containsKey(itemName)) {
      clothingLikes.remove(itemName);
      updateClothingLikes(itemName!, false);
    }

    List<dynamic> feedbackList = [itemCategory, itemName];
    bool isAdded = false;
    if (clothingDislikes.containsKey(itemName)) {
      // Undo the dislike
      clothingDislikes.remove(itemName);
    } else {
      // Mark as disliked, show feedback form
      clothingDislikes[itemName] = true;
      isAdded = true;
      String? feedbackData = await _feedbackFormBuilder(context);
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
    }
    updateClothingDislikes(itemName!, isAdded, feedbackList);
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
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text('Cancel'),
                ),
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
  // Future<String?> _feedbackFormBuilder(BuildContext context) async {
  //   String? feedbackData;

  //   await showDialog<void>(
  //     context: context,
  //     builder: (BuildContext dialogContext) {
  //       return AlertDialog(
  //         title: const Text('What did you dislike about this item?'),
  //         content: Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             ListTile(
  //               title: Text("Type of item"),
  //               onTap: () {
  //                 feedbackData = "Type of item";
  //                 Navigator.pop(dialogContext);
  //               },
  //             ),
  //             ListTile(
  //               title: Text("Style"),
  //               onTap: () {
  //                 feedbackData = "Style";
  //                 Navigator.pop(dialogContext);
  //               },
  //             ),
  //             ListTile(
  //               title: Text("Colour"),
  //               onTap: () {
  //                 feedbackData = "Colour";
  //                 Navigator.pop(dialogContext);
  //               },
  //             ),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  //   return feedbackData;
  // }

@override
Widget build(BuildContext context) {
  if (isLoadingProduct) {
    return Scaffold(
      appBar: AppBar(title: Text("Loading...")),
      body: Center(child: CircularProgressIndicator()),
    );
  }

  if (productDoc == null) {
    return Scaffold(
      appBar: AppBar(title: Text("Error")),
      body: Center(child: Text('Product not found.')),
    );
  }

  final imageUrl = productDoc!['image_url'] ?? '';
  final name = productDoc!['name'] ?? '';
  final price = productDoc!['price'] ?? '';
  final retailerName = productDoc!['retailer'] ?? 'Brand Name';
  final tags = productDoc!['other_tags'] ?? [];

  return Scaffold(
    appBar: AppBar(title: Text(name)),
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
                            : Colors.grey[700],
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
                            : Colors.grey[700],
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
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
                Text(
                  '\$${price.toString()}',
                  style: TextStyle(fontSize: 18, color: Colors.green),
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
                SizedBox(height: 16),

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
                SizedBox(height: 20),

                // Recommended Outfits
                Text(
                  'Recommended Outfits',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
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
                      style: TextStyle(fontSize: 14, color: Colors.green)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildRecommendedOutfitsSection() {
    if (isLoadingOutfits) {
      return Center(child: CircularProgressIndicator());
    }
    if (recommendedOutfits.isEmpty) {
      return Text('No recommended outfits found');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          recommendedOutfits.map((outfit) => buildOutfitCard(outfit)).toList(),
    );
  }

  Widget buildOutfitCard(dynamic outfit) {
    final styleName = outfit['style'] ?? '';
    final outfitName = outfit['name'] ?? '';
    final outfitItems = outfit['items'] as List<dynamic>? ?? [];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                (itemName, itemCategory, clothingType, otherTags, color) {
              toggleDislike(itemName, itemCategory, context, clothingType,
                  otherTags, color);
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
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
