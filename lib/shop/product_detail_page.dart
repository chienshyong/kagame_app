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
  Map<String?, dynamic> clothingLikes = {};
  Map<String?, dynamic> clothingDislikes = {};

  bool isLoadingOutfits = false;

  void toggleLike(String? itemName) {
    bool isAdded = false;
    if (clothingDislikes.containsKey(itemName)) {
      clothingDislikes.remove(itemName);
      updateClothingDislikes(itemName!, false, []);
    }
    if (clothingLikes.containsKey(itemName)) {
      clothingLikes.remove(itemName);
    } else if (!clothingLikes.containsKey(itemName)) {
      clothingLikes[itemName] = true;
      isAdded = true;
    }
    updateClothingLikes(itemName!, isAdded);
  }

  void toggleDislike(String? itemName, String? itemCategory, BuildContext context, String? clothingType, String? otherTags, String? color) async {
    if (clothingLikes.containsKey(itemName)) {
      clothingLikes.remove(itemName);
      updateClothingLikes(itemName!, false);
    }
    List<dynamic> feedbackList = [itemCategory, itemName];
    bool isAdded = false;
    if (clothingDislikes.containsKey(itemName)) {
      clothingDislikes.remove(itemName);
    } else if (!clothingDislikes.containsKey(itemName)) {
      clothingDislikes[itemName] = true;
      isAdded = true;
      String? feedbackData = await _feedbackFormBuilder(context);
      if (feedbackData == "Type of item") {
        feedbackList.add("Type of item");
        feedbackList.add(clothingType);
      } else if (feedbackData == "Style") {
        feedbackList.add("Style");
        feedbackList.add(otherTags);
      } else if (feedbackData == "Colour") {
        feedbackList.add("Colour");
        feedbackList.add(color);
      }
    }
    updateClothingDislikes(itemName!, isAdded, feedbackList);
  }

  Future<void> updateClothingLikes(String itemName, bool isAdded) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    Map<String, bool> updatedClothingLikesItem = {};

    if (isAdded) {
      updatedClothingLikesItem = {itemName: true};
    } else if (!isAdded) {
      updatedClothingLikesItem = {itemName: false};
    }

    String jsonData = jsonEncode(updatedClothingLikesItem);

    final response = await http.post(
      Uri.parse('$baseUrl/profile/updateclothinglikes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonData,
    );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      final message = responseJson["detail"];
      print(responseJson["detail"]);
      throw Exception(message);
    }
  }

  Future<void> updateClothingDislikes(String itemName, bool isAdded, List<Object?> feedbackList) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    Map<String, dynamic> updatedClothingDislikesItem = {};

    if (isAdded) {
      updatedClothingDislikesItem = {itemName: true, "feedback": feedbackList};
    } else if (!isAdded) {
      updatedClothingDislikesItem = {itemName: false};
    }

    String jsonData = jsonEncode(updatedClothingDislikesItem);

    final response = await http.post(
      Uri.parse('$baseUrl/profile/updateclothingdislikes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonData,
    );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      final message = responseJson["detail"];
      print(responseJson["detail"]);
      throw Exception(message);
    }
  }

  @override
  void initState() {
    super.initState();
    // Debug the received product data.
    debugPrint("[DEBUG] Product Data: ${jsonEncode(widget.product)}");
    getClothingPreferences();
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

  Future<void> getClothingPreferences() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/getclothingprefs'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);

        setState(() {
          clothingLikes = Map<String, dynamic>.from(jsonResponse['clothing_likes'] ?? {});
          clothingDislikes = Map<String, dynamic>.from(jsonResponse['clothing_dislikes'] ?? {});
        });
      }
    } catch (error) {
      print('Error fetching clothing preferences: $error');
    }
  }

  Future<String?> _feedbackFormBuilder(BuildContext context) async {
    String? feedbackData = "";

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('What did you dislike about this item?'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Type of item"),
                    onTap: () {
                      feedbackData = "Type of item";
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text("Style"),
                    onTap: () {
                      feedbackData = "Style";
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: Text("Colour"),
                    onTap: () {
                      feedbackData = "Colour";
                      Navigator.pop(context);
                    },
                  ),
                  SizedBox(height: 10),
                ],
              );
            },
          ),
          // actions: <Widget>[
          //   TextButton(
          //     child: const Text('Submit'),
          //     onPressed: () {
          //       feedbackData = issueCause;
          //       debugPrint("[DEBUG] Submitted Feedback: $feedbackData");
          //       Navigator.of(context).pop();
          //     },
          //   ),
          // ],
        );
      },
    );
    return feedbackData;
  }

  /// Creates a vertical stack of images (Tops, Bottoms, Shoes).
  /// This uses the product's 'category' field (passed from shop/items)
  /// to determine which slot should show the original product.
  Widget buildOutfitStack(List<dynamic> outfitItems) {
    final String originalCategoryRaw = widget.product['category']?.toString() ?? '';
    final String originalCategory = originalCategoryRaw.trim().toLowerCase();
    final String originalName = (widget.product['label'] ?? widget.product['name'] ?? '').toString();
    debugPrint("[DEBUG] Normalized Original Category: '$originalCategory'");

    String? topUrl;
    String? bottomUrl;
    String? shoesUrl;

    Map<String, dynamic>? topProduct;
    Map<String, dynamic>? bottomProduct;
    Map<String, dynamic>? shoesProduct;

    String? topName;
    String? bottomName;
    String? shoesName;

    // Loop through each recommended outfit item.
    for (var outfitItem in outfitItems) {
      final matchData = outfitItem['match'];
      if (matchData == null) continue;
      final String itemCategory = (matchData['category'] ?? '').toString().toLowerCase();
      final String? itemImageUrl = matchData['image_url'];
      String? itemName = outfitItem['match']['name'];
      debugPrint("[DEBUG] Found recommended item - Category: $itemCategory, Image: $itemImageUrl");

      debugPrint("[DEBUG] itemName"+ itemName!);
      if (itemCategory == 'tops') {
        topName = itemName;
      } else if (itemCategory == 'bottoms') {
        bottomName = itemName;
      } else if (itemCategory == 'shoes') {
        shoesName = itemName;
      }

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

    if (shoesName == null) {
      shoesName = "No shoes";
    }
    if (topName == null) {
      topName = "No top";
    }
    if (bottomName == null) {
      bottomName = "No bottoms";
    }

    if (originalCategory == 'tops') {
      topName = originalName;
    } else if (originalCategory == 'bottoms') {
      bottomName = originalName;
    } else if (originalCategory == 'shoes') {
      shoesName = originalName;
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
    Widget buildSlot(String? slotUrl, Map<String, dynamic>? slotProduct, String placeholder, String? itemName, String? itemCategory, String? clothingType, String? otherTags, String? color) {
      return Container(
        width: double.infinity,
        child: Stack(
          children: [
            if (slotUrl != null && slotUrl.isNotEmpty && slotProduct != null)
              GestureDetector(
                onTap: () {
                  debugPrint("Tapped on $placeholder slot: ${slotProduct['name']}");
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailPage(product: slotProduct),
                    ),
                  );
                },
                child: Image.network(
                  slotUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: Center(child: Text("No $placeholder")),
              ),

            Positioned(
              bottom: 8,
              right: 8,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.favorite, color: clothingLikes.containsKey(itemName) ? Colors.pink : Colors.grey),
                    onPressed: () => {
                      setState(() {
                        toggleLike(itemName);
                      })
                  },
                  ),

                  IconButton(
                    icon: Icon(Icons.thumb_down, color: clothingDislikes.containsKey(itemName) ? Colors.red : Colors.grey),
                    onPressed: () => {
                      setState(() {
                      toggleDislike(itemName, itemCategory, context, clothingType, otherTags, color);
                      })
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(topName),
        buildSlot(topUrl, topProduct, "Top", topName, "top", topProduct?['clothing_type'], topProduct?['other_tags'].toString(), topProduct?['color'].toString()),
        SizedBox(height: 8),
        Text(bottomName),
        buildSlot(bottomUrl, bottomProduct, "Bottom", bottomName, "bottoms", bottomProduct?['clothing_type'], bottomProduct?['other_tags'].toString(), bottomProduct?['color'].toString()),
        SizedBox(height: 8),
        Text(shoesName),
        buildSlot(shoesUrl, shoesProduct, "Shoes", shoesName, "shoes", shoesProduct?['clothing_type'], shoesProduct?['other_tags'].toString(), shoesProduct?['color'].toString()),
      ],
    );
  }
}
