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
    // Debug the received product data.
    debugPrint("[DEBUG] Product Data: ${jsonEncode(widget.product)}");
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
              // Use image_url and name keys from backend
              'url': item['image_url']?.toString() ?? '',
              'label': item['name']?.toString() ?? '',
              'price': item['price']?.toString() ?? '',
              'product_url': item['product_url']?.toString() ?? '',
              'category': item['category']?.toString() ?? '',
              'clothing_type': item['clothing_type']?.toString() ?? '',
              'color': item['color']?.toString() ?? '',
              'material': item['material']?.toString() ?? '',
              'other_tags': item['other_tags']?.toString() ?? '',
            };
          }).toList();
          isLoadingSimilar = false;
        });
      } else {
        throw Exception('Failed to load similar products');
      }
    } catch (error) {
      debugPrint('Error fetching similar products: $error');
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

    final Uri uri = Uri.parse('$baseUrl/shop/item-outfit-search?item_id=$productId');

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
      debugPrint('Error fetching recommended outfits: $error');
      setState(() {
        isLoadingOutfits = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use fallback: if 'url' or 'label' are null, try using 'image_url' and 'name'
    final product = widget.product;
    final imageUrl = product['url'] ?? product['image_url'];
    final name = product['label'] ?? product['name'];
    final price = product['price'];
    final brandName = product['brand'] ?? 'Brand Name';
    final tags = product['tags'] ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(name ?? "Product Detail"),
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
                    name ?? "",
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
                      return Chip(label: Text(tag));
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
                                builder: (context) => ProductDetailPage(product: similarProduct),
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
                                  similarProduct['url'] ?? similarProduct['image_url'],
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  similarProduct['label'] ?? similarProduct['name'] ?? "",
                                  style: TextStyle(fontSize: 16),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '\$${similarProduct['price']}',
                                  style: TextStyle(fontSize: 16, color: Colors.green),
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
    final outfitItems = outfit['items'] as List<dynamic>? ?? [];
    return Container(
      margin: EdgeInsets.symmetric(vertical: 12.0),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[100],
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(styleName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(outfitName, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          SizedBox(height: 8),
          buildOutfitStack(outfitItems),
        ],
      ),
    );
  }

  /// Creates a vertical stack of images (Tops, Bottoms, Shoes).
  /// This uses the product's 'category' field (passed from shop/items)
  /// to determine which slot should show the original product.
  Widget buildOutfitStack(List<dynamic> outfitItems) {
    final String originalCategoryRaw = widget.product['category']?.toString() ?? '';
    final String originalCategory = originalCategoryRaw.trim().toLowerCase();
    debugPrint("[DEBUG] Normalized Original Category: '$originalCategory'");

    String? topUrl;
    String? bottomUrl;
    String? shoesUrl;

    Map<String, dynamic>? topProduct;
    Map<String, dynamic>? bottomProduct;
    Map<String, dynamic>? shoesProduct;

    // Loop through each recommended outfit item.
    for (var outfitItem in outfitItems) {
      final matchData = outfitItem['match'];
      if (matchData == null) continue;
      final String itemCategory = (matchData['category'] ?? '').toString().toLowerCase();
      final String? itemImageUrl = matchData['image_url'];
      debugPrint("[DEBUG] Found recommended item - Category: $itemCategory, Image: $itemImageUrl");

      if (itemImageUrl != null && itemImageUrl.isNotEmpty) {
        if (itemCategory == 'tops') {
          topUrl = itemImageUrl;
          topProduct = matchData;
        } else if (itemCategory == 'bottoms') {
          bottomUrl = itemImageUrl;
          bottomProduct = matchData;
        } else if (itemCategory == 'shoes') {
          shoesUrl = itemImageUrl;
          shoesProduct = matchData;
        }
      }
    }

    final String originalImageUrl = (widget.product['image_url'] ?? widget.product['url'] ?? '').toString();
    debugPrint("[DEBUG] Original Product Image URL: $originalImageUrl");

    // Overwrite the slot corresponding to the original product's category.
    if (originalCategory == 'tops') {
      topUrl = originalImageUrl;
      topProduct = widget.product;
      debugPrint("[DEBUG] Overwriting 'Tops' slot with original item.");
    } else if (originalCategory == 'bottoms') {
      bottomUrl = originalImageUrl;
      bottomProduct = widget.product;
      debugPrint("[DEBUG] Overwriting 'Bottoms' slot with original item.");
    } else if (originalCategory == 'shoes') {
      shoesUrl = originalImageUrl;
      shoesProduct = widget.product;
      debugPrint("[DEBUG] Overwriting 'Shoes' slot with original item.");
    } else {
      debugPrint("[DEBUG] Original category '$originalCategory' did not match tops/bottoms/shoes.");
    }

    // Helper widget to build each slot with navigation.
    Widget buildSlot(String? slotUrl, Map<String, dynamic>? slotProduct, String placeholder) {
      if (slotUrl != null && slotUrl.isNotEmpty && slotProduct != null) {
        return GestureDetector(
          onTap: () {
            debugPrint("Tapped on $placeholder slot: ${slotProduct['name']}");
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailPage(product: slotProduct),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            child: Image.network(
              slotUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
          ),
        );
      } else {
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20),
          color: Colors.grey[300],
          child: Center(child: Text("No $placeholder")),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildSlot(topUrl, topProduct, "Top"),
        SizedBox(height: 8),
        buildSlot(bottomUrl, bottomProduct, "Bottom"),
        SizedBox(height: 8),
        buildSlot(shoesUrl, shoesProduct, "Shoes"),
      ],
    );
  }
}
