import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../shop/product_detail_page.dart';
import 'dart:ui';

class RecommendPage extends StatefulWidget {
  final String id;
  RecommendPage({required this.id});
  
  @override
  State<StatefulWidget> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final AuthService authService = AuthService();
  bool isLoading = true;

  // Track items being replaced
  Set<String> _loadingReplacementIds = {};

  // Placeholder while API is called
  Map<String, dynamic> this_item_jsonResponse = {'image_url': 'https://craftsnippets.com/articles_images/placeholder/placeholder.jpg', 'category': '', 'color': '', 'name': ''};
  List<Map<String, dynamic>> recommended = [];

  String prompt = "";

  /// Clothing preferences (likes & dislikes)
  Map<String?, dynamic> clothingLikes = {};
  Map<String?, dynamic> clothingDislikes = {};

  @override
  void initState() {
    super.initState();
    fetchThisItemFromApi();
    fetchRecommendationsFromApi();
  }

  Future<void> fetchThisItemFromApi() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'GET',
      Uri.parse('$baseUrl/wardrobe/item/${widget.id}'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString(); // Convert response to string
        setState(() {
          this_item_jsonResponse = json.decode(responseBody); // Decode JSON data as Map
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (error) {
      print('Error fetching image: $error');
    }
  }

  Future<void> fetchRecommendationsFromApi() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'GET',
      Uri.parse('$baseUrl/wardrobe/wardrobe_recommendation?_id=${widget.id}&additional_prompt=${prompt}'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString(); // Convert response to string
        final List<Map<String, dynamic>> data = json.decode(responseBody).cast<Map<String, dynamic>>();

        setState(() {
          recommended = data;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load recommend');
      }
    } catch (error) {
      print('Error fetching recommend: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchReplacementItem({
    required String previousRecId,
    required String dislikeReason,
    required String itemName,
  }) async {
    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final uri = Uri.parse(
      '$baseUrl/wardrobe/feedback_recommendation?previous_rec_id=$previousRecId&dislike_reason=${Uri.encodeComponent(dislikeReason)}',
    );

    try {
      setState(() => _loadingReplacementIds.add(previousRecId));
      
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final rec = json.decode(response.body);
        final formattedRec = {
          '_id': rec['_id'] ?? '',
          'image_url': rec['image_url'] ?? '',
          'name': rec['name'] ?? '',
          'category': rec['category'] ?? '',
          'color': rec['color'] ?? '',
          'clothing_type': rec['clothing_type'] ?? '',
          'other_tags': rec['other_tags'] ?? [],
        };

        setState(() {
          // Find and replace the disliked item
          final index = recommended.indexWhere(
            (item) => item['_id'] == previousRecId
          );
          
          if (index != -1) {
            recommended[index] = formattedRec;
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching replacement: $e");
    } finally {
      setState(() => _loadingReplacementIds.remove(previousRecId));
    }
  }


 /// Shows a dialog with checkboxes for disliked aspects.
  Future<String?> _showDislikeDialog(BuildContext context) async {
    String? selectedOption;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('What did you dislike about this item?'),
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
  // Toggle like state for an item
  void toggleLike(String? itemName) {
    bool isAdded = false;
    if (clothingDislikes.containsKey(itemName)) {
      clothingDislikes.remove(itemName);
      updateClothingDislikes(itemName!, false, []);
    }
    if (clothingLikes.containsKey(itemName)) {
      clothingLikes.remove(itemName);
    } else {
      clothingLikes[itemName] = true;
      isAdded = true;
    }
    updateClothingLikes(itemName!, isAdded);
  }

  // Toggle dislike state for an item with feedback
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

    List<dynamic> feedbackList = [itemCategory, itemName];
    bool isAdded = false;

    if (clothingDislikes.containsKey(itemName)) {
      clothingDislikes.remove(itemName);
    } else {
      clothingDislikes[itemName] = true;
      isAdded = true;
      String? feedbackData = await _showDislikeDialog(context);

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

    await updateClothingDislikes(itemName!, isAdded, feedbackList);

    if (clothingDislikes.containsKey(itemName)) {
    await _fetchReplacementItem(
      previousRecId: id!,
      dislikeReason: feedbackList.join(', '),
      itemName: itemName,
    );
  };
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

  Future<void> updateClothingDislikes(String itemName, bool isAdded, List<Object?> feedbackList) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    Map<String, dynamic> updatedClothingDislikesItem = isAdded
        ? {itemName: true, "feedback": feedbackList}
        : {itemName: false};
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


List<Widget> _buildGroupedRecommendations() {
  Map<String, List<Map<String, dynamic>>> grouped = {
    "Tops": [],
    "Bottoms": [],
    "Shoes": [],
  };

  // Group recommendations by their 'category' field.
  for (var item in recommended) {
    String category = item['category'] ?? 'Others';
    if (grouped.containsKey(category)) {
      grouped[category]!.add(item);
    } else {
      if (!grouped.containsKey("Others")) {
        grouped["Others"] = [];
      }
      grouped["Others"]!.add(item);
    }
  }

  List<Widget> widgets = [];

  // Define the category display order
  List<String> displayOrder = ["Tops", "Bottoms", "Shoes", "Others"];

  for (String category in displayOrder) {
    if (grouped.containsKey(category) && grouped[category]!.isNotEmpty) {
      widgets.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Text(
          category,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ));
      widgets.add(
        Container(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: grouped[category]!.length,
            itemBuilder: (context, index) {
              final recommendedProduct = grouped[category]![index];
              final isReplacing = _loadingReplacementIds.contains(recommendedProduct['_id']);
              
              return Stack(
                children:[
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(
                        productId: recommendedProduct['_id'],
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 150,
                  margin: EdgeInsets.all(8.0),
                  child: Stack(
                    children: [
                      // Product image
                      Image.network(
                        recommendedProduct['url'] ?? recommendedProduct['image_url'],
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                      ),
                      // Overlay Like/Dislike buttons
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: Row(
                          children: [
                            
                            IconButton(
                              icon: Icon(
                                Icons.favorite,
                                color: clothingLikes.containsKey(recommendedProduct['name'])
                                    ? Colors.pink
                                    : Colors.grey[700],
                              ),
                              onPressed: () {
                                setState(() {
                                  toggleLike(recommendedProduct['name']);
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.thumb_down,
                                color: clothingDislikes.containsKey(recommendedProduct['name'])
                                    ? Colors.red
                                    : Colors.grey[700],
                              ),
                              onPressed: () async {
                                setState(() {
                                  toggleDislike(
                                    recommendedProduct['name'],
                                    recommendedProduct['category'],
                                    context,
                                    recommendedProduct['clothing_type']?.toString(),
                                    recommendedProduct['other_tags']?.toString(),
                                    recommendedProduct['color']?.toString(),
                                    recommendedProduct['_id']?.toString(),
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (isReplacing)
                Positioned.fill(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  ),
                ),
                ],
              );
            },
          ),
        ),
      );
    }
  }
  return widgets;
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 1, // Automatically select the second tab ("From Partner Brands")
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Curated Recommendations'),
        ),
        body: Column(
          children: [
            // Header section: Top section with the shirt image and title, plus the Recommend Again button
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        this_item_jsonResponse['image_url'],
                        width: 200,
                        height: 150,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Tab bar: Displays two tabs, separate from the header section
            TabBar(
              labelColor: Colors.black,
              indicatorColor: Colors.blue,
              tabs: [
                Tab(text: 'From Your Wardrobe'),
                Tab(text: 'From Partner Brands'),
              ],
            ),
            // Expanded TabBarView: Holds the content for each tab
            Expanded(
              child: TabBarView(
                children: [
                  // First tab: From Your Wardrobe
                  SingleChildScrollView(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Recommendations from Your Wardrobe Coming Soon',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  // Second tab: From Partner Brands (with recommendations)

                      isLoading
                      ? Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: fetchRecommendationsFromApi,
                          child: ListView(
                            children: _buildGroupedRecommendations(),
                          ),
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}