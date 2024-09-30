import 'package:flutter/material.dart';

class ItemPage extends StatefulWidget {
  final String id;
  ItemPage({required this.id});
  
  @override
  State<StatefulWidget> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  String _title = "Sample Title"; // Initial title

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Big image
              Image.network(
                'https://dummyimage.com/300x400&text=cool stuff',
                width: double.infinity,
                fit: BoxFit.cover, // Adjusts the image fit
              ),
              SizedBox(height: 16.0), // Space between image and title

              // Editable title field
              TextField(
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _title = value; // Update title as user types
                  });
                },
                controller: TextEditingController(text: _title), // Pre-fill with initial title
              ),
              SizedBox(height: 16.0), // Space between title and description

              // Description
              Text(
                'Description:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.0),
              Text(
                'This is the description of the item. You can customize this text and add more information here as needed.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 32.0), // Space between description and buttons

              // Buttons at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle edit action
                    },
                    child: Text('Build Outfit'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle save action
                    },
                    child: Text('Discover'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      // Handle edit action
                    },
                    child: Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}