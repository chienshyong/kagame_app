import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WardrobePage extends StatelessWidget {
  const WardrobePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Center(
                    child: Text('This is the Wardrobe Page'),
                  ),
                ),
                // Add other widgets here if necessary
              ],
            ),
            Positioned(
              top: 0,
              left: 12.0,
              right: 12.0,
              child: Row(
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
                  SizedBox(width: 16.0), // Space between the image and the search bar
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
            ),
          ],
        ),
      ),
    );
  }
}
