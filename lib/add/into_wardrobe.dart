import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:material_tag_editor/tag_editor.dart';

import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class IntoWardrobePage extends StatefulWidget {
  final String imagePath;
  final Map<String, dynamic> jsonResponse;
  IntoWardrobePage({required this.imagePath, required this.jsonResponse});
  
  @override
  State<StatefulWidget> createState() => _IntoWardrobePageState();
}

class _IntoWardrobePageState extends State<IntoWardrobePage>{
  final AuthService authService = AuthService();
  List<String> _tagvalues = []; //List of descriptive tags
  final FocusNode _focusNode = FocusNode(); //Control, monitor, and manage the descriptive tag editor
  final TextEditingController _textEditingController = TextEditingController(); //Manage state of the descriptive tag editor

  late File imageFile;
  String? _selectedValue;
  List<String> _dropdownItems = [];

  late TextEditingController _nameFieldController;  // Controller for Name TextField

  @override
  void initState() {
    super.initState();
    _tagvalues = List<String>.from(widget.jsonResponse["tags"]); // Set initial value
    _fetchDropdownItems();
    _nameFieldController = TextEditingController(text: widget.jsonResponse["name"]);
  }

  Future<void> _fetchDropdownItems() async {
    final String baseUrl = authService.baseUrl;
    final response = await http.get(Uri.parse('$baseUrl/wardrobe/available_categories'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _dropdownItems = List<String>.from(data);
      });
    } else {
      // Handle error
      throw Exception('Failed to load dropdown items');
    }
  }

  //Remove a tag
  _onDelete(index) {
    setState(() {
      _tagvalues.removeAt(index);
    });
  }

  //Update the item details
  Future<void> _updateItem() async {
    String textFieldValue = _nameFieldController.text;
    String? dropdownValue = _selectedValue;
    List<String> tags = _tagvalues;

    if (dropdownValue == null) {
      dropdownValue = widget.jsonResponse["category"];
    }

    print('TextField Value: $textFieldValue');
    print('Dropdown Value: $dropdownValue');
    print('Tags: $tags');

    // Create JSON object
    Map<String, dynamic> data = {
      "name": textFieldValue,
      "category": dropdownValue,
      "tags": tags,
    };

    // Convert data to JSON
    String jsonData = jsonEncode(data);

    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    // Send PATCH request with JSON
    final response = await http.patch(
      Uri.parse('$baseUrl/wardrobe/item/${widget.jsonResponse["id"]}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonData,
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Update item failed with status code: ${response.statusCode}')),
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
      print('Invalid image path');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(''),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: <Widget>[
              Container(
                height: 200,
                child: Center(
                  child: widget.imagePath != ''
                    ? Image.file(imageFile)
                    : Text('Invalid image path'),
                ),
              ),
              Container(
                margin: EdgeInsets.all(16.0),
                child: TextField(
                  controller: _nameFieldController,
                  decoration: InputDecoration(
                    hintText: 'Name',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.all(16.0),
                child: DropdownButton<String>(
                  value: _selectedValue,
                  hint: Text(widget.jsonResponse["category"]),
                  items: _dropdownItems
                      .map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedValue = newValue;
                    });
                  },
                ),
              ),
              TagEditor(
                length: _tagvalues.length,
                controller: _textEditingController,
                focusNode: _focusNode,
                delimiters: [',', ' '],
                hasAddButton: true,
                resetTextOnSubmitted: true,
                // This is set to grey just to illustrate the `textStyle` prop
                textStyle: const TextStyle(color: Colors.grey),
                onSubmitted: (outstandingValue) {
                  setState(() {
                    _tagvalues.add(outstandingValue);
                  });
                },
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    _tagvalues.add(newValue);
                  });
                },
                tagBuilder: (context, index) => _Chip(
                  index: index,
                  label: _tagvalues[index],
                  onDeleted: _onDelete,
                ),
                // InputFormatters example, this disallow \ and /
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[/\\]'))
                ],
              ),
              const Divider(),
              ElevatedButton(
                onPressed: _updateItem,
                child: const Text('Confirm tags'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//Widget defining individual tags
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.onDeleted,
    required this.index,
  });

  final String label;
  final ValueChanged<int> onDeleted;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Chip(
      labelPadding: const EdgeInsets.only(left: 8.0),
      label: Text(label),
      deleteIcon: const Icon(
        Icons.close,
        size: 18,
      ),
      onDeleted: () {
        onDeleted(index);
      },
    );
  }
}