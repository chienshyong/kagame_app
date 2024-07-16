import 'package:flutter/material.dart';
import 'dart:io';

import 'package:go_router/go_router.dart';

class IntoWardrobePage extends StatefulWidget {
  final String imagePath;
  IntoWardrobePage({required this.imagePath});
  
  @override
  State<StatefulWidget> createState() => _IntoWardrobePageState();
}

class _IntoWardrobePageState extends State<IntoWardrobePage>{
  late File imageFile;

  @override
  Widget build(BuildContext context) {
    if (File(widget.imagePath).existsSync()) {
      imageFile = File(widget.imagePath);
    }
    else{
      imageFile = File('');
      print('Invalid image path');
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Center(
              child: widget.imagePath != ''
                ? Image.file(imageFile)
                : Text('Invalid image path'),
            ),
          ),
          Container(
            margin: EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                context.pop();
              },
              child: Text('Add to Wardrobe'),
            ),
          ),
        ],
      ),
    );
  }
}