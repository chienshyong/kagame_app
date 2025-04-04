import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../services/auth_service.dart';
import '../services/event_bus_service.dart';

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
      _checkStyleAnalysis();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Images uploaded successfully!')),
      );

      // Refresh the wardrobe
      eventBus.fire(WardrobeRefreshEvent());

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload images: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _uploadProgress = 0.0;
        _images = [];
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

// This function handles any errors internally
  Future<void> _checkStyleAnalysis() async {
    try {
      final String baseUrl = authService.baseUrl;
      final token = await authService.getToken();

      final response = await http.post(
        Uri.parse('$baseUrl/wardrobe/check-style-analysis'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // If you want to display something or log success:
        debugPrint('Style analysis triggered successfully.');
        // Optionally parse `response.body` if needed
      } else {
        debugPrint(
            'Failed to check style analysis: ${response.statusCode} - ${response.body}');
      }
    } catch (err) {
      debugPrint('Error in _checkStyleAnalysis(): $err');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder:
            (BuildContext context, bool innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Color(0xFFFFF4E9),
              pinned: false,
              floating: true,
              snap: true,
              toolbarHeight: 80.0,
              titleSpacing: 12,
              title: Row(
                children: [
                  GestureDetector(
                    child: Image.asset(
                      'lib/assets/KagaMe.png',
                      width: 120.0,
                      height: 60.0,
                    ),
                  ),
                ],
              ),
            ),
          ];
        },
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0), // Adjust value as needed
              child: Text(
                'Add Clothes',
                style: const TextStyle(fontSize: 30.0, color: Colors.black),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
      )
    );
  }
}