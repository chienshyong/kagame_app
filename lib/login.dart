import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService authService = AuthService();
  final TextEditingController _usernameController = TextEditingController(text: '');
  final TextEditingController _passwordController = TextEditingController(text: '');

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final username = _usernameController.text;
    final password = _passwordController.text;
    if (username.isNotEmpty && password.isNotEmpty) {
      try {
        await authService.login(username, password);
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
        scrolledUnderElevation: 0, // fix bug of appbar changing colour when scrolling down the page
        ),

      body: SizedBox(
      height: MediaQuery.of(context).size.height,
      child:
      
      SingleChildScrollView(
        child:
          Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Image.asset(
                'lib/assets/app_icon_transparent.png',
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
                  fontWeight: FontWeight.w300,
                  // fontStyle: FontStyle.italic,
                  )
              ),

              SizedBox(height: 64),

              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Username'),
              ),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              SizedBox(height: 20),

              // Login Button
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
              ),
              
              SizedBox(height: 8),

              // Divider
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
                          context.go('/wardrobe');
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
              
              SizedBox(height: 8),
              
              // Sign in with Apple button - Only show on iOS
              if (Theme.of(context).platform == TargetPlatform.iOS)
              Container(
                alignment: Alignment.center,
                child: 
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (BuildContext context) {
                            return Center(
                              child: CircularProgressIndicator(),
                            );
                          },
                        );
                        
                        final result = await authService.signInWithApple();
                        
                        // Close loading indicator
                        Navigator.of(context).pop();
                        
                        if(result) {
                          context.go('/wardrobe');
                        }
                      } catch (e) {
                        // Close loading indicator if it's shown
                        if (Navigator.canPop(context)) {
                          Navigator.of(context).pop();
                        }
                        
                        print("Error signing in with Apple: $e");
                        
                        String errorMessage = "Apple sign in failed. Please try again.";
                        if (e.toString().contains("not available on this device")) {
                          errorMessage = "Sign in with Apple requires iOS 13 or later.";
                        } else if (e.toString().contains("canceled")) {
                          errorMessage = "Sign in was canceled.";
                        }
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(errorMessage)),
                        );
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.apple,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text('Sign in with Apple'),
                      ],
                    ),
                    
                    style:
                      ElevatedButton.styleFrom(
                        backgroundColor: Colors.black, // Button background color
                        foregroundColor: Colors.white, // Text color
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        )
                      ),
                  ),
              ),

              // Clickable text for new user registration
              TextButton(
                onPressed: () {
                  // Navigate to RegisterPage
                  context.push('/register');
                },
                child: Text(
                  'New user? Register here!',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
              ),

            ],
          ),
        ),
      ),
      ),
    );
  }
}
