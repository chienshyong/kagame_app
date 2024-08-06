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
  List<String> _values = [];
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();

  _onDelete(index) {
    setState(() {
      _values.removeAt(index);
    });
  }

  late File imageFile;
  String? _selectedValue;
  List<String> _dropdownItems = [];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _values = List<String>.from(widget.jsonResponse["description"]); // Set initial value
    _fetchDropdownItems();
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

  @override
  Widget build(BuildContext context) {
    TextEditingController _colorController = TextEditingController(text: widget.jsonResponse["color"][0]);
    
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
                  decoration: InputDecoration(
                    hintText: 'Name (Optional)',
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
                  hint: Text(widget.jsonResponse["category"][0]),
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
              Container(
                margin: EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Color',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  controller: _colorController,
                ),
              ),
              TagEditor(
                length: _values.length,
                controller: _textEditingController,
                focusNode: _focusNode,
                delimiters: [',', ' '],
                hasAddButton: true,
                resetTextOnSubmitted: true,
                // This is set to grey just to illustrate the `textStyle` prop
                textStyle: const TextStyle(color: Colors.grey),
                onSubmitted: (outstandingValue) {
                  setState(() {
                    _values.add(outstandingValue);
                  });
                },
                inputDecoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Add tags...',
                ),
                onTagChanged: (newValue) {
                  setState(() {
                    _values.add(newValue);
                  });
                },
                tagBuilder: (context, index) => _Chip(
                  index: index,
                  label: _values[index],
                  onDeleted: _onDelete,
                ),
                // InputFormatters example, this disallow \ and /
                inputFormatters: [
                  FilteringTextInputFormatter.deny(RegExp(r'[/\\]'))
                ],
              ),
              const Divider(),
              ElevatedButton(
                onPressed: context.pop,
                child: const Text('Add to Wardrobe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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