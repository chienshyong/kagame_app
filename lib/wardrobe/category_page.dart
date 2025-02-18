import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryPage extends StatefulWidget {
  final String category;
  CategoryPage({required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final AuthService authService = AuthService();
  List<Map<String, String>> cachedImages = []; // Cached images
  List<Map<String, String>> newImages = []; // Fetched new images
  bool isLoading = true;
  bool isFetching = false; // Track if new images are being fetched

  // Cache Manager
  final BaseCacheManager cacheManager = DefaultCacheManager();

  @override
  void initState() {
    super.initState();
    loadPersistedImages().then((_) {
      fetchImagesFromApi(); // Fetch new images in the background
    });
  }

  /// Load stored image URLs from SharedPreferences (cached images)
  Future<void> loadPersistedImages() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedImages = prefs.getString('category_images_${widget.category}');

    if (storedImages != null) {
      List<dynamic> decodedList = json.decode(storedImages); // Decode JSON string to List<dynamic>

      setState(() {
        cachedImages = decodedList
            .map((item) => Map<String, String>.from(item)) // Convert Map<String, dynamic> to Map<String, String>
            .toList();
        isLoading = false; // Stop loading since we have cached data
      });
    }
  }

  /// Store new image URLs in SharedPreferences
  Future<void> saveImagesToLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('category_images_${widget.category}', json.encode(newImages));
    await _cacheImages(newImages);
  }

  /// Downloads and caches multiple images simultaneously from a List<Map<String, String>>
  Future<void> _cacheImages(List<Map<String, String>> newImages) async {
    try {
      // Create a list of Future tasks for downloading images
      List<Future<void>> cacheTasks = newImages.map((image) async {
        String url = image['url'] ?? ''; // Ensure URL exists
        if (url.isNotEmpty) {
          FileInfo? fileInfo = await cacheManager.getFileFromCache(url);
          if (fileInfo == null) {
            await cacheManager.downloadFile(url); // Download only if not cached
          }
        }
      }).toList();

      // Wait for all downloads to complete
      await Future.wait(cacheTasks);

      print('All images downloaded and cached.');
    } catch (e) {
      print('Error caching images: $e');
    }
  }

  /// Fetch images from API (background update)
  Future<void> fetchImagesFromApi() async {
    if (isFetching) return; // Prevent multiple API calls at once
    setState(() {
      isFetching = true;
    });

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
        final responseBody = await response.stream.bytesToString();
        final Map<String, dynamic> jsonResponse = json.decode(responseBody);
        final List<dynamic> items = jsonResponse['items'];

        List<Map<String, String>> fetchedImages = items.map((item) => {
              'url': item['url'] as String,
              'name': item['name'] as String,
              'id': item['_id'] as String,
            }).toList();

        // Compare fetched images to cached images, if IDs match don't update
        // Convert list of maps to a set of IDs for comparison
        Set<String> cachedImageIds = cachedImages.map((img) => img['id']!).toSet();
        Set<String> fetchedImageIds = fetchedImages.map((img) => img['id']!).toSet();

        // Check if fetchedImages has any new items compared to cachedImages
        bool hasNewImages = !cachedImageIds.containsAll(fetchedImageIds) || !fetchedImageIds.containsAll(cachedImageIds);

        if (hasNewImages) {
          setState(() {
            newImages = fetchedImages;
          });

          await saveImagesToLocal(); // Save new images to SharedPreferences
          updateUIWithNewImages(); // Swap the images once all are fetched
        }
      } else {
        throw Exception('Failed to load images');
      }
    } catch (error) {
      print('Error fetching images: $error');
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  /// Replace cached images with new images once they are all fetched
  void updateUIWithNewImages() {
    setState(() {
      cachedImages = List.from(newImages); // Update displayed images
    });
  }

  /// Refresh images manually
  Future<void> refreshImages() async {
    await cacheManager.emptyCache(); // Clear cached image files
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('category_images_${widget.category}'); // Remove stored URLs
    setState(() {
      isLoading = true;
      cachedImages = [];
    });
    fetchImagesFromApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('My Wardrobe (${widget.category})'), actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: refreshImages, // Manual refresh button
        ),
      ]),
      body: SafeArea(
        child: Column(
          children: [
            // Logo and Search Bar
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.go('/home'),
                  child: Image.asset(
                    'lib/assets/KagaMe.png',
                    width: 120.0,
                    height: 60.0,
                  ),
                ),
                SizedBox(width: 16.0),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(color: Colors.grey, width: 1.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search Wardrobe',
                        border: InputBorder.none,
                        prefixIcon: Icon(Icons.search, color: Colors.grey),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.filter_list, color: Colors.grey),
                          onPressed: () => print('Filter icon tapped'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Image Grid
            Expanded(
              child: isLoading && cachedImages.isEmpty
                  ? Center(child: CircularProgressIndicator()) // Show loader if no cached images
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                        ),
                        itemCount: cachedImages.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => context.push('/wardrobe/item/${cachedImages[index]['id']!}'),
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child:  CachedNetworkImage(
                                      cacheManager: cacheManager,
                                      imageUrl: cachedImages[index]['url']!,
                                      // placeholder: (context, url) =>
                                      //     Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Icon(Icons.error),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
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
    );
  }
}
