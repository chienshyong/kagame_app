// lib/widgets/wardrobe_visualization_widget.dart
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart'; // Keep for potential fallback or other uses
// Import StylePaginationHeader if it's in its own file
// import 'style_pagination_header.dart';
import '../shop/product_detail_page.dart'; // Or wherever StylePaginationHeader is defined

class WardrobeVisualizationWidget extends StatefulWidget {
  final Map<String, dynamic>? visualizationData;
  final bool isLoading;
  // AuthService might not be strictly needed anymore if backend provides all URLs
  final AuthService authService;

  const WardrobeVisualizationWidget({
    Key? key,
    required this.visualizationData,
    required this.isLoading,
    required this.authService,
  }) : super(key: key);

  @override
  _WardrobeVisualizationWidgetState createState() =>
      _WardrobeVisualizationWidgetState();
}

class _WardrobeVisualizationWidgetState
    extends State<WardrobeVisualizationWidget> {
  int _currentStyleIndex = 0;

  void _nextStyle() {
    if (widget.visualizationData == null) return;
    final styles = widget.visualizationData!['matching_styles'] as List<dynamic>? ?? [];
    if (_currentStyleIndex < styles.length - 1) {
      setState(() => _currentStyleIndex++);
    }
  }

  void _previousStyle() {
    if (_currentStyleIndex > 0) {
      setState(() => _currentStyleIndex--);
    }
  }

  // REMOVED: _getWardrobeItemImageUrl as backend now provides the full URL

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildLoadingSkeleton();
    }

    if (widget.visualizationData == null) {
      return _buildErrorView('Failed to load visualization data.');
    }

    final shopItemData = widget.visualizationData!['shop_item'] as Map<String, dynamic>?;
    final matchingStyles = widget.visualizationData!['matching_styles'] as List<dynamic>? ?? [];

    if (shopItemData == null) {
       return _buildErrorView('Shop item data is missing.');
    }
    // Check if *any* style has *any* matching items
    bool hasAnyMatches = matchingStyles.any((style) {
        final styleOutfits = style['style_outfits'] as List<dynamic>? ?? [];
        return styleOutfits.any((outfit) => (outfit['matching_wardrobe_items'] as List<dynamic>? ?? []).isNotEmpty);
    });

     if (matchingStyles.isEmpty || !hasAnyMatches) {
      return _buildNoMatchesView(); // Show if no styles or no items in any style
    }


    // Ensure index is valid
    if (_currentStyleIndex >= matchingStyles.length) {
      _currentStyleIndex = 0;
    }

    final currentStyleData = matchingStyles[_currentStyleIndex];
    final styleName = currentStyleData['style_name']?.toString() ?? 'Style';
    final styleOutfits = currentStyleData['style_outfits'] as List<dynamic>? ?? [];

    // Consolidate Wardrobe Items
    final Map<String, Map<String, dynamic>> uniqueWardrobeItems = {};
    for (var outfit in styleOutfits) {
      final items = outfit['matching_wardrobe_items'] as List<dynamic>? ?? [];
      for (var item in items) {
         final itemId = item['id']?.toString();
         if (itemId != null && !uniqueWardrobeItems.containsKey(itemId)) {
           uniqueWardrobeItems[itemId] = item;
         }
      }
    }
    final List<Map<String, dynamic>> consolidatedWardrobeItems = uniqueWardrobeItems.values.toList();

    // Categorize Items
    List<dynamic> tops = [];
    List<dynamic> bottoms = [];
    List<dynamic> dresses = [];
    List<dynamic> shoes = [];
    List<dynamic> outerwear = [];
    List<dynamic> accessories = [];
    final shopItemId = shopItemData['id']?.toString() ?? '';

    void categorizeItem(Map<String, dynamic> item, bool isShopItem) {
      final category = item['category']?.toLowerCase() ?? '';
       item['_is_shop_item'] = isShopItem; // Keep flag for highlighting
       switch (category) {
         case 'tops': tops.add(item);
         case 'bottoms': bottoms.add(item);
         case 'dresses': dresses.add(item);
         case 'shoes': shoes.add(item);
         case 'outerwear': case 'jackets': outerwear.add(item);
         case 'accessories': accessories.add(item);
       }
     }
     categorizeItem(shopItemData, true);
     for (final item in consolidatedWardrobeItems) {
       categorizeItem(item, false);
     }

    // Build Carousel Config
     List<Map<String, dynamic>> carouselConfigs = [];
     if (tops.isNotEmpty) carouselConfigs.add({'category': 'Tops', 'items': tops});
     if (bottoms.isNotEmpty) carouselConfigs.add({'category': 'Bottoms', 'items': bottoms});
     if (dresses.isNotEmpty) carouselConfigs.add({'category': 'Dresses', 'items': dresses});
     if (outerwear.isNotEmpty) carouselConfigs.add({'category': 'Outerwear', 'items': outerwear});
     if (shoes.isNotEmpty) carouselConfigs.add({'category': 'Shoes', 'items': shoes});
     if (accessories.isNotEmpty) carouselConfigs.add({'category': 'Accessories', 'items': accessories});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StylePaginationHeader(
          title: styleName,
          currentIndex: _currentStyleIndex,
          totalStyles: matchingStyles.length,
          onPrevious: _previousStyle,
          onNext: _nextStyle,
          isLoading: false,
        ),
        Divider(height: 1),
        SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              if (carouselConfigs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No compatible items found in your wardrobe for this style.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              else
                 ...carouselConfigs.map((config) {
                    return _buildCategoryCarousel(
                      config['category'],
                      config['items'] as List<dynamic>,
                      shopItemId, // Pass shop item ID for highlighting
                    );
                 }).toList(),
               SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets for Loading, Error, Empty States (Keep as is) ---
  Widget _buildLoadingSkeleton() { /* ... Keep skeleton ... */
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding( /* Skeleton Header */
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: 150, height: 24, color: Colors.white)),
            Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: 80, height: 24, color: Colors.white)),
          ]),
        ),
         Divider(height: 1), SizedBox(height: 12),
         Expanded( // Make skeleton scrollable if it overflows
           child: ListView(
             children: [
               _buildCarouselSkeleton('Category 1'), SizedBox(height: 16),
               _buildCarouselSkeleton('Category 2'),
             ],
           ),
         ),
      ],
    );
  }
  Widget _buildCarouselSkeleton(String title) { /* ... Keep skeleton ... */
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(bottom: 8.0), child: Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: 100, height: 20, color: Colors.white))),
        SizedBox(height: 190, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: 3, itemBuilder: (context, index) => _buildItemSkeleton())),
      ]);
  }
  Widget _buildItemSkeleton() { /* ... Keep skeleton ... */
     return Container(width: 130, margin: EdgeInsets.only(right: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(height: 130, width: double.infinity, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4)))),
        SizedBox(height: 6), Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: 100, height: 14, color: Colors.white)),
        SizedBox(height: 4), Shimmer.fromColors(baseColor: Colors.grey[300]!, highlightColor: Colors.grey[100]!, child: Container(width: 60, height: 12, color: Colors.white)),
     ]));
  }
  Widget _buildErrorView(String message) { /* ... Keep error view ... */
      return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text(message, style: TextStyle(color: Colors.red))));
  }
  Widget _buildNoMatchesView() { /* ... Keep no matches view ... */
     return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.checkroom, size: 64, color: Colors.grey[400]), SizedBox(height: 16),
        Text('No matching outfits found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500), textAlign: TextAlign.center), SizedBox(height: 8),
        Text('Try adding more items to your wardrobe that complement this style.', style: TextStyle(color: Colors.grey[600]), textAlign: TextAlign.center),
     ]));
  }


  // --- Category Carousel Builder ---
  Widget _buildCategoryCarousel(
      String categoryTitle, List<dynamic> items, String shopItemId) {
    if (items.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding( /* Category Title */
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
          child: Text(categoryTitle, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black.withOpacity(0.75))),
        ),
        SizedBox(
          height: 190, // Carousel row height
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final itemId = item['id']?.toString() ?? '';
              final itemName = item['name']?.toString() ?? 'Unnamed Item';
              final itemCategory = item['category']?.toString() ?? '';
              final bool isShopItem = item['_is_shop_item'] ?? false;

              // *** USE THE PROVIDED IMAGE URL ***
              final String imageUrl = item['image_url']?.toString() ?? ''; // Get URL from backend data

              return Container( /* Item Card */
                width: 130, margin: EdgeInsets.only(right: 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container( /* Image Container */
                      height: 130, width: double.infinity,
                      decoration: BoxDecoration(
                        border: isShopItem ? Border.all(color: Theme.of(context).primaryColor.withOpacity(0.8), width: 2.5) : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ClipRRect(borderRadius: BorderRadius.circular(isShopItem ? 2 : 4),
                        child: imageUrl.isNotEmpty
                          ? Image.network(imageUrl, fit: BoxFit.cover, /* Error/Loading Builders */
                              errorBuilder: (ctx, e, st) => Container(color: Colors.grey[200], child: Icon(Icons.broken_image, color: Colors.grey[400])),
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(child: CircularProgressIndicator(strokeWidth: 2.0, value: loadingProgress.expectedTotalBytes != null ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes! : null));
                              },
                            )
                          : Container(color: Colors.grey[200], child: Icon(Icons.image_not_supported, color: Colors.grey[400])),
                      ),
                    ),
                    Padding( /* Item Name */
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(itemName, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text(itemCategory, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: Colors.grey[600])), /* Item Category */
                  ],
                ),
              );
            },
          ),
        ),
        SizedBox(height: 16), // Space after carousel
      ],
    );
  }
}