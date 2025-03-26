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

  int _currentQuestionIndex = 0;
  Map<String, int> _styleCount = {}; //track freq of styles

  final List<Map<String, dynamic>> _questions = [
    {
      "question": "Grabbing coffee with a friend, what are you wearing?",
      "options": ["lib/assets/stylequiz/1A.png", "lib/assets/stylequiz/1BHJ.png", "lib/assets/stylequiz/1CGI.png", "lib/assets/stylequiz/1DEF.png"],
      "styles": ["A", "BHJ", "CGI", "DEF"],
      "isImage": true,
    },
    {
      "question": "You’re going out to an event in the evening, what’s your go-to look?",
      "options": ["lib/assets/stylequiz/2AC.png", "lib/assets/stylequiz/2H.png", "lib/assets/stylequiz/2BJ.png", "lib/assets/stylequiz/2GI.png", "lib/assets/stylequiz/2DEF.png"],
      "styles": ["AC", "H", "BJ", "GI", "DEF"],
      "isImage": true,
    },
    {
      "question": "Choose a print or pattern that speaks to you.",
      "options": ["lib/assets/stylequiz/3BJ.png", "lib/assets/stylequiz/3I.png", "lib/assets/stylequiz/3DG.png", "lib/assets/stylequiz/3EF.png", "lib/assets/stylequiz/3H.png", "lib/assets/stylequiz/3AC.png"],
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

  void _nextQuestion(int selectedIndex) {
    List selectedStyles = _questions[_currentQuestionIndex]["styles"][selectedIndex].split("");

    //increment style count
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
      "A": "Casual", "B": "Classic", "C": "Streetwear", "D": "Romantic",
      "E": "Bohemian", "F": "Vintage", "G": "90s", "H": "Glamorous",
      "I": "Edgy", "J": "Preppy"
    };

    return styleMap[mostCommonLetter] ?? "Undefined";
    // print(_styleCount);
    // return _styleCount.toString();
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> question = _questions[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(title: Text("Find Your Style")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(question["question"], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                children: List.generate(question["options"].length, (index) {
                  return ElevatedButton(
                    onPressed: () => _nextQuestion(index),
                    child: Text(question["options"][index]),
                  );
                }),
              ),
          ],
        ),
      ),
    );
  }
}
