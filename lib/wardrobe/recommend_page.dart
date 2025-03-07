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

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Curated Recommendations'),
        ),
        body: Column(
          children: [
            // Header section: Top section with the shirt image and title, plus the Modify Search button
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
                        height: 200,
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Action for Modify Search
                      },
                      child: Text('Modify Search'),
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
                          'Content from Your Wardrobe goes here',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ),
                  // Second tab: From Partner Brands (with recommendations)
                  isLoading
                      ? Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommended.length,
                          itemBuilder: (context, index) {
                            final recommendedProduct = recommended[index];
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Image.network(
                                      recommendedProduct['url'] ??
                                          recommendedProduct['image_url'],
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.error),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      recommendedProduct['label'] ??
                                          recommendedProduct['name'] ??
                                          "",
                                      style: TextStyle(fontSize: 16),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      '\$${recommendedProduct['price']}',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.green),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );


    // return Scaffold(
    //   backgroundColor: Colors.white,
    //   appBar: AppBar(
    //     title: Text('Curated Recommendations'),
    //   ),
    //   body: Column(
    //     children: [
    //       // Top section with the shirt image and title
    //       Padding(
    //         padding: const EdgeInsets.all(16.0),
    //         child: Row(
    //           mainAxisAlignment: MainAxisAlignment.center, // Centers children horizontally
    //           children: [
    //             Image.network(
    //               this_item_jsonResponse['image_url'],
    //               width: 200,
    //               height: 200,
    //             ),
    //           ],
    //         ),
    //       ),

    //       // Buttons
    //       Row(
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         children: [
    //           ElevatedButton(
    //             onPressed: () {
    //               // Action for Modify Search
    //             },
    //             child: Text('Modify Search'),
    //           ),
    //         ],
    //       ),

    //       // Recommendations

    //       isLoading
    //         ? Center(child: CircularProgressIndicator())
    //         : Container(
    //           height: 250,
    //           child: ListView.builder(
    //             scrollDirection: Axis.horizontal,
    //             itemCount: recommended.length,
    //             itemBuilder: (context, index) {
    //               final recommendedProduct = recommended[index];
    //               return GestureDetector(
    //                 onTap: () {
    //                   Navigator.push(
    //                     context,
    //                     MaterialPageRoute(
    //                       builder: (context) => ProductDetailPage(productId: recommendedProduct['_id']),
    //                     ),
    //                   );
    //                 },
    //                 child: Container(
    //                   width: 150,
    //                   margin: EdgeInsets.all(8.0),
    //                   child: Column(
    //                     crossAxisAlignment: CrossAxisAlignment.start,
    //                     children: [
    //                       Image.network(
    //                         recommendedProduct['url'] ?? recommendedProduct['image_url'],
    //                         width: 150,
    //                         height: 150,
    //                         fit: BoxFit.cover,
    //                         errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
    //                       ),
    //                       SizedBox(height: 8),
    //                       Text(
    //                         recommendedProduct['label'] ?? recommendedProduct['name'] ?? "",
    //                         style: TextStyle(fontSize: 16),
    //                         maxLines: 2,
    //                         overflow: TextOverflow.ellipsis,
    //                       ),
    //                       Text(
    //                         '\$${recommendedProduct['price']}',
    //                         style: TextStyle(fontSize: 16, color: Colors.green),
    //                       ),
    //                     ],
    //                   )
    //                 )
    //               );
    //             }
    //           )
    //         )
    //     ],
    //   )
    // );
  }
}