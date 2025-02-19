import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';

import 'stylequiz.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with RouteAware{
  Future<void> getProfileData() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    try{
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
          _birthdayController.text = jsonResponse['birthday'] ?? "";
          _locationController.text = jsonResponse['location'] ?? "";
          _heightController.text = jsonResponse['height'] ?? "";
          _weightController.text = jsonResponse['weight'] ?? "";
          _raceController.text = jsonResponse['ethnicity'] ?? "";
          _skinToneController.text = jsonResponse['skin_tone'] ?? "";
        });
      }
    }
    catch (error){
      print('Error fetching profile: $error');
    }
  }


  Future<void> updateProfileData() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    Map<String, dynamic> updatedProfile = {
      "gender": _genderSelected,
      "birthday": _birthdayController.text,
      "location": _locationController.text,
      "height": _heightController.text.toString(),
      "weight": _weightController.text.toString(),
      "ethnicity": _raceController.text,
      "skin_tone": _skinToneController.text,
      "style": _styleResult,
      "happiness_current_wardrobe": _happinessLevel.toInt().toString()
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

  String _styleResult = "Not determined yet";
  double _happinessLevel = 1;
  List<String> _genderDropdownList = <String>["Prefer not to say", "Female", "Male"];
  String _genderSelected = "Prefer not to say";

  List<Color> _skinToneColors = [
    const Color(0xFFf6ede4),
    const Color(0xFFf3e7db),
    const Color(0xFFf7ead0),
    const Color(0xFFeadaba),
    const Color(0xFFd7bd96),
    const Color(0xFFa07e56),
    const Color(0xFF825c43),
    const Color(0xFF604134),
    const Color(0xFF3a312a),
    const Color(0xFF292420),
  ];

  Map<Color, String> _skinToneDescription = {
    Color(0xFFf6ede4):"Very fair skin with cool, pink undertones",
    Color(0xFFf3e7db):"Fair skin with neutral to cool undertones",
    Color(0xFFf7ead0):"Light skin with neutral undertones",
    Color(0xFFeadaba):"Light to medium skin with warm or golden undertones",
    Color(0xFFd7bd96):"Medium skin with neutral to warm undertones",
    Color(0xFFa07e56):"Medium to olive skin with warm or golden undertones",
    Color(0xFF825c43):"Olive to light brown skin with golden or neutral undertones",
    Color(0xFF604134):"Medium brown skin with neutral to warm undertones",
    Color(0xFF3a312a):"Dark brown skin with rich, warm undertones",
    Color(0xFF292420):"Deep skin with cool or neutral undertones"
  };

  final AuthService authService = AuthService();

  // Controllers for text fields
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _raceController = TextEditingController();
  final TextEditingController _birthdayController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _skinToneController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // FocusNodes to manage the focus of each text field
  final FocusNode _genderFocusNode = FocusNode();
  final FocusNode _raceFocusNode = FocusNode();
  final FocusNode _birthdayFocusNode = FocusNode();
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _heightFocusNode = FocusNode();
  final FocusNode _weightFocusNode = FocusNode();
  final FocusNode _skinToneFocusNode = FocusNode();
  final FocusNode _bioFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    getProfileData();
  }

  @override
  void dispose() {
    // Dispose the controllers and FocusNodes to free up resources
    _genderController.dispose();
    _raceController.dispose();
    _birthdayController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _skinToneController.dispose();
    _bioController.dispose();

    _genderFocusNode.dispose();
    _raceFocusNode.dispose();
    _birthdayFocusNode.dispose();
    _locationFocusNode.dispose();
    _heightFocusNode.dispose();
    _weightFocusNode.dispose();
    _skinToneFocusNode.dispose();
    _bioFocusNode.dispose();

    super.dispose();
  }

  // Formatter to enforce DD/MM/YYYY format
  final birthdayFormatter = TextInputFormatter.withFunction(
        (oldValue, newValue) {
      String text = newValue.text;

      // Store the old cursor position before adding slashes
      int selectionIndex = newValue.selection.end;

      // Remove all existing '/' to prevent double slashes
      text = text.replaceAll('/', '');

      // Automatically insert slashes at the appropriate places
      if (text.length > 2) {
        text = text.substring(0, 2) + '/' + text.substring(2);
        if (selectionIndex >= 2) selectionIndex += 1;
      }
      if (text.length > 5) {
        text = text.substring(0, 5) + '/' + text.substring(5);
        if (selectionIndex >= 5) selectionIndex += 1;
      }

      // Limit to 10 characters (DD/MM/YYYY)
      if (text.length > 10) {
        text = text.substring(0, 10);
      }

      // Return new formatted value
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
                    return Text('Hello, ${snapshot.data}!',
                        style: TextStyle(
                          fontSize: 30.0,
                          color: Colors.black,
                        )
                    );
                  }
                },
              ),
              Text(
                "You can tell us as much as you want, but the more we know about you, the better recommendations we can make :)",
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 24),

              // Gender field
              // _buildTextField(
              //   label: 'Gender',
              //   controller: _genderController,
              //   focusNode: _genderFocusNode,
              //   nextFocusNode: _birthdayFocusNode,
              // ),
              Text("Gender"),
              DropdownButton<String>(
                value: _genderSelected,
                icon: const Icon(Icons.arrow_downward),
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                underline: Container(height: 2, color: Colors.deepPurpleAccent),
                onChanged: (String? value) {
                setState(() {
                _genderSelected = value!;
                });
                },
                items: _genderDropdownList.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(value: value, child: Text(value));
                }).toList(),
                ),
              SizedBox(height: 16),

              // Birthday field
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
              ),
              SizedBox(height: 16),

              // Location field
              _buildTextField(
                label: 'Location',
                controller: _locationController,
                focusNode: _locationFocusNode,
                nextFocusNode: _heightFocusNode,
              ),
              SizedBox(height: 16),

              // Height field
              _buildTextField(
                label: 'Height (cm)',
                controller: _heightController,
                focusNode: _heightFocusNode,
                nextFocusNode: _weightFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16),

              // Weight field
              _buildTextField(
                label: 'Weight (kg)',
                controller: _weightController,
                focusNode: _weightFocusNode,
                nextFocusNode: _raceFocusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              SizedBox(height: 16),

              // Ethnicity field
              _buildTextField(
                label: 'Ethnicity',
                controller: _raceController,
                focusNode: _raceFocusNode,
                nextFocusNode: _skinToneFocusNode,
              ),
              SizedBox(height: 16),

              // Skin Tone field
              Text("Pick the closest skin tone to yours:"),
              SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children: _skinToneColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _skinToneController.text = '${_skinToneDescription[color]}';
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: _skinToneController.text ==
                              '#${color.value.toRadixString(16).substring(2).toUpperCase()}'
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),
              _buildTextField(
                label: 'Skin Tone',
                controller: _skinToneController,
                focusNode: _skinToneFocusNode,
                nextFocusNode: _bioFocusNode,
              ),
              SizedBox(height: 16),

              // Style Quiz
              Text(
                "My style is: $_styleResult",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Center(
                child: ElevatedButton(
                  onPressed: () async {
                    String? result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => QuizPage()),
                    );
                    if (result != null && result.isNotEmpty) {
                      setState(() {
                        _styleResult = result;
                      });
                    }
                  },
                  child: Text('Find my style'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Happiness Slider
              Text(
                "How happy are you with your current wardrobe?",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 8),
              Center(
                child: SfSlider(
                  min: 1,
                  max: 10,
                  value: _happinessLevel,
                  interval: 1,
                  showTicks: true,
                  showLabels: true,
                  enableTooltip: true,
                  minorTicksPerInterval: 0,
                  stepSize: 1,
                  onChanged: (dynamic value) {
                    setState(() {
                      _happinessLevel = value;
                    });
                  },
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Your rating: ${_happinessLevel.toInt()}",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 24),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Handle submission logic here
                    updateProfileData();
                    if (_validateBirthday(_birthdayController.text)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Profile Updated.")),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Invalid birthday date.")),
                      );
                    }
                  },
                  child: Text('Update Profile'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build text fields with focus transition
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    FocusNode? nextFocusNode,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLines: maxLines,
      textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
      onSubmitted: (_) {
        if (nextFocusNode != null) {
          FocusScope.of(context).requestFocus(nextFocusNode); // Move to next field
        } else {
          focusNode.unfocus(); // Hide keyboard if no next focus node
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
    // Check if the birthday follows the DD/MM/YYYY format
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(birthday)) {
      return false;
    }

    // Split the birthday string into day, month, and year
    final parts = birthday.split('/');
    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);

    try {
      // Create a DateTime object, this will throw an error if the date is invalid
      DateTime parsedDate = DateTime(year, month, day);

      // Ensure the parsed date components match the input (to catch out-of-range dates)
      if (parsedDate.day != day || parsedDate.month != month || parsedDate.year != year) {
        return false;
      }

      return true; // Date is valid
    } catch (e) {
      return false; // Invalid date, such as 30/02/2021
    }
  }
}