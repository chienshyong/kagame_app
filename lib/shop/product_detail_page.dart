import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ProductDetailPage extends StatefulWidget {
  final Map<String, dynamic> product;

  ProductDetailPage({required this.product});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final AuthService authService = AuthService();

  // Similar Products
  List<Map<String, dynamic>> similarProducts = [];
  bool isLoadingSimilar = true;

  // Recommended Outfits
  List<dynamic> recommendedOutfits = [];
  bool isLoadingOutfits = false;

  @override
  void initState() {
    super.initState();
    fetchSimilarProducts();
    fetchRecommendedOutfits(); // Fetch outfits in parallel
  }

  /// Fetch similar items
  Future<void> fetchSimilarProducts() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final productId = widget.product['id'];

    final Uri uri = Uri.parse('$baseUrl/shop/similar_items?id=$productId&n=5');

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
              'url': item['image_url']?.toString() ?? '',
              'label': item['name']?.toString() ?? '',
              'price': item['price']?.toString() ?? '',
              'product_url': item['product_url']?.toString() ?? '',
            };
          }).toList();
          isLoadingSimilar = false;
        });
      } else {
        throw Exception('Failed to load similar products');
      }
    } catch (error) {
      print('Error fetching similar products: $error');
      setState(() {
        isLoadingSimilar = false;
      });
    }
  }

  /// Fetch recommended outfits from /shop/item-outfit-search
  Future<void> fetchRecommendedOutfits() async {
    setState(() {
      isLoadingOutfits = true;
    });

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final productId = widget.product['id'];

    final Uri uri =
    Uri.parse('$baseUrl/shop/item-outfit-search?item_id=$productId');

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final outfits = data['outfits'] ?? [];

        setState(() {
          recommendedOutfits = outfits;
          isLoadingOutfits = false;
        });
      } else {
        throw Exception('Failed to load recommended outfits');
      }
    } catch (error) {
      print('Error fetching recommended outfits: $error');
      setState(() {
        isLoadingOutfits = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product['url'];
    final name = product['label'];
    final price = product['price'];
    final brandName = product['brand'] ?? 'Brand Name';
    final tags = product['tags'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    brandName,
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${price}',
                    style: TextStyle(fontSize: 20, color: Colors.green),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Tags:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Wrap(
                    spacing: 8.0,
                    children: tags.map<Widget>((tag) {
                      return Chip(
                        label: Text(tag),
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),

                  // Similar Items
                  Text(
                    'Similar Items',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  isLoadingSimilar
                      ? Center(child: CircularProgressIndicator())
                      : similarProducts.isNotEmpty
                      ? Container(
                    height: 250,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: similarProducts.length,
                      itemBuilder: (context, index) {
                        final similarProduct = similarProducts[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProductDetailPage(
                                        product: similarProduct),
                              ),
                            );
                          },
                          child: Container(
                            width: 150,
                            margin: EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Image.network(
                                  similarProduct['url'],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (context, error, stackTrace) =>
                                      Icon(Icons.error),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  similarProduct['label'],
                                  style: TextStyle(fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '\$${similarProduct['price']}',
                                  style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  )
                      : Text('No similar items found'),

                  SizedBox(height: 24),
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

  /// UI for recommended outfits
  Widget buildRecommendedOutfitsSection() {
    if (isLoadingOutfits) {
      return Center(child: CircularProgressIndicator());
    }

    if (recommendedOutfits.isEmpty) {
      return Text('No recommended outfits found');
    }

    // We'll stack outfits vertically in a Column.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: recommendedOutfits.map((outfit) {
        return buildOutfitCard(outfit);
      }).toList(),
    );
  }

  /// Individual outfit card
  Widget buildOutfitCard(dynamic outfit) {
    final styleName = outfit['style'] ?? '';
    final outfitName = outfit['name'] ?? '';
    // outfit['items'] is a List of { "original": {...}, "match": {...} }
    final outfitItems = outfit['items'] as List<dynamic>? ?? [];

    return Container(
      // Make the card fill the full width of screen except for padding on the sides
      margin: EdgeInsets.symmetric(vertical: 12.0),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      // You can also use a Card widget if you like:
      color: Colors.grey[100],
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            styleName,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            outfitName,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          SizedBox(height: 8),
          buildOutfitStack(outfitItems),
        ],
      ),
    );
  }

  /// Creates a vertical stack of images (top/bottom/shoes) filling parent width
  Widget buildOutfitStack(List<dynamic> outfitItems) {
    final topUrl = (outfitItems.isNotEmpty)
        ? outfitItems[0]['match'] != null ? outfitItems[0]['match']['image_url'] : null
        : null;
    final bottomUrl = (outfitItems.length > 1)
        ? outfitItems[1]['match'] != null ? outfitItems[1]['match']['image_url'] : null
        : null;
    final shoesUrl = (outfitItems.length > 2)
        ? outfitItems[2]['match'] != null ? outfitItems[2]['match']['image_url'] : null
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top
        if (topUrl != null && topUrl.isNotEmpty)
          Container(
            width: double.infinity,
            // No fixed height here
            child: Image.network(
              topUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Colors.grey[300],
            child: Center(child: Text("No Top")),
          ),

        SizedBox(height: 8),

        // Bottom
        if (bottomUrl != null && bottomUrl.isNotEmpty)
          Container(
            width: double.infinity,
            // No fixed height here
            child: Image.network(
              bottomUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Colors.grey[300],
            child: Center(child: Text("No Bottom")),
          ),

        SizedBox(height: 8),

        // Shoes
        if (shoesUrl != null && shoesUrl.isNotEmpty)
          Container(
            width: double.infinity,
            // No fixed height here
            child: Image.network(
              shoesUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(vertical: 20),
            color: Colors.grey[300],
            child: Center(child: Text("No Shoes")),
          ),
      ],
    );
  }
}
