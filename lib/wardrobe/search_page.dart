import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class SearchPage extends StatefulWidget {
  final String query;
  SearchPage({required this.query});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with RouteAware{
  final AuthService authService = AuthService(); // Handles API authentication
  List<Map<String, String>> images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImagesFromApi(); // Fetch new images
  }

  /// Fetch images from API 
  Future<void> fetchImagesFromApi() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'GET',
      Uri.parse('$baseUrl/wardrobe/search/${widget.query}'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);

        final List<dynamic> items = jsonResponse['items'];

        List<Map<String, String>> fetchedImages = items.map((item) => {
              'id': item['_id'] as String,
              'name': item['name'] as String,
              'url': item['url'] as String
            }).toList();


        setState(() {
          images = fetchedImages;
          isLoading = false;
        });

        }
      } catch (error) {
      print('Error fetching images: $error');
      setState(() {
          isLoading = false;
        });
    }
  }

  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();
    
    return Scaffold(
      appBar: AppBar(title: Text('Search results for "${widget.query}"')),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      backgroundColor: Colors.white,
                      pinned: false,
                      floating: true,
                      snap: true,
                      expandedHeight: 80.0,
                      automaticallyImplyLeading:
                          false,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              GestureDetector(
                                child: Image.asset(
                                  'lib/assets/KagaMe.png',
                                  width: 120.0,
                                  height: 60.0,
                                ),
                              ),
                              
                              // Space between logo and the search bar
                              SizedBox(width: 16.0),
                              
                              // Search bar
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30.0),
                                    border: Border.all(
                                      color: Colors.grey,
                                      width: 1.0,
                                    ),
                                  ),
                                  padding: 
                                      const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: TextField(
                                    controller: searchController,
                                    textAlign: TextAlign.left,
                                    onSubmitted: (query) {
                                      if (query.isNotEmpty) {
                                        context.push('/wardrobe/search/$query');
                                      }
                                    },
                                    decoration: InputDecoration(
                                      hintText: 'Search My Wardrobe',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                      border: InputBorder.none,
                                      prefixIcon: 
                                        Icon(Icons.search, color: Colors.grey),
                                      // suffixIcon: IconButton(
                                      //   icon: Icon(Icons.filter_list,
                                      //       color: Colors.grey),
                                      //   onPressed: () {
                                      //     print('Filter icon tapped');
                                      //   },
                                      // ),
                                      contentPadding:
                                          EdgeInsets.symmetric(vertical: 12.0),
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ];
                },
                body: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    physics: AlwaysScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Two columns
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          context.push('/wardrobe/item/${images[index]['id']!}');
                        },
                        child: Column(
                          children: [
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1, // Keeps the images square
                                child: Image.network(
                                  images[index]['url']!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.error),
                                ),
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              textAlign: TextAlign.center,
                              images[index]['name']!,
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
    );
  }
}
