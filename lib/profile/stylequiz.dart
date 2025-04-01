import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/auth_service.dart';
import 'dart:convert';

class QuizPage extends StatefulWidget {
  @override
  _QuizPageState createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  final AuthService authService = AuthService();

  bool? _isMale;
  int _currentQuestionIndex = 0;
  Map<String, int> _styleCount = {}; //track frequency of styles

  final List<Map<String, dynamic>> _maleQuestions = [
    {
      "question": "Grabbing coffee with a friend, what are you wearing?",
      "options": [
        "lib/assets/stylequiz/male/M1A.png",
        "lib/assets/stylequiz/male/M1BHJ.png",
        "lib/assets/stylequiz/male/M1CGI.png",
        "lib/assets/stylequiz/male/M1DEF.png"
      ],
      "styles": ["A", "BHJ", "CGI", "DEF"],
      "isImage": true,
    },
    {
      "question": "You’re going out to an event in the evening, what’s your go-to look?",
      "options": ["lib/assets/stylequiz/male/M2AC.png", "lib/assets/stylequiz/male/M2H.png", "lib/assets/stylequiz/male/M2BJ.png", "lib/assets/stylequiz/male/M2GI.png", "lib/assets/stylequiz/male/M2DEF.png"],
      "styles": ["AC", "H", "BJ", "GI", "DEF"],
      "isImage": true,
    },
    {
      "question": "Given a neutral brown t-shirt, what bottoms would you wear with it?",
      "options": ["lib/assets/stylequiz/male/M3CI.png", "lib/assets/stylequiz/male/M3F.png", "lib/assets/stylequiz/male/M3AG.png", "lib/assets/stylequiz/male/M3BJ.png", "lib/assets/stylequiz/male/M3H.png", "lib/assets/stylequiz/male/M3DE.png"],
      "styles": ["CI", "F", "AG", "BJ", "H", "DE"],
      "isImage": true,
    },
    {
      "question": "To complete the outfit, which shoes would you pick?",
      "options": ["lib/assets/stylequiz/male/M4CI.png", "lib/assets/stylequiz/male/M4F.png", "lib/assets/stylequiz/male/M4AG.png", "lib/assets/stylequiz/male/M4BJ.png", "lib/assets/stylequiz/male/M4H.png", "lib/assets/stylequiz/male/M4DE.png"],
      "styles": ["CI", "F", "AG", "BJ", "H", "DE"],
      "isImage": true,
    },
    {
      "question": "Choose a print or pattern that speaks to you.",
      "options": ["lib/assets/stylequiz/male/M5BJ.png", "lib/assets/stylequiz/male/M5I.png", "lib/assets/stylequiz/male/M5DG.png", "lib/assets/stylequiz/male/M5EF.png", "lib/assets/stylequiz/male/M5H.png", "lib/assets/stylequiz/male/M5AC.png"],
      "styles": ["BJ", "I", "DG", "EF", "H", "AC"],
      "isImage": true,
    },
    {
      "question": "If weather weren’t a concern, what is your ideal outerwear?",
      "options": ["Denim jacket or flannel shirt", "Knit cardigan", "Faux fur coat", "Tailored coat", "Leather biker jacket", "Bomber jacket"],
      "styles": ["G", "DEF", "H", "BJ", "I", "AC"],
      "isImage": false,
    },
    {
      "question": "How do you put together an outfit?",
      "options": ["I coordinate colours and patterns for a polished, structured look.",
        "I add bold accessories, dark colours, or unique details.",
        "I make sure my outfit looks expensive and put-together.",
        "I add playful, bold pieces to stand out.",
        "I love incorporating vintage finds into my look.",
        "I stick to comfy, practical pieces that always work.",
        "I plan every detail to make sure I look polished.",
        "I mix oversized and fitted pieces for contrast.",
        "I focus on soft elements.",
        " I go for layered, flowy, and textured pieces."],
      "styles": ["J", "I", "H", "G","F", "A", "B", "C","D", "E"],
      "isImage": false,
    },
  ];

  final List<Map<String, dynamic>> _femaleQuestions = [
    {
      "question": "Grabbing coffee with a friend, what are you wearing?",
      "options": [
        "lib/assets/stylequiz/female/F1A.png",
        "lib/assets/stylequiz/female/F1BHJ.png",
        "lib/assets/stylequiz/female/F1CGI.png",
        "lib/assets/stylequiz/female/F1DEF.png"
      ],
      "styles": ["A", "BHJ", "CGI", "DEF"],
      "isImage": true,
    },
    {
      "question": "You’re going out to an event in the evening, what’s your go-to look?",
      "options": ["lib/assets/stylequiz/female/F2AC.png", "lib/assets/stylequiz/female/F2H.png", "lib/assets/stylequiz/female/F2BJ.png", "lib/assets/stylequiz/female/F2GI.png", "lib/assets/stylequiz/female/F2DEF.png"],
      "styles": ["AC", "H", "BJ", "GI", "DEF"],
      "isImage": true,
    },
    {
      "question": "Given a neutral brown t-shirt, what bottoms would you wear with it?",
      "options": ["lib/assets/stylequiz/female/F3CI.png", "lib/assets/stylequiz/female/F3F.png", "lib/assets/stylequiz/female/F3AG.png", "lib/assets/stylequiz/female/F3BJ.png", "lib/assets/stylequiz/female/F3H.png", "lib/assets/stylequiz/female/F3DE.png"],
      "styles": ["CI", "F", "AG", "BJ", "H", "DE"],
      "isImage": true,
    },
    {
      "question": "To complete the outfit, which shoes would you pick?",
      "options": ["lib/assets/stylequiz/female/F4CI.png", "lib/assets/stylequiz/female/F4F.png", "lib/assets/stylequiz/female/F4AG.png", "lib/assets/stylequiz/female/F4BJ.png", "lib/assets/stylequiz/female/F4H.png", "lib/assets/stylequiz/female/F4DE.png"],
      "styles": ["CI", "F", "AG", "BJ", "H", "DE"],
      "isImage": true,
    },
    {
      "question": "Choose a print or pattern that speaks to you.",
      "options": ["lib/assets/stylequiz/female/F5BJ.png", "lib/assets/stylequiz/female/F5I.png", "lib/assets/stylequiz/female/F5DG.png", "lib/assets/stylequiz/female/F5EF.png", "lib/assets/stylequiz/female/F5H.png", "lib/assets/stylequiz/female/F5AC.png"],
      "styles": ["BJ", "I", "DG", "EF", "H", "AC"],
      "isImage": true,
    },
    {
      "question": "If weather weren’t a concern, what is your ideal outerwear?",
      "options": ["Denim jacket or flannel shirt", "Knit cardigan", "Faux fur coat", "Tailored coat", "Leather biker jacket", "Bomber jacket"],
      "styles": ["G", "DEF", "H", "BJ", "I", "AC"],
      "isImage": false,
    },
    {
      "question": "How do you put together an outfit?",
      "options": ["I coordinate colours & patterns for a polished look.",
        "I add bold accessories, dark colours, or unique details.",
        "I make sure my outfit looks expensive and put-together.",
        "I add playful, bold pieces to stand out.",
        "I love incorporating vintage finds into my look.",
        "I stick to comfy, practical pieces that always work.",
        "I plan every detail to make sure I look polished.",
        "I mix oversized and fitted pieces for contrast.",
        "I focus on soft elements.",
        " I go for layered, flowy, and textured pieces."],
      "styles": ["J", "I", "H", "G","F", "A", "B", "C","D", "E"],
      "isImage": false,
    },
  ];

  List<Map<String, dynamic>> get _questions {
    if (_isMale == null) return [];
    return _isMale! ? _maleQuestions : _femaleQuestions;
  }

  void _setGender(bool isMale) {
    setState(() {
      _isMale = isMale;
      _currentQuestionIndex = 0;
    });
  }

  void _nextQuestion(int selectedIndex) {
    List selectedStyles = _questions[_currentQuestionIndex]["styles"][selectedIndex].split("");

    for (var style in selectedStyles) {
      _styleCount[style] = (_styleCount[style] ?? 0) + 1;
    }

    setState(() {
      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        _showResults();
      }
    });
  }

  Future<void> postResult(String resultStyle) async {
    final String baseUrl = authService.baseUrl;
    final token = await authService.getToken();
    try {
      Map<String, String> styleQuizResult = {"style_result": resultStyle};
      String jsonData = jsonEncode(styleQuizResult);
      final response = await http.post(
        Uri.parse('$baseUrl/profile/stylequizresult'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonData,
      );
      if (response.statusCode == 200) {
        print('Result posted successfully!');
      } else {
        print('Failed to post result. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error posting result: $e');
    }
  }

  void _showResults() async {
    String resultStyle = _calculateStyle();
    await postResult(resultStyle);
    Navigator.pop(context);
  }

  String _calculateStyle() {
    if (_styleCount.isEmpty) return "Undefined";

    String mostCommonLetter =
        _styleCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    Map<String, String> styleMap = {
      "A": "Casual",
      "B": "Classic",
      "C": "Streetwear",
      "D": "Romantic",
      "E": "Bohemian",
      "F": "Vintage",
      "G": "90s",
      "H": "Glamorous",
      "I": "Edgy",
      "J": "Preppy"
    };

    return styleMap[mostCommonLetter] ?? "Undefined";
  }

  @override
  Widget build(BuildContext context) {
    if (_isMale == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Select Your Gender")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Please select your gender:", style: TextStyle(fontSize: 18)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _setGender(true),
                child: Text("Male"),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _setGender(false),
                child: Text("Female"),
              ),
            ],
          ),
        ),
      );
    }

    Map<String, dynamic> question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Find Your Style")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(question["question"],
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            if (question["isImage"])
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: question["options"].length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _nextQuestion(index),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        question["options"][index],
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  );
                },
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(question["options"].length, (index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: ElevatedButton(
                      onPressed: () => _nextQuestion(index),
                      style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                        minimumSize: Size(double.infinity, 48),
                      ),
                      child: Text(
                        question["options"][index],
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
