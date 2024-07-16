import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

class ImageEditorPage extends StatefulWidget {
  final String imagePath;
  ImageEditorPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  late File imageFile;

  // Future<void> _removeBackground() async {
  //   if (imageFile == File('')) return;
  //   // final bytes = await _imageFile!.readAsBytes();
  //   // TODO: Call API and remove bg
  // }

  @override
  Widget build(BuildContext context) {
    if (File(widget.imagePath).existsSync()) {
      imageFile = File(widget.imagePath);
    }
    else{
      imageFile = File('');
      print('Invalid image path ${widget.imagePath}');
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
            child: ElevatedButton(
              onPressed: () {
                //Remove bg
              },
              child: Text('Remove Background'),
            ),
          ),
          ButtonBar(
            alignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  context.pop();
                },
                child: Text('Retake'),
              ),
              ElevatedButton(
                onPressed: () {
                  context.push('/add/into_wardrobe/${Uri.encodeComponent(widget.imagePath)}');
                },
                child: Text('Confirm'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}