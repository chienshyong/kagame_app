import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WardrobePage extends StatelessWidget {
  WardrobePage({Key? key}) : super(key: key);

  final List<Map<String, String>> images = [
    {'url': 'https://dummyimage.com/600x400&text=shirts', 'label': 'Shirts'},
    {'url': 'https://dummyimage.com/400x600&text=shorts', 'label': 'Shorts'},
    {'url': 'https://dummyimage.com/400x400&text=pants', 'label': 'Pants'},
    {'url': 'https://dummyimage.com/400x500&text=dresses', 'label': 'Dresses'},
    // Add more dynamically as needed
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Wardrobe')
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Logo and Search bar
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    // Navigate to the home page when the logo is tapped
                    context.go('/home');
                  },
                  child: Image.asset(
                    'lib/assets/KagaMe.png',
                    width: 120.0,
                    height: 60.0,
                  ),
                ),
                SizedBox(
                    width: 16.0), // Space between the image and the search bar
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
                        hintText: 'Search Wardrobe',
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

            //Images
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 columns
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                  ),
                  itemCount: images.length, // Dynamic item count
                  itemBuilder: (context, index) {
                    return GestureDetector(
                        onTap: () {
                          // Navigate to Navigator page on tap
                          context.push(
                              '/wardrobe/category/${images[index]['label']!}');
                        },
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: AspectRatio(
                                aspectRatio: 1, // Forces the image to be square
                                child: Image.network(
                                  images[index]['url']!,
                                  fit: BoxFit
                                      .cover, // Ensures the image covers the entire square
                                ),
                              ),
                            ),
                            SizedBox(
                                height: 8.0), // Space between image and text
                            Text(
                              images[index]['label']!,
                              style: TextStyle(
                                  fontSize: 16.0, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ));
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
