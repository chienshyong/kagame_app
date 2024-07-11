import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image/image.dart' as img;

class DisplayPicturePage extends StatefulWidget {
  final String imagePath;
  DisplayPicturePage({required this.imagePath});

  @override
  State<DisplayPicturePage> createState() => _DisplayPicturePageState();
}

class _DisplayPicturePageState extends State<DisplayPicturePage> {
  File? _imageFile;

  Future<void> _removeBackground() async {
    if (_imageFile == null) return;

    final bytes = await _imageFile!.readAsBytes();
    //Call API and remove bg
  }

  @override
  Widget build(BuildContext context) {
      _imageFile = File(widget.imagePath);
      _removeBackground();

    return Scaffold(
      body: Center(
        child: Image.file(File(widget.imagePath)),
      ),
    );
  }
}