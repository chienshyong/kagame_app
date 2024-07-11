import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';

class Camera extends StatefulWidget {
  final Function(String) onDataChanged;
  Camera({required this.onDataChanged});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  Future<void>? _initializeControllerFuture;

  //Camera
  @override
  void initState() {
    super.initState();
    _setupCamera();
  }

  Future<void> _setupCamera() async {
    cameras = await availableCameras();
    _controller = CameraController(
      cameras![0],
      ResolutionPreset.high,
      enableAudio: false,
    );
    
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    try {
      await _initializeControllerFuture;
      _controller!.setFlashMode(FlashMode.off);
      final image = await _controller!.takePicture();
      print('Picture cached to ${image.path}');
      
      widget.onDataChanged(image.path); // Return the img path to parent
    } catch (e) {
      print(e);
    }
  }

  //Choose from files 
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      widget.onDataChanged(pickedFile.path); // Return the img path to parent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _controller == null
          ? Center(child: CircularProgressIndicator())
          : Center(
            child: FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return CameraPreview(_controller!);
                  } else {
                    return Center(child: CircularProgressIndicator());
                  }
                },
              ),
          ),
      floatingActionButton: Stack(
        children: <Widget>[
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: _takePicture,
              child: Icon(Icons.camera_alt),
            ),
          ),
          Positioned(
            bottom: 80,
            right: 16,
            child: FloatingActionButton(
              onPressed: _pickImage,
              child: Icon(Icons.image),
            ),
          ),
        ]
      ),
    );
  }
}
