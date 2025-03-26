import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);
  
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final AuthService authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    if (username.isNotEmpty && password.isNotEmpty) {
      try {
        await authService.register(username, password).timeout(Duration(seconds: 3), onTimeout: () {
          throw Exception('Register request timed out');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful')),
        );
        // Auto login after registration
        await authService.login(username, password).timeout(Duration(seconds: 3), onTimeout: () {
          throw Exception('Login request timed out');
        });
        context.go('/wardrobe');
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Username and password cannot be empty")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove built-in back button
        scrolledUnderElevation: 0,
        ),

      body: 
      SizedBox(
      height: MediaQuery.of(context).size.height,
      child:
      SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
            children: [
              Image.asset(
                  'lib/assets/app_icon.png',
                  width: 96,
                  height: 96,
                ),

              Text(
                'KagaMe',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                  )
              ),

              Text(
                'Your Personal AI Stylist',
                style: TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  )
              ),

              SizedBox(height: 64),
              
              // Username field
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),

              // Password field
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),

              // Register button
              ElevatedButton(
                onPressed: _register,
                child: Text('Register Account'),
              ),

              SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    child: Text(
                      "or",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),

              // Login with Google button
              Container(
                alignment: Alignment.center,
                child: 
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        if(await authService.signInWithGoogle()){
                          context.go('/profile/quiz');
                        }
                      } catch (e) {
                        print("Error signing in with Google: $e");
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'lib/assets/Google_logo.png',
                          width: 16,
                          height: 16,
                        ),
                        SizedBox(width: 8),
                        Text('Login with Google'),
                      ],
                    ),
                    
                    style:
                      ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Button background color
                        foregroundColor: Colors.black, // Text color
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                          side: BorderSide(color: Colors.grey)
                        )
                      ),
                  ),
              ),

              // Clickable text for back to login
              TextButton(
                onPressed: () {
                  // Navigate to Login Page
                  context.push('/login');
                },
                child: Text(
                  'Back to login page',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),
            ],
          ),
        ),
      ),
      );
  }
}
