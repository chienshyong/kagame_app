import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ShopPage extends StatefulWidget {
  ShopPage({Key? key}) : super(key: key);

  @override
  _ShopPageState createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> products = [
    {
      'url': 'https://dummyimage.com/600x400&text=Evil+Twisted+Blocking+Sleeveless',
      'label': 'Evil twisted blocking knitwear',
      'price': 'SGD23.77'
    },
    {
      'url': 'https://dummyimage.com/400x600&text=Cotter+Flower+Dress',
      'label': 'Cotter flower uncut dress',
      'price': 'SGD32.69'
    },
    {
      'url': 'https://dummyimage.com/400x400&text=Tinkerbell+Cardigan',
      'label': 'Tinkerbell cardigan cashmere',
      'price': 'SGD34.70'
    },
    {
      'url': 'https://dummyimage.com/400x500&text=Suin+Frill+Bustier+Dress',
      'label': 'Suin frill bustier sleeveless',
      'price': 'SGD32.69'
    },
    {
      'url': 'https://dummyimage.com/400x500&text=Kathy+Tulip+Mini+Dress',
      'label': 'Kathy tulip mini dress',
      'price': 'SGD34.06'
    },
    {
      'url': 'https://dummyimage.com/400x500&text=Off+Shoulder+Twisted+Knitwear',
      'label': 'Off shoulder twisted knitwear',
      'price': 'SGD54.25'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverAppBar(
              pinned: false, // Not sticky
              floating: true, // Appears when scrolling up
              snap: true, // Snaps into place when scrolling up
              expandedHeight: 80.0, // Reduced height
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          // Navigate to the home page when the logo is tapped
                          context.go('/home');
                        },
                        child: Image.asset(
                          'lib/assets/KagaMe.png',
                          width: 100.0, // Adjust the logo size
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
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Search Products',
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              suffixIcon: IconButton(
                                icon: Icon(Icons.filter_list, color: Colors.grey),
                                onPressed: () {
                                  // Add filter action here
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
                    return GestureDetector(
                      onTap: () {
                        // Navigate to the product detail page on tap
                        context.push('/product/${products[index]['label']}');
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Expanded(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Image.network(
                                products[index]['url']!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(height: 8.0),
                          Text(
                            products[index]['label']!,
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4.0),
                          Text(
                            products[index]['price']!,
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
