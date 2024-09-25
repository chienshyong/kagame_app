import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/auth_service.dart';

class ImageEditorPage extends StatefulWidget {
  final String imagePath;
  ImageEditorPage({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<ImageEditorPage> createState() => _ImageEditorPageState();
}

class _ImageEditorPageState extends State<ImageEditorPage> {
  final AuthService authService = AuthService();
  late File imageFile;
  bool _isUploading = false;

  // Future<void> _removeBackground() async {
  //   if (imageFile == File('')) return;
  //   // final bytes = await _imageFile!.readAsBytes();
  //   // TODO: Call API and remove bg
  // }

  Future<void> _uploadImage() async {
    setState(() {
      _isUploading = true;
    });
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/wardrobe/item'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', widget.imagePath));
    request.headers['Authorization'] = 'Bearer $token';
    
    final response = await request.send();
    setState(() {
      _isUploading = false;
    });
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload successful')),
      );
      final responseData = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseData);
      context.push('/add/into_wardrobe/${Uri.encodeComponent(widget.imagePath)}', extra: jsonResponse);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed with status code: ${response.statusCode}')),
      );
    }
  }

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
      body: Stack(
        children: [Column(
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
            OverflowBar(
              alignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: context.pop,
                  child: Text('Retake'),
                ),
                ElevatedButton(
                  onPressed: _uploadImage,
                  child: Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.2),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ]
      ),
    );
  }
}