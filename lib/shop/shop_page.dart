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

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();
  List<Map<String, dynamic>> products = []; // All products
  List<Map<String, dynamic>> recommendedProducts = []; // Recommended products
  bool isLoading = true;
  bool isLoadingRecommendations = true;
  int selectedTab = 0; // 0 = Recommended, 1 = All Products

  @override
  void initState() {
    super.initState();
    fetchRecommendedProducts(); // Load recommended first
    fetchProducts(); // Load all products second
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
      print('Response body: ${response.body.substring(0, 500)}...');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          products = data.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
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

  Future<void> fetchRecommendedProducts() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final Uri uri = Uri.parse('$baseUrl/shop/recommendations');

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print('Recommendations Response status: ${response.statusCode}');
      print('Recommendations Response body: ${response.body.substring(0, 500)}...');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          recommendedProducts = data.map((item) {
            return {
              'id': item['id']?.toString() ?? '',
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
          isLoadingRecommendations = false;
        });

        print('Recommended products loaded successfully: ${recommendedProducts.length} items.');
      } else {
        print('Failed to load recommended products: ${response.body}');
        throw Exception('Failed to load recommended products');
      }
    } catch (error) {
      print('Error fetching recommended products: $error');
      setState(() {
        isLoadingRecommendations = false;
      });
    }
  }

  Widget buildProductGrid(List<Map<String, dynamic>> productList) {
    return SliverPadding(
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
            final product = productList[index];
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailPage(product: product),
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
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.0),
                  Text(
                    product['label']!,
                    style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4.0),
                  Text(
                    product['price']!,
                    style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          },
          childCount: productList.length,
        ),
      ),
    );
  }

  Future<void> _refreshAllProducts() async {
    await fetchProducts();
  }

  Future<void> _refreshRecommendedProducts() async {
    await fetchRecommendedProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: isLoading && isLoadingRecommendations
            ? Center(child: CircularProgressIndicator())
            : DefaultTabController(
          length: 2,
          child: NestedScrollView(
            headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  pinned: true,
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
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 1.0,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search Products',
                                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.filter_list, color: Colors.grey),
                                    onPressed: () {
                                      print('Filter icon tapped');
                                    },
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 12.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: Column(
              children: [
                Container(
                  color: Colors.grey[200],
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedTab = 0;
                          });
                        },
                        child: Text(
                          "Recommended",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: selectedTab == 0 ? FontWeight.bold : FontWeight.normal,
                            color: selectedTab == 0 ? Colors.blue : Colors.black,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedTab = 1;
                          });
                        },
                        child: Text(
                          "All Products",
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: selectedTab == 1 ? FontWeight.bold : FontWeight.normal,
                            color: selectedTab == 1 ? Colors.blue : Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: selectedTab == 0
                      ? (isLoadingRecommendations
                      ? Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                    onRefresh: _refreshRecommendedProducts,
                    child: CustomScrollView(
                      slivers: [
                        buildProductGrid(recommendedProducts),
                      ],
                    ),
                  ))
                      : (isLoading
                      ? Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                    onRefresh: _refreshAllProducts,
                    child: CustomScrollView(
                      slivers: [
                        buildProductGrid(products),
                      ],
                    ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
