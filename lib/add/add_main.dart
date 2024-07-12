import 'package:flutter/material.dart';
import 'package:kagame_app/add/into_wardrobe.dart';
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

  String _imagePath = ''; //Variable to transfer file path from Scanner() to DisplayPicture()

  @override
  void initState() {
    super.initState();
    _pages = [
      CameraPage(listener: (data) {
        print("Got data from Camera page: $data");
        setState(() {
          _index = 1;
          _imagePath = data;
          _pages[1] = newImageEditorPage(); //Need to create new page to update inside an IndexedStack
        });
      }),
      newImageEditorPage(),
      newIntoWardrobePage(), //Add clothing item to wardrobe
    ];
  }

  ImageEditorPage newImageEditorPage(){
    return ImageEditorPage(imagePath: _imagePath,
            listener: (data) {
              print("Got data from Image Editor page: $data");
              if(data == 'retake'){
                setState(() {
                _index = 0;
                });
              }
              else{ //If not 'retake', data is the new file path
                setState(() {
                  _index = 2;
                  _imagePath = data;
                  _pages[2] = newIntoWardrobePage();
                });
              }
            },);
  }

  IntoWardrobePage newIntoWardrobePage(){
    return IntoWardrobePage(imagePath: _imagePath,);
  }

  //Reset index to camera page when we switch back to "Add" via navigation bar
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