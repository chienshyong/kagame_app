import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'KagaMe',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.wb_sunny, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      '26°C',
                      style: TextStyle(
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text(
                      'Changi South Avenue, Singapore\nThu, 28th Feb',
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'My Collections',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCollectionItem('Summer day out'),
                  _buildCollectionItem('Graduation'),
                  _buildCollectionItem('Vacation'),
                  // Add more collections here
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Recommended Outfits',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildOutfitItem(),
                  _buildOutfitItem(),
                  _buildOutfitItem(),
                  _buildOutfitItem(),
                  _buildOutfitItem(),
                  // Add more outfits here
                ],
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Top Picks for You',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildTopPickItem(),
            // Add more top picks here
          ],
        ),
      ),
    );
  }

  Widget _buildCollectionItem(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            color: Colors.grey.shade300,
          ),
          SizedBox(height: 8),
          Text(title),
        ],
      ),
    );
  }

  Widget _buildOutfitItem() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 100,
        height: 150,
        color: Colors.grey.shade300,
      ),
    );
  }

  Widget _buildTopPickItem() {
    return Container(
      height: 150,
      color: Colors.grey.shade300,
    );
  }
}
