import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';

import '../services/auth_service.dart';
import 'stylequiz.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware {
  final AuthService authService = AuthService();

  // Controllers for text fields
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _clothingPrefsController = TextEditingController();
  final TextEditingController _clothingDislikesController = TextEditingController();

  // FocusNodes
  final FocusNode _ageFocusNode = FocusNode();
  final FocusNode _genderFocusNode = FocusNode();
  final FocusNode _raceFocusNode = FocusNode();
  final FocusNode _birthdayFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _clothingPrefsFocusNode = FocusNode();
  final FocusNode _clothingDislikesFocusNode = FocusNode();

  // List to store countries
  List<String> countries = [];

  // Other state variables
  String _styleResult = "Not determined yet";
  bool _isEditing = false;

  // Gender dropdown vars
  List<String> _genderDropdownList = <String>["Prefer not to say", "Female", "Male"];
  String _genderSelected = "Prefer not to say";

  @override
  void initState() {
    super.initState();
    getProfileData();
    loadCountriesFile();
  }

  @override
  void dispose() {
    // Dispose controllers & focus nodes
    _ageController.dispose();
    _genderController.dispose();
    _birthdayController.dispose();
    _locationController.dispose();
    _clothingPrefsController.dispose();
    _clothingDislikesController.dispose();

    _ageFocusNode.dispose();
    _genderFocusNode.dispose();
    _raceFocusNode.dispose();
    _birthdayFocusNode.dispose();
    _locationFocusNode.dispose();
    _clothingPrefsFocusNode.dispose();
    _clothingDislikesFocusNode.dispose();

    super.dispose();
  }

  // Retrieve profile data from backend
  Future<void> getProfileData() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/retrieve'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          _genderSelected = jsonResponse["gender"] ?? "Prefer not to say";
          _birthdayController.text = jsonResponse["birthday"] ?? "";
          _locationController.text = jsonResponse["location"] ?? "";
          _styleResult = jsonResponse["style"];
        });
      }
    } catch (error) {
      print('Error fetching profile: $error');
    }
  }

  // Post updates for profile data
  Future<void> updateProfileData() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    Map<String, dynamic> updatedProfile = {
      "gender": _genderSelected,
      "birthday": _birthdayController.text,
      "location": _locationController.text,
    };

    String jsonData = jsonEncode(updatedProfile);

    final response = await http.post(
      Uri.parse('$baseUrl/profile/update'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonData,
    );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      final message = responseJson["detail"];
      print(responseJson["detail"]);
      throw Exception(message);
    }
  }

  // Load countries into searchable dropdown
  Future<void> loadCountriesFile() async {
    try {
      String fileContent = await rootBundle.loadString('lib/assets/countries.txt');
      List<String> countriesList = fileContent.split('\n');
      setState(() {
        countries = countriesList;
      });
    } catch (e) {
      debugPrint("Error loading file: $e");
    }
  }

  // Birthdate formatting
  final birthdayFormatter = TextInputFormatter.withFunction(
        (oldValue, newValue) {
      String text = newValue.text;
      int selectionIndex = newValue.selection.end;

      text = text.replaceAll('/', '');

      if (text.length > 2) {
        text = text.substring(0, 2) + '/' + text.substring(2);
        if (selectionIndex >= 2) selectionIndex++;
      }
      if (text.length > 5) {
        text = text.substring(0, 5) + '/' + text.substring(5);
        if (selectionIndex >= 5) selectionIndex++;
      }

      if (text.length > 10) {
        text = text.substring(0, 10);
      }

      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: selectionIndex),
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.cancel),
              onPressed: () {
                getProfileData();
                setState(() {
                  _isEditing = false;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                if (_validateBirthday(_birthdayController.text)) {
                  updateProfileData().then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Profile Updated.")),
                    );
                    setState(() {
                      _isEditing = false;
                    });
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid birthday date.")),
                  );
                }
              },
            ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await authService.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String?>(
                future: authService.getUsername(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return Text('No user found.');
                  } else {
                    return Text(
                      'Hello, ${snapshot.data}!',
                      style: TextStyle(fontSize: 30.0, color: Colors.black),
                    );
                  }
                },
              ),
              Text(
                "You can tell us as much as you want, but the more we know about you, the better recommendations we can make :)",
                style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
              ),
              SizedBox(height: 24),

              DropdownButtonFormField<String>(
                value: _genderSelected,
                decoration: InputDecoration(
                  labelText: "Gender",
                  border: OutlineInputBorder(),
                ),
                icon: const Icon(Icons.arrow_downward),
                style: const TextStyle(color: Colors.black),
                onChanged: _isEditing
                    ? (String? value) {
                  setState(() {
                    _genderSelected = value!;
                  });
                }
                    : null,
                items: _genderDropdownList.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              _buildTextField(
                label: 'Birthday (DD/MM/YYYY)',
                controller: _birthdayController,
                focusNode: _birthdayFocusNode,
                nextFocusNode: _locationFocusNode,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  birthdayFormatter,
                ],
                keyboardType: TextInputType.number,
                readOnly: !_isEditing,
              ),
              SizedBox(height: 16),

              _buildLocationDropdown(
                label: 'Location',
                controller: _locationController,
                focusNode: _locationFocusNode,
                enabled: _isEditing,
              ),
              SizedBox(height: 16),

              Text(
                "My style is: $_styleResult",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QuizPage()),
                    );
                    setState(() {
                      getProfileData();
                    });
                  },
                  child: Text('Find my style'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // Read only
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      readOnly: readOnly,
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode);
        } else {
          focusNode.unfocus();
        }
      },
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
    );
  }

  // Validate if the birthday matches DD/MM/YYYY
  bool _validateBirthday(String birthday) {
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(birthday)) {
      return false;
    }

    final parts = birthday.split('/');
    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);

    try {
      DateTime parsedDate = DateTime(year, month, day);
      if (parsedDate.day != day || parsedDate.month != month || parsedDate.year != year) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  // Location dropdown UI
  Widget _buildLocationDropdown({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool enabled,
  }) {
    return DropdownSearch<String>(
      items: countries,
      selectedItem: controller.text.isNotEmpty ? controller.text : null,
      onChanged: enabled
          ? (value) {
        controller.text = value ?? '';
      }
          : null,
      popupProps: PopupProps.menu(
        showSearchBox: true,
        searchFieldProps: TextFieldProps(
          decoration: InputDecoration(
            labelText: "Search Country",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
      dropdownBuilder: (context, selectedItem) => Text(
        selectedItem ?? '',
        style: TextStyle(fontWeight: FontWeight.normal),
      ),
      enabled: enabled,
    );
  }
}
