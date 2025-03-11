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

  @override
  void initState() {
    super.initState();
    fetchRecommendedProducts();
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
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {
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
      } else {
        throw Exception('Failed to load recommended products');
      }
    } catch (error) {
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
                    builder: (context) => ProductDetailPage(productId: product['id']),
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
        child: (isLoading && isLoadingRecommendations)
            ? Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                    return [
                      // SliverAppBar with logo and search bar
                      SliverAppBar(
                        backgroundColor: Colors.white,
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
                      // Persistent header for the TabBar
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            indicatorColor: Colors.blue,
                            labelColor: Colors.black,
                            tabs: [
                              Tab(text: "Recommended For You"),
                              Tab(text: "All Products"),
                            ],
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      // Recommended For You tab content
                      isLoadingRecommendations
                          ? Center(child: CircularProgressIndicator())
                          : RefreshIndicator(
                              onRefresh: _refreshRecommendedProducts,
                              child: CustomScrollView(
                                slivers: [
                                  buildProductGrid(recommendedProducts),
                                ],
                              ),
                            ),
                      // All Products tab content
                      isLoading
                          ? Center(child: CircularProgressIndicator())
                          : RefreshIndicator(
                              onRefresh: _refreshAllProducts,
                              child: CustomScrollView(
                                slivers: [
                                  buildProductGrid(products),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

// Helper class to embed the TabBar in a sliver header.
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _SliverAppBarDelegate(this.tabBar);
  
  @override
  double get minExtent => tabBar.preferredSize.height;
  
  @override
  double get maxExtent => tabBar.preferredSize.height;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }
  
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}