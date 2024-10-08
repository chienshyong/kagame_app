import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:material_tag_editor/tag_editor.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class ItemPage extends StatefulWidget {
  final String id;
  ItemPage({required this.id});
  
  @override
  State<StatefulWidget> createState() => _ItemPageState();
}

class _ItemPageState extends State<ItemPage> {
  final AuthService authService = AuthService();
  List<String> _tagvalues = []; //List of descriptive tags
  final FocusNode _focusNode = FocusNode(); //Control, monitor, and manage the descriptive tag editor
  final TextEditingController _textEditingController = TextEditingController(); //Manage state of the descriptive tag editor
  bool isLoading = true;

  String? _selectedValue;
  List<String> _dropdownItems = [];

  //Placeholders while API is called
  Map<String, dynamic> jsonResponse = {'image_url': 'https://craftsnippets.com/articles_images/placeholder/placeholder.jpg', 'category': '', 'color': '', 'name': ''};

  @override
  void initState() {
    super.initState();
    fetchItemFromApi();
    _fetchDropdownItems();
  }

  Future<void> fetchItemFromApi() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    final request = http.MultipartRequest(
      'GET',
      Uri.parse('$baseUrl/wardrobe/item/${widget.id}'),
    );
    request.headers['Authorization'] = 'Bearer $token';

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString(); // Convert response to string
        setState(() {
          jsonResponse = json.decode(responseBody); // Decode JSON data as Map
          _tagvalues = List<String>.from(jsonResponse["description"]); // Set initial value
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load image');
      }
    } catch (error) {
      print('Error fetching image: $error');
      setState(() {
        isLoading = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    TextEditingController _colorController = TextEditingController(text: jsonResponse["color"]);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Item Page'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Image.network(
                jsonResponse['image_url']!,
                width: double.infinity,
                fit: BoxFit.cover, // Adjusts the image fit
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
                  hint: Text(jsonResponse["category"]),
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

              // Buttons at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Handle update
                    },
                    child: const Text('Update Details'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/wardrobe/recommend/${widget.id}');
                    },
                    child: Text('Recommend'),
                  ),
                ],
              )
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