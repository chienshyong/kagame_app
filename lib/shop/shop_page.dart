import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/search_history_service.dart';
import 'product_detail_page.dart';
import '../widgets/advanced_search_bar.dart';

class ShopPage extends StatefulWidget {
  ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> with SingleTickerProviderStateMixin {
  final AuthService authService = AuthService();
  List<Map<String, dynamic>> products = []; // All products
  List<Map<String, dynamic>> filteredProducts = []; // Products after search filtering
  List<Map<String, dynamic>> recommendedProducts = []; // Recommended products
  List<Map<String, dynamic>> filteredRecommendedProducts = []; // Filtered recommended products
  List<String> recentSearches = []; // Recent searches history

  bool isLoading = true;
  bool isLoadingRecommendations = true;
  bool isSearching = false; // Flag to indicate search in progress
  bool isLoadingBackendSearch = false; // Flag for backend search in progress
  String? selectedGender; // Selected gender filter (M, F, U, or null for all)
  String searchQuery = ''; // Search query string
  Timer? _debounce; // For debouncing search requests
  int _currentTabIndex = 0; // Track current tab index (0=Recommended, 1=All)

  @override
  void initState() {
    super.initState();
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

  // Load user gender and initialize
  Future<void> _loadUserGenderAndInitialize() async {
    try {
      final String baseUrl = authService.baseUrl;
      final token = await authService.getToken();
      
      final response = await http.get(
        Uri.parse('$baseUrl/user/gender'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String? genderCode = data['gender_code']; // Will be 'M', 'F', or null
        
        setState(() {
          selectedGender = genderCode;
        });
      }
      
      // Fetch products and recommendations with the gender filter
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

  // Handle search text submission with debounce
  void _onSearch(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 800), () {
      setState(() {
        isSearching = true;
        searchQuery = query.trim();
      });

      if (query.trim().isNotEmpty) {
        // Save search to history
        SearchHistoryService.saveSearch(query)
            .then((_) => _loadRecentSearches());
        
        // Do frontend filtering for immediate feedback
        _filterProducts();
        
        // Only trigger backend search for All Products tab and non-empty queries
        if (_currentTabIndex == 1 && query.trim().isNotEmpty) {
          _fetchBackendSearchResults(query);
        } else {
          // Just finish the search for recommended tab
          setState(() {
            isSearching = false;
          });
        }
      } else {
        // If query is empty, revert to regular products
        setState(() {
          filteredProducts = List.from(products);
          filteredRecommendedProducts = List.from(recommendedProducts);
          isSearching = false;
        });
      }
    });
  }

  // Clear current search
  void _onClearSearch() {
    setState(() {
      searchQuery = '';
      filteredProducts = List.from(products);
      filteredRecommendedProducts = List.from(recommendedProducts);
      isSearching = false;
      isLoadingBackendSearch = false;
    });
  }

  // Frontend filtering (used for both tabs, but primarily for Recommended tab)
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

  // Fetch backend search results (only for All Products tab)
  Future<void> _fetchBackendSearchResults(String query) async {
    setState(() {
      isLoadingBackendSearch = true;
    });

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    
    // Build URI with query and optional gender filter
    Uri uri;
    if (selectedGender != null) {
      uri = Uri.parse('$baseUrl/shop/text-search?query=${Uri.encodeComponent(query)}&gender=$selectedGender');
    } else {
      uri = Uri.parse('$baseUrl/shop/text-search?query=${Uri.encodeComponent(query)}');
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
          // Transform the search results into the expected format
          List<Map<String, dynamic>> searchResults = data.map((item) {
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
          
          // Update filtered products with backend results
          filteredProducts = searchResults;
          
          isLoadingBackendSearch = false;
          isSearching = false;
        });
      } else {
        setState(() {
          isLoadingBackendSearch = false;
          isSearching = false;
        });
        throw Exception('Failed to load search results');
      }
    } catch (error) {
      setState(() {
        isLoadingBackendSearch = false;
        isSearching = false;
      });
      print('Error fetching search results: $error');
    }
  }

  // Fetch regular products
  Future<void> fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    // Build URI with optional gender filter
    Uri uri;
    if (selectedGender != null) {
      uri = Uri.parse('$baseUrl/shop/items?limit=500&gender=$selectedGender');
    } else {
      uri = Uri.parse('$baseUrl/shop/items?limit=500');
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
          filteredProducts = List.from(products);
          
          // Apply any current search filter
          if (searchQuery.isNotEmpty) {
            _filterProducts();
          }
          
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

  // Fetch recommended products
  Future<void> fetchRecommendedProducts() async {
    setState(() {
      isLoadingRecommendations = true;
    });

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    
    // Build URI with optional gender filter
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
          
          // Apply any current search filter
          if (searchQuery.isNotEmpty) {
            _filterProducts();
          }
          
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

  // Handle gender filter change
  void _handleGenderFilterChange(String? gender) {
    setState(() {
      selectedGender = gender;
    });
    fetchProducts(); // Refresh products with the new filter
    fetchRecommendedProducts(); // Also refresh recommended products
  }

  // Build product widgets for the CustomScrollView
  List<Widget> buildProductWidgets(List<Map<String, dynamic>> productList, bool isBackendSearchLoading) {
    List<Widget> widgets = [];
    
    // Empty state
    if (productList.isEmpty && !isBackendSearchLoading) {
      widgets.add(
        SliverToBoxAdapter(
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
        )
      );
      return widgets;
    }

    // Main product grid
    widgets.add(
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
      )
    );
    
    // Loading indicator and skeleton cards for backend search
    if (isBackendSearchLoading) {
      widgets.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text(
                    "Finding more products...",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        )
      );
      
      widgets.add(
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
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(8.0)),
                            color: Colors.grey[300],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 14.0,
                              width: double.infinity,
                              color: Colors.grey[300],
                            ),
                            SizedBox(height: 4.0),
                            Container(
                              height: 14.0,
                              width: 80.0,
                              color: Colors.grey[300],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              childCount: 4, // 4 skeleton loaders
            ),
          ),
        )
      );
    }
    
    return widgets;
  }

  // Refresh functions
  Future<void> _refreshAllProducts() async {
    await fetchProducts();
    if (searchQuery.isNotEmpty && _currentTabIndex == 1) {
      _fetchBackendSearchResults(searchQuery);
    }
  }

  Future<void> _refreshRecommendedProducts() async {
    await fetchRecommendedProducts();
  }

  // Show filter dialog
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
                            onTap: (index) {
                              setState(() {
                                _currentTabIndex = index;
                              });
                            },
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
                                      padding: const EdgeInsets.only(left: 20.0, top: 8.0),
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
                                                ),
                                                if (isSearching)
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 20.0),
                                                    child: SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : SizedBox.shrink(),
                                    ),
                                  ),
                                  
                                  // Product grid (no backend search for recommended tab)
                                  ...buildProductWidgets(filteredRecommendedProducts, false),
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
                                      padding: const EdgeInsets.only(left: 20.0, top: 8.0),
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
                                                  Padding(
                                                    padding: const EdgeInsets.only(right: 20.0),
                                                    child: SizedBox(
                                                      height: 16,
                                                      width: 16,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : SizedBox.shrink(),
                                    ),
                                  ),
                                  
                                  // Product grid with potential backend search loading
                                  ...buildProductWidgets(filteredProducts, isLoadingBackendSearch),
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


// Helper class to embed the TabBar in a sliver header
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