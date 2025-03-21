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
  List<String> _tagvalues = []; // List of descriptive tags
  final FocusNode _focusNode = FocusNode(); // Control, monitor, and manage the descriptive tag editor
  final TextEditingController _textEditingController = TextEditingController(); // Manage state of the descriptive tag editor
  bool isLoading = true;
  bool isEditMode = false; // Toggle for edit mode

  String? _selectedValue;
  List<String> _dropdownItems = [];

  late TextEditingController _nameFieldController = TextEditingController();  // Controller for Name TextField
  TextEditingController _promptController = TextEditingController(); // Controller for Prompt TextField

  // Placeholders while API is called
  Map<String, dynamic> jsonResponse = {'image_url': 'https://craftsnippets.com/articles_images/placeholder/placeholder.jpg', 'category': '', 'color': '', 'name': ''};

  @override
  void initState() {
    super.initState();
    fetchItemFromApi();
    _fetchDropdownItems();
  }

  void _toggleEditMode() {
    setState(() {
      isEditMode = !isEditMode;
    });
  }

  // Define the function to handle input changes
  void _onPromptChanged(String value) {
    print("User typed: $value");
  }

  @override
  void dispose() {
    _promptController.dispose(); // Dispose the controller when widget is destroyed
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item does not exist')),
      );
      context.pop();
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

  // Remove a tag
  _onDelete(index) {
    setState(() {
      _tagvalues.removeAt(index);
    });
  }

  // Delete the item
  Future<void> _deleteItem() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    // Send DELETE request
    final response = await http.delete(
      Uri.parse('$baseUrl/wardrobe/item/${jsonResponse["_id"]}'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      }
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item deleted')),
      );
      context.pop();
    }
  }

  // Update the item details
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

      setState(() {
        isEditMode = false;  // Switch back to view mode after saving
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item updated successfully')),
      );
  }

  
  // Separate Widgets for View and Edit Mode
  @override
  Widget build(BuildContext context) {   
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditMode 
            ? 'Edit: ${_nameFieldController.text}' 
            : jsonResponse["name"] ?? "Item Details"
        ),
        actions: [
          IconButton(
            icon: Icon(isEditMode ? Icons.save : Icons.edit),
            onPressed: isEditMode ? _updateItem : _toggleEditMode,
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : isEditMode
              ? _buildEditModeLayout()
              : _buildViewModeLayout(),
    );
  }

  /// View Mode Layout (Read-Only)
  Widget _buildViewModeLayout() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              jsonResponse['image_url']!,
              width: double.infinity,
              fit: BoxFit.cover,
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


            // Recommend Outfit button
            Container(
              alignment: Alignment.center,
              child: 
                ElevatedButton(
                  onPressed: () {
                    context.push('/wardrobe/recommend/${widget.id}');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('StyleMe'),
                      SizedBox(width: 8),
                      Image.asset(
                        'lib/assets/shine.png',
                        width: 16,
                        height: 16,
                      ),
                    ],
                  ),
                  
                  style:
                    ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[100],       // Button background color
                      foregroundColor: Colors.black,      // Text color
                      elevation: 5,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                ),
            ),

            SizedBox(height: 16),
            _infoRow("Category:", jsonResponse["category"] ?? "No Category"),
            SizedBox(height: 10),
            Text("Tags:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 6.0,
              children: _tagvalues.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _toggleEditMode,
                child: Text("Edit Item"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper function for displaying text in view mode
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(width: 8),
          Text(value, style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  // Widget for Edit Mode Layout
  Widget _buildEditModeLayout() {
    return SingleChildScrollView(
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
              
              // Item Name Text Box
              Container(
                margin: EdgeInsets.all(10.0),
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
                          hintText: 'Enter item name',
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
                margin: EdgeInsets.all(8.0),
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
                textStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                
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
              Container(
                margin: EdgeInsets.only(top: 8.0),
                  child:
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Flexible(
                          child:
                            Container(
                              margin: EdgeInsets.only(right: 4.0),
                              child: 
                                ElevatedButton(
                                  onPressed: () {
                                    _deleteItem();
                                  },
                                  child: const Text('Delete Item'),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.red[400],
                                    textStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                        ),

                        Flexible(
                          child:
                            Container(
                              margin: EdgeInsets.only(right: 4.0),
                              child: 
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      // Switch back to view mode
                                      isEditMode = false;
                                      // Revert the name field to its original value from jsonResponse
                                      _nameFieldController.text = jsonResponse["name"];
                                      // Reset the dropdown value to the original category
                                      _selectedValue = jsonResponse["category"];
                                      // Reset the tags list to its original value
                                      _tagvalues = List<String>.from(jsonResponse["tags"]);
                                      // Optionally reset other controllers if necessary
                                      _promptController.text = "";
                                    });
                                  },
                                  child: const Text('Cancel'),
                                  style: ElevatedButton.styleFrom(
                                    textStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ),
                        ),

                        Flexible(
                          child:
                            Container(
                              margin: EdgeInsets.only(right: 4.0),
                              child: 
                                ElevatedButton(
                                  onPressed: () {
                                    _updateItem();
                                  },
                                  child: const Text('Save'),
                                  style: ElevatedButton.styleFrom(
                                    textStyle: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ),
                        ),
                      ],
                    )
              )
            ],
          ),
        ),
      );
    }
  }


// Widget defining individual tags
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