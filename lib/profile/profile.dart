import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/auth_service.dart';
import 'stylequiz.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final AuthService authService = AuthService();

  // Controllers
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

  // Country list
  List<String> countries = [];

  // State variables
  String _styleResult = "Not determined yet";
  bool _isEditing = false;

  // Gender dropdown
  List<String> _genderDropdownList = <String>["Prefer not to say", "Female", "Male"];
  String _genderSelected = "Prefer not to say";

  // Clothing likes and dislikes
  Map<String, dynamic> _clothingLikesDict = {};
  Map<String, dynamic> _clothingDislikesDict = {};
  Map<String, dynamic> _likesImages = {};
  Map<String, dynamic> _dislikesImages = {};

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

  // Fetch profile data
  Future<void> getProfileData() async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profile/retrieve'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          _genderSelected = jsonResponse["gender"] ?? "Prefer not to say";
          _birthdayController.text = jsonResponse["birthday"] ?? "";
          _locationController.text = jsonResponse["location"] ?? "";
          _styleResult = jsonResponse["style"];
          _clothingLikesDict = jsonResponse["clothing_likes"];
          _clothingDislikesDict = jsonResponse["clothing_dislikes"];
        });
        await getLikesImageURLs(prefsDict: _clothingLikesDict);
        await getDislikesImageURLs(prefsDict: _clothingDislikesDict);
      }
    } catch (error) {
      print('Error fetching profile: $error');
    }
  }

  // Update profile data
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

  // Load countries into the dropdown
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

  // Get likes/dislikes image urls
  Future<void> getLikesImageURLs({
    required Map<String, dynamic> prefsDict
  }) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    try {
      String jsonData = jsonEncode(prefsDict);
      final response = await http.get(
        Uri.parse('$baseUrl/profile/getprefsurls?prefs_dict=$jsonData'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          _likesImages = jsonResponse;
        });
      }
    } catch (error) {
      print('Error fetching likes images: $error');
    }
  }

  Future<void> getDislikesImageURLs({
    required Map<String, dynamic> prefsDict
  }) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    try {
      String jsonData = jsonEncode(prefsDict);
      final response = await http.get(
        Uri.parse('$baseUrl/profile/getprefsurls?prefs_dict=$jsonData'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        setState(() {
          _dislikesImages = jsonResponse;
        });
      }
    } catch (error) {
      print('Error fetching likes images: $error');
    }
  }

  void removeLike (String? itemName) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    Map<String?, bool> removedLike = {itemName: false};
    String jsonData = jsonEncode(removedLike);

    final response = await http.post(
      Uri.parse('$baseUrl/profile/updateclothinglikes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonData,
    );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      debugPrint(responseJson["detail"]);
      throw Exception(responseJson["detail"]);
    }

    setState(() {
      getProfileData();
    });
  }

  void removeDislike (String? itemName) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();

    Map<String?, bool> removedDislike = {itemName: false};
    String jsonData = jsonEncode(removedDislike);

    final response = await http.post(
      Uri.parse('$baseUrl/profile/updateclothingdislikes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonData,
    );

    if (response.statusCode != 200) {
      final responseJson = jsonDecode(response.body);
      debugPrint(responseJson["detail"]);
      throw Exception(responseJson["detail"]);
    }

    setState(() {
      getProfileData();
    });
  }

  // Birthday formatter
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

  // Validate DD/MM/YYYY
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                getProfileData();
                setState(() {
                  _isEditing = false;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () {
                if (_validateBirthday(_birthdayController.text)) {
                  updateProfileData().then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Profile Updated.")),
                    );
                    setState(() {
                      _isEditing = false;
                    });
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Invalid birthday date.")),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.logout),
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
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                    return const Text('No user found.');
                  } else {
                    return Text(
                      'Hello, ${snapshot.data}!',
                      style: const TextStyle(fontSize: 30.0, color: Colors.black),
                    );
                  }
                },
              ),
              Text(
                "You can tell us as much as you want, but the more we know about you, the better recommendations we can make :)",
                style: TextStyle(fontSize: 16.0, color: Colors.grey[700]),
              ),
              const SizedBox(height: 24),

              // VIEW ONLY MODE
              if (!_isEditing) ...[
                Text(
                  "Gender: $_genderSelected",
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16),
                Text(
                  "Birthday: ${_birthdayController.text}",
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16),
                Text(
                  "Location: ${_locationController.text}",
                  style: const TextStyle(fontSize: 16.0),
                ),
                const SizedBox(height: 16),
                Text(
                  "Style: $_styleResult",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Text(
                  "Clothing Likes",
                  style: const TextStyle(fontSize: 16.0),
                ),
                _likesImages.isNotEmpty
                ? Container(
                  height: 290,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _likesImages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: 140,
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 190,
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: _likesImages.values.elementAt(index),
                                    width: 140,
                                    height: 190,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error, color: Colors.red),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        removeLike(_likesImages.keys.elementAt(index));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 140,
                              child: Text(
                                _likesImages.keys.elementAt(index),
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                : Text('No items in likes'),
                const SizedBox(height: 16),
                Text(
                  "Clothing Dislikes",
                  style: const TextStyle(fontSize: 16.0),
                ),
                _dislikesImages.isNotEmpty
                    ? Container(
                  height: 290,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _dislikesImages.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: 140,
                        child: Column(
                          children: [
                            Container(
                              width: 140,
                              height: 190,
                              child: Stack(
                                children: [
                                  CachedNetworkImage(
                                    imageUrl: _dislikesImages.values.elementAt(index),
                                    width: 140,
                                    height: 190,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) =>
                                        Icon(Icons.error, color: Colors.red),
                                  ),
                                  Positioned(
                                    top: 0,
                                    right: 0,
                                    child: IconButton(
                                      icon: Icon(Icons.close, color: Colors.red),
                                      onPressed: () {
                                        removeDislike(_dislikesImages.keys.elementAt(index));
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: 140,
                              child: Text(
                                _dislikesImages.keys.elementAt(index),
                                textAlign: TextAlign.center,
                                softWrap: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                    : Text('No items in dislikes'),
              ]

              // EDIT MODE
              else ...[
                DropdownButtonFormField<String>(
                  value: _genderSelected,
                  decoration: const InputDecoration(
                    labelText: "Gender",
                    border: OutlineInputBorder(),
                  ),
                  icon: const Icon(Icons.arrow_downward),
                  style: const TextStyle(color: Colors.black),
                  onChanged: (String? value) {
                    setState(() {
                      _genderSelected = value!;
                    });
                  },
                  items: _genderDropdownList.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
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
                  readOnly: false,
                ),
                const SizedBox(height: 16),
                _buildLocationDropdown(
                  label: 'Location',
                  controller: _locationController,
                  focusNode: _locationFocusNode,
                  enabled: true,
                ),
                const SizedBox(height: 16),
                Text(
                  "Style: $_styleResult",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await updateProfileData();
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => QuizPage()),
                      );
                      setState(() {
                        getProfileData();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    child: const Text('Find my style'),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // TextField builder
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
        border: const OutlineInputBorder(),
      ),
    );
  }

  // Location dropdown
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
        searchFieldProps: const TextFieldProps(
          decoration: InputDecoration(
            labelText: "Search Country",
            border: OutlineInputBorder(),
          ),
        ),
      ),
      dropdownDecoratorProps: DropDownDecoratorProps(
        dropdownSearchDecoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
      dropdownBuilder: (context, selectedItem) => Text(
        selectedItem ?? '',
        style: const TextStyle(fontWeight: FontWeight.normal),
      ),
      enabled: enabled,
    );
  }
}
