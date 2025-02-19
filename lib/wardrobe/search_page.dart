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
      Uri.parse('$baseUrl/wardrobe/categories'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);

        // Extract categories list from the JSON response
        final List<dynamic> categories = jsonResponse['categories'];

        List<Map<String, String>> fetchedImages = categories.map((item) => {
              'url': item['url'] as String,
              'label': item['category'] as String
            }).toList();


        setState(() {
          images = fetchedImages;
        });

        }
      } catch (error) {
      print('Error fetching images: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search: ${widget.query}')),
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
                      textAlign: TextAlign.center,
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
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: images.length, // Dynamic item count
                  itemBuilder: (context, index) {
                    return GestureDetector(
                        onTap: () {
                          // Navigate to Navigator page on tap
                          context.push(
                              '/wardrobe/category/${images[index]['label']!}');
                        },
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1, // Forces the image to be square
                                child: 
                                    Image.network(
                                      images[index]['url']!,
                                      fit: BoxFit.cover, // Adjusts the image fit
                                    ),
                              ),
                            ),
                            SizedBox(
                                height: 8.0), // Space between image and text
                            Text(
                              images[index]['label']!,
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
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
