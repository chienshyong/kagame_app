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

  late TextEditingController _nameFieldController = TextEditingController();  // Controller for Name TextField
  TextEditingController _promptController = TextEditingController(); // Controller for Prompt TextField

  //Placeholders while API is called
  Map<String, dynamic> jsonResponse = {'image_url': 'https://craftsnippets.com/articles_images/placeholder/placeholder.jpg', 'category': '', 'color': '', 'name': ''};

  @override
  void initState() {
    super.initState();
    fetchItemFromApi();
    _fetchDropdownItems();
  }

  // 2️⃣ Define the function to handle input changes
  void _onPromptChanged(String value) {
    print("User typed: $value");
  }

  @override
  void dispose() {
    _promptController.dispose(); // 3️⃣ Dispose the controller when widget is destroyed
    super.dispose();
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
          _tagvalues = List<String>.from(jsonResponse["tags"]); // Set initial value
          _nameFieldController.text = jsonResponse["name"];
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

  //Update the item details
  Future<void> _updateItem() async {
    String textFieldValue = _nameFieldController.text;
    String? dropdownValue = _selectedValue;
    List<String> tags = _tagvalues;

    if (dropdownValue == null) {
      dropdownValue = jsonResponse["category"];
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
      Uri.parse('$baseUrl/wardrobe/item/${jsonResponse["_id"]}'),
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
                child: Row(
                  children: [
                    Text(
                      "Item Name:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10), // Spacing between text and TextField
                    Expanded( // Ensures TextField takes up remaining space
                      child: TextField(
                        controller: _nameFieldController,
                        decoration: InputDecoration(
                          hintText: 'Enter your name',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.all(16.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min, // Ensures Row takes minimal space
                  children: [
                    Text(
                      "Category:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10), // Space between label and dropdown
                    DropdownButton<String>(
                      value: _selectedValue,
                      hint: Text(jsonResponse["category"]),
                      items: _dropdownItems.map((String value) {
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
                  ],
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

              // Prompt TextInput
              Container(
                margin: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Label Text "Prompt:"
                    Text(
                      "Prompt (optional):",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10), // Space between label and input field

                    // TextField for user input
                    Expanded( // Allows input field to take available space
                      child: TextField(
                        controller: _promptController, // TextEditingController to store input
                        onChanged: _onPromptChanged, // Call function when text changes
                        decoration: InputDecoration(
                          hintText: "e.g. date night", // Placeholder text
                          hintStyle: TextStyle(color: Colors.grey), // Gray hint text
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),



              // Buttons at the bottom
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _updateItem();
                    },
                    child: const Text('Save Changes'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      context.push('/wardrobe/recommend/${widget.id}');
                    },
                    child: Text('Recommend Outfit'),
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