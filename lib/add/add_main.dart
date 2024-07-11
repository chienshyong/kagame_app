import 'package:flutter/material.dart';
import 'camera.dart';
import 'image_editor.dart';

class AddMain extends StatefulWidget {
  AddMain({Key? key}) : super(key: key);

  @override
  State<AddMain> createState() => AddMainState();
}

class AddMainState extends State<AddMain>{
  int _index = 0; //Current page index. Page 0 = camera
  late List<Widget> _pages; //List of pages under scanner tab

  String _imagepath = ''; //Variable to transfer file path from Scanner() to DisplayPicture()

  @override
  void initState() {
    super.initState();
    _pages = [
      Camera(onDataChanged: (imagepath) {
        print("Got data from Camera page");
        setState(() {
          _index = 1;
          _imagepath = imagepath;
          _pages[1] = DisplayPicturePage(imagePath: _imagepath,);
        });
      }),
      Placeholder() //Don't create a DisplayPicturePage without a valid filepath
    ];
  }

  //Reset index when we switch back to "Add" via navigation
  void reset() {
    print('Reset called');
    setState(() {
      _index = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: _index,
      children: _pages,
    );
  }
}