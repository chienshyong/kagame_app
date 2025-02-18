import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class WardrobePage extends StatefulWidget {
  WardrobePage({Key? key}) : super(key: key);

  @override
  State<WardrobePage> createState() => _WardrobePageState();
}

class _WardrobePageState extends State<WardrobePage> with RouteAware{
  final AuthService authService = AuthService(); // Handles API authentication
  List<Map<String, String>> images = []; // Stores fetch wardrobe items
  bool isLoading = true; // Tracks API loading state

  @override
  void initState() {
    super.initState();
    fetchImagesFromApi();
  }

  Future<void> fetchImagesFromApi() async {
    isLoading = true;
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
        final responseBody = await response.stream.bytesToString(); // Convert response to string
        final Map<String, dynamic> jsonResponse = json.decode(responseBody); // Decode JSON data as Map

        // Extract categories list from the JSON response
        final List<dynamic> categories = jsonResponse['categories'];

        // Map categories to images list
        setState(() {
          images = categories.map((item) => {
            'url': item['url'] as String,
            'label': item['category'] as String
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
        title: Text('My Wardrobe'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            fetchImagesFromApi();
          },
          child: Column(
            children: [
              // Logo and Search Bar (Top Section)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                      },
                      child: Image.asset(
                        'lib/assets/KagaMe.png',
                        width: 120.0,
                        height: 60.0,
                      ),
                    ),
                    SizedBox(width: 16.0), // Space between logo and search bar
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
                                print('Filter icon tapped');
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Recommended and All Products Tabs (Middle Section)
              Container(
                color: Colors.grey[200], // Background for tabs
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Handle recommended tab logic
                      },
                      child: Text("Recommended", style: TextStyle(fontSize: 16.0)),
                    ),
                    TextButton(
                      onPressed: () {
                        // Handle all products tab logic
                      },
                      child: Text("All Products", style: TextStyle(fontSize: 16.0)),
                    ),
                  ],
                ),
              ),

              // Images GridView (Bottom Section)
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          context.push(
                              '/wardrobe/category/${images[index]['label']!}');
                        },
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: Image.network(
                                  images[index]['url']!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            SizedBox(height: 8.0),
                            Text(
                              images[index]['label']!,
                              style: TextStyle(
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
