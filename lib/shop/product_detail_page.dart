import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;
  const ProductDetailPage({required this.productId});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final AuthService authService = AuthService();

  Map<String, dynamic>? productDoc;
  bool isLoadingProduct = true;

  List<Map<String, dynamic>> similarProducts = [];
  bool isLoadingSimilar = true;

  List<dynamic> recommendedOutfits = [];
  bool isLoadingOutfits = false;

  @override
  void initState() {
    super.initState();
    _fetchProductDoc();
  }

  /// Step 1: Fetch the main product
  Future<void> _fetchProductDoc() async {
    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final uri = Uri.parse('$baseUrl/shop/item/${widget.productId}');

    try {
      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          productDoc = data;
          isLoadingProduct = false;
        });
        // Then fetch similar & recommended
        await fetchSimilarProducts();
        await fetchRecommendedOutfits();
      } else {
        throw Exception('Failed to load product detail');
      }
    } catch (error) {
      debugPrint('Error fetching product detail: $error');
      setState(() => isLoadingProduct = false);
    }
  }

  /// Step 2: fetch similar items
  Future<void> fetchSimilarProducts() async {
    if (productDoc == null) return;
    setState(() => isLoadingSimilar = true);

    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final String productId = productDoc!['id'] ?? '';
    final uri = Uri.parse('$baseUrl/shop/similar_items?id=$productId&n=5');

    try {
      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          similarProducts = data.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
              'url': item['image_url'] ?? '',
              'label': item['name'] ?? '',
              'price': item['price']?.toString() ?? '',
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load similar products');
      }
    } catch (error) {
      debugPrint('Error fetching similar products: $error');
    } finally {
      setState(() => isLoadingSimilar = false);
    }
  }

  /// Step 3: fetch recommended outfits
  Future<void> fetchRecommendedOutfits() async {
    if (productDoc == null) return;
    setState(() => isLoadingOutfits = true);

    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final String productId = productDoc!['id'] ?? '';
    final uri =
        Uri.parse('$baseUrl/shop/item-outfit-search?item_id=$productId');

    try {
      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          recommendedOutfits = data['outfits'] ?? [];
        });
      } else {
        throw Exception('Failed to load recommended outfits');
      }
    } catch (error) {
      debugPrint('Error fetching recommended outfits: $error');
    } finally {
      setState(() => isLoadingOutfits = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingProduct) {
      return Scaffold(
        appBar: AppBar(title: Text("Loading...")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (productDoc == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Error")),
        body: Center(child: Text('Product not found.')),
      );
    }

    final imageUrl = productDoc!['image_url'] ?? '';
    final name = productDoc!['name'] ?? '';
    final price = productDoc!['price'] ?? '';
    final retailerName = productDoc!['retailer'] ?? 'Brand Name';
    final tags = productDoc!['other_tags'] ?? [];

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main product image
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 400,
              fit: BoxFit.contain,
              errorBuilder: (ctx, e, st) => Icon(Icons.error),
            ),
            // Product info
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(name,
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(retailerName,
                      style: TextStyle(fontSize: 20, color: Colors.grey)),
                  Text('\$${price.toString()}',
                      style: TextStyle(fontSize: 18, color: Colors.green)),
                  Text('Tags:',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 6.0,
                    children: (tags is List)
                        ? tags
                            .map<Widget>(
                                (tag) => Chip(label: Text(tag.toString()), padding: EdgeInsets.all(2), materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,))
                            .toList()
                        : [],
                  ),
                  SizedBox(height: 8),

                  // Similar Items
                  Text('Similar Items',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  isLoadingSimilar
                      ? Center(child: CircularProgressIndicator())
                      : (similarProducts.isNotEmpty
                          ? buildSimilarItems()
                          : Text('No similar items found')),
                  // Recommended Outfits
                  Text('Recommended Outfits',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  buildRecommendedOutfitsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSimilarItems() {
    return Container(
      height: 232,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: similarProducts.length,
        itemBuilder: (context, index) {
          final sp = similarProducts[index];
          return GestureDetector(
            onTap: () {
              // Navigate to detail page
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailPage(productId: sp['id']),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: EdgeInsets.all(4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(
                    sp['url'] ?? '',
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, e, st) => Icon(Icons.error),
                  ),
                  SizedBox(height: 8),
                  Text(sp['label'] ?? "",
                      style: TextStyle(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text('\$${sp['price']}',
                      style: TextStyle(fontSize: 14, color: Colors.green)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildRecommendedOutfitsSection() {
    if (isLoadingOutfits) {
      return Center(child: CircularProgressIndicator());
    }
    if (recommendedOutfits.isEmpty) {
      return Text('No recommended outfits found');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          recommendedOutfits.map((outfit) => buildOutfitCard(outfit)).toList(),
    );
  }

  Widget buildOutfitCard(dynamic outfit) {
    final styleName = outfit['style'] ?? '';
    final outfitName = outfit['name'] ?? '';
    final outfitItems = outfit['items'] as List<dynamic>? ?? [];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(styleName,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(outfitName,
              style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          SizedBox(height: 8),

          // Show top/bottom/shoes layout
          OutfitStackWidget(
            originalDoc: productDoc!,
            outfitItems: outfitItems,
          ),
        ],
      ),
    );
  }
}

class OutfitStackWidget extends StatefulWidget {
  final Map<String, dynamic> originalDoc;
  final List<dynamic> outfitItems;

  const OutfitStackWidget({
    Key? key,
    required this.originalDoc,
    required this.outfitItems,
  }) : super(key: key);

  @override
  State<OutfitStackWidget> createState() => _OutfitStackWidgetState();
}

class _OutfitStackWidgetState extends State<OutfitStackWidget> {
  final AuthService authService = AuthService();

  Map<String, dynamic>? topsDoc;
  Map<String, dynamic>? bottomsDoc;
  Map<String, dynamic>? shoesDoc;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _assignOriginalDoc();
    _fetchMatchedItems();
  }

  void _assignOriginalDoc() {
    final originalCat =
        widget.originalDoc['category']?.toString().toLowerCase() ?? '';
    if (originalCat == 'tops') {
      topsDoc = widget.originalDoc;
    } else if (originalCat == 'bottoms') {
      bottomsDoc = widget.originalDoc;
    } else if (originalCat == 'shoes') {
      shoesDoc = widget.originalDoc;
    }
  }

  Future<void> _fetchMatchedItems() async {
    final fetchFutures = <Future>[];

    for (final outfitItem in widget.outfitItems) {
      final matchData = outfitItem['match'];
      if (matchData == null) continue;

      final matchedId = matchData['id'];
      if (matchedId == null || matchedId.isEmpty) continue;

      fetchFutures.add(_fetchSingleDoc(matchedId));
    }

    try {
      await Future.wait(fetchFutures);
    } catch (e) {
      debugPrint("Error in _fetchMatchedItems: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchSingleDoc(String itemId) async {
    final token = await authService.getToken();
    final baseUrl = authService.baseUrl;
    final uri = Uri.parse('$baseUrl/shop/item/$itemId');

    try {
      final response =
          await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final doc = json.decode(response.body);
        final cat = doc['category']?.toString().toLowerCase() ?? '';

        if (cat == 'tops') {
          topsDoc = doc;
        } else if (cat == 'bottoms') {
          bottomsDoc = doc;
        } else if (cat == 'shoes') {
          shoesDoc = doc;
        }
      } else {
        debugPrint("Failed to fetch item doc $itemId: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error fetching item doc $itemId: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSlot(topsDoc, "tops"),
        SizedBox(height: 8),
        _buildSlot(bottomsDoc, "bottoms"),
        SizedBox(height: 8),
        _buildSlot(shoesDoc, "shoes"),
      ],
    );
  }

  Widget _buildSlot(Map<String, dynamic>? doc, String placeholder) {
    if (doc == null) {
      return Container(
        margin: EdgeInsets.symmetric(
            horizontal:
                MediaQuery.of(context).size.width * 0.08), // Default 10% padding
        color: Colors.grey[300],
        alignment: Alignment.center,
        child: Text("No $placeholder"),
      );
    }

    final cropped = doc['cropped_image_url'] ?? '';
    final fallback = doc['image_url'] ?? '';
    final imageUrl = (cropped.isNotEmpty) ? cropped : fallback;

    // Determine padding based on category
    final category = doc['category']?.toString().toLowerCase() ?? '';
    final double sidePadding;

    if (category == 'bottoms') {
      sidePadding =
          MediaQuery.of(context).size.width * 0.18; // 20% padding for bottoms
    } else if (category == 'shoes') {
      sidePadding =
          MediaQuery.of(context).size.width * 0.25; // 30% padding for shoes
    } else {
      sidePadding = MediaQuery.of(context).size.width *
          0.1; // 10% padding for tops & others
    }

    return GestureDetector(
      onTap: () {
        final itemId = doc['id'] ?? '';
        if (itemId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProductDetailPage(productId: itemId),
            ),
          );
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(
            horizontal: sidePadding), // Apply category-based padding
        child: Image.network(
          imageUrl,
          width:
              double.infinity, // Ensure it spans the full width (minus padding)
          fit: BoxFit.contain, // Maintain aspect ratio
          errorBuilder: (ctx, e, st) => Container(
            color: Colors.grey[300],
            alignment: Alignment.center,
            child: Text("Error loading image"),
          ),
        ),
      ),
    );
  }
}
