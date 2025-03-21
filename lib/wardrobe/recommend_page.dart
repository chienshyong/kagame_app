import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../shop/product_detail_page.dart'; 

class RecommendPage extends StatefulWidget {
  final String id;
  RecommendPage({required this.id});
  
  @override
  State<StatefulWidget> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final AuthService authService = AuthService();
  bool isLoading = true;

  // Placeholder while API is called
  Map<String, dynamic> this_item_jsonResponse = {'image_url': 'https://craftsnippets.com/articles_images/placeholder/placeholder.jpg', 'category': '', 'color': '', 'name': ''};
  List<Map<String, dynamic>> recommended = [];

  String prompt = "";

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

  // // Helper method for showing a dialog where user can enter a new prompt to modify search
  // Future<String?> _showModifySearchDialog(BuildContext context) async {
  //     TextEditingController _promptController = TextEditingController();

  //     return showDialog<String>(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //           title: Text('Modify Search'),
  //           content: TextField(
  //             controller: _promptController,
  //             decoration: InputDecoration(
  //               hintText: 'Enter additional details...',
  //             ),
  //           ),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.pop(context, null), // Cancel action
  //               child: Text('Cancel'),
  //             ),
  //             TextButton(
  //               onPressed: () {
  //                 Navigator.pop(context, _promptController.text); // Confirm action
  //               },
  //               child: Text('Search'),
  //             ),
  //           ],
  //         );
  //       },
  //     );
  //   }

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
              return GestureDetector(
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
                                Icons.favorite_border,
                                // Optionally change color if you add state management
                              ),
                              onPressed: () {
                                // Insert toggle functionality or API call here
                                print('Liked product: ${recommendedProduct['_id']}');
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.thumb_down,
                                // Optionally change color if you add state management
                              ),
                              onPressed: () async {
                                String? dislikedAspect = await _showDislikeDialog(context);

                                if (dislikedAspect != null) {
                                  print(
                                    'Disliked product: ${recommendedProduct['_id']}, Aspects: $dislikedAspect'
                                  );
                                  // Handle dislike functionality here (e.g., update state or API call)
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isLoading = true; // Show loading indicator while fetching
                        });
                        fetchRecommendationsFromApi();
                      },
                      child: Text('Recommend Again'),
                    ),
                  ],
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
                      : ListView(
                          children: _buildGroupedRecommendations(),
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