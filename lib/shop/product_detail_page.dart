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
  List<Map<String, dynamic>> similarProducts = [];
  bool isLoadingSimilar = true;

  @override
  void initState() {
    super.initState();
    fetchSimilarProducts();
  }

  Future<void> fetchSimilarProducts() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final productId = widget.product['id'];
    final Uri uri = Uri.parse('$baseUrl/shop/similar_items?id=$productId&n=5'); // Updated endpoint

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
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

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final imageUrl = product['url'];
    final name = product['label'];
    final price = product['price'];
    final brandName = product['brand'] ?? 'Brand Name';
    final tags = product['tags'] ?? []; // Ensure tags is a list

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              imageUrl,
              width: double.infinity,
              height: 300,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
            ),
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
                                            similarProduct['url'],
                                            width: 150,
                                            height: 150,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
