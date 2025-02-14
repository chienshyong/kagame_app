import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class RecommendPage extends StatefulWidget {
  final String id;
  RecommendPage({required this.id});
  
  @override
  State<StatefulWidget> createState() => _RecommendPageState();
}

class _RecommendPageState extends State<RecommendPage> {
  final AuthService authService = AuthService();
  bool isLoading = false;

  // Dummy image list for the infinite scroll
  List<String> _items = List.generate(10, (index) => 'Item $index');

  // Scroll controller to detect when the user scrolls to the bottom
  ScrollController _scrollController = ScrollController();

  //Placeholders while API is called
  Map<String, dynamic> jsonResponse = {'image_url': 'https://craftsnippets.com/articles_images/placeholder/placeholder.jpg', 'category': '', 'color': '', 'name': ''};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    fetchItemFromApi();
  }

    // Fetch more items when scrolled to the bottom
  void _fetchMore() async {
    if (!isLoading) {
      setState(() {
        isLoading = true;
      });

      // Simulate a delay for loading more items (replace with API call)
      await Future.delayed(Duration(seconds: 2));

      setState(() {
        isLoading = false;
        _items.addAll(List.generate(10, (index) => 'Item ${_items.length + index}'));
      });
    }
  }

  // Detect when the user has scrolled to the bottom
  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchMore();
    }
  }

  Future<void> fetchItemFromApi() async {
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
          jsonResponse = json.decode(responseBody); // Decode JSON data as Map
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (error) {
      print('Error fetching image: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('Curated Recommendations'),
      ),
      body: Column(
        children: [
          // Top section with the shirt image and title
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Image.network(
                  jsonResponse['image_url'],
                  width: 200,
                  height: 200,
                ),
                SizedBox(height: 8),
                Text(
                  'This will\ngo well with',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),

          // Buttons
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

          SizedBox(height: 16),

          Expanded(
            child: TabbedPage()
            ),

          // // Infinite scroll grid section
          // Expanded(
          //   child: GridView.builder(
          //     controller: _scrollController,
          //     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          //       crossAxisCount: 2,
          //       crossAxisSpacing: 8.0,
          //       mainAxisSpacing: 8.0,
          //       childAspectRatio: 0.8,
          //     ),
          //     itemCount: _items.length + 1,
          //     itemBuilder: (context, index) {
          //       if (index == _items.length) {
          //         return isLoading
          //             ? Center(child: CircularProgressIndicator())
          //             : SizedBox(); // Show loading indicator when loading
          //       }

          //       // Replace with your image network URL for real items
          //       return Column(
          //         children: [
          //           Expanded(
          //             child: Container(
          //               decoration: BoxDecoration(
          //                 image: DecorationImage(
          //                   image: NetworkImage(
          //                       'https://dummyimage.com/200x300/000/fff&text=${_items[index]}'), // Placeholder
          //                   fit: BoxFit.cover,
          //                 ),
          //                 borderRadius: BorderRadius.circular(10),
          //               ),
          //             ),
          //           ),
          //         ],
          //       );
          //     },
          //   ),
          // ),
        ],
      ),
    );
  }
}

class TabbedPage extends StatefulWidget {
  @override
  _TabbedPageState createState() => _TabbedPageState();
}

class _TabbedPageState extends State<TabbedPage> {
  final AuthService authService = AuthService();
  bool isLoading = false;

  // Dummy image list for the infinite scroll
  List<String> _items = List.generate(10, (index) => 'Item $index');

  // Scroll controller to detect when the user scrolls to the bottom
  ScrollController _scrollController = ScrollController();

  //Placeholders while API is called
  Map<String, dynamic> jsonResponse = {'image_url': 'https://craftsnippets.com/articles_images/placeholder/placeholder.jpg', 'category': '', 'color': '', 'name': ''};

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, // Number of tabs
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: "From Partner Brands"),
              Tab(text: "From Your Wardrobe"),
            ],
          ),

      
        Expanded(child: TabBarView(
          children: [
            Center( // From Partner Brands Tab
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Recommendations with items from our partner brands"),
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return isLoading
                              ? Center(child: CircularProgressIndicator())
                              : SizedBox(); // Show loading indicator when loading
                        }

                        // Replace with your image network URL for real items
                        return Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        'https://dummyimage.com/200x300/000/fff&text=${_items[index]}'), // Placeholder
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              Center( // From Your Wardrobe Tab
                child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Recommendations with items from your personal wardrobe"),
                  Expanded(
                    child: GridView.builder(
                      controller: _scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: _items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _items.length) {
                          return isLoading
                              ? Center(child: CircularProgressIndicator())
                              : SizedBox(); // Show loading indicator when loading
                        }

                        // Replace with your image network URL for real items
                        return Column(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(
                                        'https://dummyimage.com/200x300/000/fff&text=${_items[index]}'), // Placeholder
                                    fit: BoxFit.cover,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }
}