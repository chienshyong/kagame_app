import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class CategoryPage extends StatefulWidget {
  final String category;
  CategoryPage({required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final AuthService authService = AuthService();
  List<Map<String, String>> images = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchImagesFromApi();
  }

  Future<void> fetchImagesFromApi() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'GET',
      Uri.parse('$baseUrl/wardrobe/category/${widget.category}'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString(); // Convert response to string
        final Map<String, dynamic> jsonResponse = json.decode(responseBody); // Decode JSON data as Map

        // Extract items list from the JSON response
        final List<dynamic> items = jsonResponse['items'];

        // Map items to images list
        setState(() {
          images = items.map((item) => {
            'url': item['url'] as String,
            'name': item['name'] as String,
            'id': item['_id'] as String,
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load images');
      }
    } catch (error) {
      print('Error fetching images: $error');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wardrobe (${widget.category})')
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Logo and Search bar
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to the home page when the logo is tapped
                    context.go('/home');
                  },
                  child: Image.asset(
                    'lib/assets/KagaMe.png',
                    width: 120.0,
                    height: 60.0,
                  ),
                ),
                SizedBox(
                    width: 16.0), // Space between the image and the search bar
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Wardrobe',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.filter_list, color: Colors.grey),
                          onPressed: () {
                            // Add filter action here
                            print('Filter icon tapped');
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            //Images
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 columns
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: images.length, // Dynamic item count
                  itemBuilder: (context, index) {
                    return GestureDetector(
                        onTap: () {
                          context.push('/wardrobe/item/${images[index]['id']!}');
                        },
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1, // Forces the image to be square
                                child: Image.network(
                                  images[index]['url']!,
                                  fit: BoxFit
                                      .cover, // Ensures the image covers the entire square
                                ),
                              ),
                            )
                          ],
                        ));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
