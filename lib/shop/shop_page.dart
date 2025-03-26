import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/search_history_service.dart';
import 'product_detail_page.dart';

// Import the AdvancedSearchBar from wherever you placed it
import '../widgets/advanced_search_bar.dart';

class ShopPage extends StatefulWidget {
  ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage>
    with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();
  List<Map<String, dynamic>> products = []; // All products
  List<Map<String, dynamic>> filteredProducts =
      []; // Products after search filtering
  List<Map<String, dynamic>> recommendedProducts = []; // Recommended products
  List<Map<String, dynamic>> filteredRecommendedProducts =
      []; // Filtered recommended products
  List<String> recentSearches = []; // Recent searches history

  bool isLoading = true;
  bool isLoadingRecommendations = true;
  bool isSearching = false; // Flag to indicate search in progress
  String? selectedGender; // Selected gender filter (M, F, U, or null for all)
  String searchQuery = ''; // Search query string
  Timer? _debounce; // For debouncing search requests

  @override
  void initState() {
    super.initState();
    // Fetch products and recommendations
    fetchRecommendedProducts();
    fetchProducts();
      // Load user profile first to get gender for default filter
  _loadUserGenderAndInitialize();

    // Load recent searches
    _loadRecentSearches();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
// New method to fetch user gender and set default gender filter
Future<void> _loadUserGenderAndInitialize() async {
  try {
    // Get auth token from existing service
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    
    // Fetch user gender directly
    final response = await http.get(
      Uri.parse('$baseUrl/user/gender'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final String? genderCode = data['gender_code']; // Will be 'M', 'F', or null
      
      // Set gender filter based on response
      setState(() {
        selectedGender = genderCode;
      });
    }
    
    // Now fetch products and recommendations with the gender filter
    fetchRecommendedProducts();
    fetchProducts();
  } catch (error) {
    print('Error loading user gender: $error');
    // If there's an error, still load products without gender filter
    fetchRecommendedProducts();
    fetchProducts();
  }
}
  // Load recent searches from storage
  Future<void> _loadRecentSearches() async {
    final searches = await SearchHistoryService.getRecentSearches();
    setState(() {
      recentSearches = searches;
    });
  }

  // Handle search text submission
  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 200), () {
      setState(() {
        isSearching = true;
        searchQuery = query.trim();
      });

      if (query.trim().isNotEmpty) {
        // Save search to history
        SearchHistoryService.saveSearch(query)
            .then((_) => _loadRecentSearches());
      }

      _filterProducts();

      // Simulate search delay for UI feedback
      Future.delayed(Duration(milliseconds: 50), () {
        setState(() {
          isSearching = false;
        });
      });
    });
  }

  // Clear current search
  void _onClearSearch() {
    setState(() {
      searchQuery = '';
      _filterProducts();
    });
  }

  // Filter products based on search query
  void _filterProducts() {
    if (searchQuery.isEmpty) {
      setState(() {
        filteredProducts = List.from(products);
        filteredRecommendedProducts = List.from(recommendedProducts);
      });
    } else {
      final String query = searchQuery.toLowerCase();

      setState(() {
        // Filter all products
        filteredProducts = products.where((product) {
          // Check all relevant fields for the search query
          return product['label'].toString().toLowerCase().contains(query) ||
              product['category'].toString().toLowerCase().contains(query) ||
              product['clothing_type']
                  .toString()
                  .toLowerCase()
                  .contains(query) ||
              product['color'].toString().toLowerCase().contains(query) ||
              product['material'].toString().toLowerCase().contains(query) ||
              (product['other_tags'] != null &&
                  product['other_tags']
                      .toString()
                      .toLowerCase()
                      .contains(query));
        }).toList();

        // Also filter recommended products with the same criteria
        filteredRecommendedProducts = recommendedProducts.where((product) {
          return product['label'].toString().toLowerCase().contains(query) ||
              product['category'].toString().toLowerCase().contains(query) ||
              product['clothing_type']
                  .toString()
                  .toLowerCase()
                  .contains(query) ||
              product['color'].toString().toLowerCase().contains(query) ||
              product['material'].toString().toLowerCase().contains(query) ||
              (product['other_tags'] != null &&
                  product['other_tags']
                      .toString()
                      .toLowerCase()
                      .contains(query));
        }).toList();
      });
    }
  }

  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    // Build URI with optional gender filter
    Uri uri;
    if (selectedGender != null) {
      uri = Uri.parse('$baseUrl/shop/items?limit=100&gender=$selectedGender');
    } else {
      uri = Uri.parse('$baseUrl/shop/items?limit=100');
    }

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
              'gender': item['gender']?.toString() ?? 'U',
            };
          }).toList();
          _filterProducts(); // Apply any current search filter
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching products: $error');
    }
  }
Future<void> fetchRecommendedProducts() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    
    // Build URI with optional gender filter, similar to fetchProducts
    Uri uri;
    if (selectedGender != null) {
      uri = Uri.parse('$baseUrl/shop/recommendations-fast?gender=$selectedGender');
    } else {
      uri = Uri.parse('$baseUrl/shop/recommendations-fast');
    }

    try {
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        final List<dynamic> data = responseData['recommendations'];
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
              'gender': item['gender']?.toString() ?? 'U',
            };
          }).toList();
          filteredRecommendedProducts = List.from(recommendedProducts);
          isLoadingRecommendations = false;
        });
      } else {
        throw Exception('Failed to load recommended products');
      }
    } catch (error) {
      setState(() {
        isLoadingRecommendations = false;
      });
      print('Error fetching recommended products: $error');
    }
  }

  // Function to handle gender filter selection
  void _handleGenderFilterChange(String? gender) {
    setState(() {
      selectedGender = gender;
    });
    fetchProducts(); // Refresh products with the new filter
    fetchRecommendedProducts(); // Also refresh recommended products with the new filter
  }

  Widget buildProductGrid(List<Map<String, dynamic>> productList) {
    if (productList.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "No products found",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700]),
                ),
                SizedBox(height: 8),
                Text(
                  "Try adjusting your search or filters",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

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
                    builder: (context) =>
                        ProductDetailPage(productId: product['id']),
                  ),
                );
              },
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Hero(
                        tag: 'product-${product['id']}',
                        child: Container(
                          width: double.infinity,
                          child: ClipRRect(
                            borderRadius: BorderRadius.vertical(
                                top: Radius.circular(8.0)),
                            child: Image.network(
                              product['url']!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                      child: Icon(Icons.broken_image,
                                          size: 40, color: Colors.grey)),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['label']!,
                            style: TextStyle(
                                fontSize: 14.0, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            product['price']!,
                            style: TextStyle(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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

  // Show filter dialog when filter icon is tapped
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filter by Gender'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('All'),
                leading: Radio<String?>(
                  value: null,
                  groupValue: selectedGender,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _handleGenderFilterChange(value);
                  },
                ),
              ),
              ListTile(
                title: Text('Men'),
                leading: Radio<String?>(
                  value: 'M',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _handleGenderFilterChange(value);
                  },
                ),
              ),
              ListTile(
                title: Text('Women'),
                leading: Radio<String?>(
                  value: 'F',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _handleGenderFilterChange(value);
                  },
                ),
              ),
              ListTile(
                title: Text('Unisex'),
                leading: Radio<String?>(
                  value: 'U',
                  groupValue: selectedGender,
                  onChanged: (value) {
                    Navigator.pop(context);
                    _handleGenderFilterChange(value);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // Get current filter status text
  String get _filterStatusText {
    switch (selectedGender) {
      case 'M':
        return 'Men';
      case 'F':
        return 'Women';
      case 'U':
        return 'Unisex';
      default:
        return 'All';
    }
  }

  // Remove a search from history
  void _removeSearchFromHistory(String query) {
    SearchHistoryService.removeSearch(query).then((_) => _loadRecentSearches());
  }

  // Clear all search history
  void _clearSearchHistory() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Search History'),
          content:
              Text('Are you sure you want to clear all your recent searches?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Clear'),
              onPressed: () {
                Navigator.of(context).pop();
                SearchHistoryService.clearSearches()
                    .then((_) => _loadRecentSearches());
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController searchController = TextEditingController();

    return Scaffold(
      body: SafeArea(
        child: (isLoading && isLoadingRecommendations)
            ? Center(child: CircularProgressIndicator())
            : DefaultTabController(
                length: 2,
                child: NestedScrollView(
                  headerSliverBuilder:
                      (BuildContext context, bool innerBoxIsScrolled) {
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
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              children: [
                                GestureDetector(
                                  child: Image.asset(
                                    'lib/assets/KagaMe.png',
                                    width: 120.0,
                                    height: 60.0,
                                  ),
                                ),
                                SizedBox(width: 12.0),
                                Expanded(
                                  child: AdvancedSearchBar(
                                    onSearch: _onSearch,
                                    onClear: _onClearSearch,
                                    onFilterTap: _showFilterDialog,
                                    filterText: _filterStatusText,
                                    hintText:
                                        'Find clothes, shoes, accessories...',
                                    isSearching: isSearching,
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
                            indicatorColor: Theme.of(context).primaryColor,
                            labelColor: Colors.black,
                            unselectedLabelColor: Colors.grey,
                            indicatorWeight: 3.0,
                            labelStyle: TextStyle(fontWeight: FontWeight.bold),
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
                                  // Show result count or searching indicator
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left:20.0),
                                      child: searchQuery.isNotEmpty
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Found ${filteredRecommendedProducts.length} results",
                                                  style: TextStyle(
                                                    fontSize: 12.0,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),                                              ],
                                            )
                                          : SizedBox.shrink(),
                                    ),
                                  ),
                                  buildProductGrid(filteredRecommendedProducts),
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
                                  // Show product count or empty state
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 20.0),
                                      child: searchQuery.isNotEmpty
                                          ? Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  "Found ${filteredProducts.length} results",
                                                  style: TextStyle(
                                                    fontSize: 14.0,
                                                    color: Colors.grey.shade600,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                if (isSearching)
                                                  SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                              strokeWidth: 2)),
                                              ],
                                            )
                                          : SizedBox.shrink(),
                                    ),
                                  ),
                                  buildProductGrid(filteredProducts),
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
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
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
