import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';

class MultiImagePickerPage extends StatefulWidget {
  @override
  _MultiImagePickerPageState createState() => _MultiImagePickerPageState();
}

class _MultiImagePickerPageState extends State<MultiImagePickerPage> {
  List<File> _images = [];
  final AuthService authService = AuthService();
  bool _isLoading = false;
  double _uploadProgress = 0.0;
  int _currentUploadIndex = 0;

  Future<void> _pickImages() async {
    final ImagePicker _picker = ImagePicker();
    final List<XFile>? pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles != null) {
      setState(() {
        _images = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  Future<void> _confirmSelection() async {
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No images selected')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadProgress = 0.0;
      _currentUploadIndex = 0;
    });

    try {
      for (int i = 0; i < _images.length; i++) {
        setState(() {
          _currentUploadIndex = i + 1;
        });
        await _uploadImageToWardrobe(_images[i]);
        setState(() {
          _uploadProgress = (i + 1) / _images.length;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Images uploaded successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload images: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  Future<void> _uploadImageToWardrobe(File image) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/wardrobe/item'),
    );
    request.files.add(await http.MultipartFile.fromPath('file', image.path));
    request.headers['Authorization'] = 'Bearer $token';

    await request.send();
  }

    @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add to your Wardrobe'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Text(
              'Upload photos of your clothing to your wardrobe. Our virtual assistant will label and sort them automatically!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4.0,
                mainAxisSpacing: 4.0,
              ),
              itemCount: _images.length,
              itemBuilder: (context, index) {
                return Image.file(
                  _images[index],
                  fit: BoxFit.cover,
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Uploading... ($_currentUploadIndex/${_images.length})'),
                  LinearProgressIndicator(value: _uploadProgress),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _pickImages,
                  child: Text('Pick Images'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _confirmSelection,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Confirm'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}