import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../services/auth_service.dart';
import 'package:path_provider/path_provider.dart'; // To get temporary directories

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

  Future<void> _removeBackground() async {
    if (imageFile == File('')) return;

    // Call API and remove bg
    setState(() {
      _isUploading = true;
    });
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/image/remove-bg'),
    );
    request.files
        .add(await http.MultipartFile.fromPath('file', widget.imagePath));
    request.headers['Authorization'] = 'Bearer $token';

    final response = await request.send();
    if (response.statusCode == 200) {
      final imageBytes = await response.stream.toBytes();
      final directory = await getTemporaryDirectory();
      File tempImageFile = File('${directory.path}/modified_image.png');
      // Increment the filename until a non-existing file is found
      int counter = 1;
      while (await tempImageFile.exists()) {
        tempImageFile = File('${directory.path}/modified_image${counter}.png');
        counter++;
      }
      await tempImageFile.writeAsBytes(imageBytes);
      setState(() {
        imageFile = tempImageFile; // Update the imageFile with the new modified file
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Remove background failed with status code: ${response.statusCode}')),
      );
    }

    setState(() {
      _isUploading = false;
    });
  }

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
    request.files
        .add(await http.MultipartFile.fromPath('file', imageFile.path));
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
      context.push(
          '/add/into_wardrobe/${Uri.encodeComponent(imageFile.path)}',
          extra: jsonResponse);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Image upload failed with status code: ${response.statusCode}')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    if (File(widget.imagePath).existsSync()) {
      imageFile = File(widget.imagePath);
    } else {
      imageFile = File('');
      print('Invalid image path ${widget.imagePath}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Center(
                child: // Display the picked image or the modified image
                  imageFile.path.isEmpty
                      ? Text('No image selected.')
                      : Image.file(imageFile) // Show the original or modified image
              ),
            ),
            Container(
              margin: EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: _removeBackground,
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
      ]),
    );
  }
}
