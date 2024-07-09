import 'package:flutter/material.dart';
import 'dart:io';

class DisplayPicturePage extends StatelessWidget {
  final String imagePath;

  DisplayPicturePage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.file(File(imagePath)),
      ),
    );
  }
}