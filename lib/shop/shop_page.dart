import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../services/auth_service.dart';
import 'product_detail_page.dart';

class ShopPage extends StatefulWidget {
  ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  final AuthService authService = AuthService();
  List<Map<String, dynamic>> products = []; // Changed to dynamic
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
  setState(() {
    isLoading = true;
  });

  final String baseUrl = authService.baseUrl;
  final token = await authService.getToken();
  final Uri uri = Uri.parse('$baseUrl/shop/items?limit=100');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    // Optionally, limit the length of the printed body for large responses
    print('Response body: ${response.body.substring(0, 500)}...');

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        products = data.map((item) {
          return {
            'id': item['id']?.toString() ?? '', // Include the 'id' field here
            'url': item['image_url']?.toString() ?? '',
            'label': item['name']?.toString() ?? '',
            'price': item['price']?.toString() ?? '',
            'product_url': item['product_url']?.toString() ?? '',
            // Include any other fields you need
          };
        }).toList();
        isLoading = false;
      });

      print('Products loaded successfully: ${products.length} items.');
    } else {
      print('Failed to load products: ${response.body}');
      throw Exception('Failed to load products');
    }
  } catch (error) {
    print('Error fetching products: $error');
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverAppBar(
                    pinned: false,
                    floating: true,
                    snap: true,
                    expandedHeight: 80.0,
                    flexibleSpace: FlexibleSpaceBar(
                      background: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                context.go('/home');
                              },
                              child: Image.asset(
                                'lib/assets/KagaMe.png',
                                width: 100.0,
                                height: 50.0,
                              ),
                            ),
                            SizedBox(width: 16.0),
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Search Products',
                                    border: InputBorder.none,
                                    prefixIcon:
                                        Icon(Icons.search, color: Colors.grey),
                                    suffixIcon: IconButton(
                                      icon: Icon(Icons.filter_list,
                                          color: Colors.grey),
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
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.all(8.0),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.7,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                          final product = products[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailPage(product: product),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Image.network(
                                      product['url']!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Icon(Icons.error),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 8.0),
                                Text(
                                  product['label']!,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4.0),
                                Text(
                                  product['price']!,
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: products.length,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
