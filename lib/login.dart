import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService authService = AuthService();
  final TextEditingController _usernameController = TextEditingController(text: 'JWardrobe');  // Prefilled username
  final TextEditingController _passwordController = TextEditingController(text: 'JWardrobe');  // Prefilled password

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
            ElevatedButton(
              onPressed: () async {
                final username = _usernameController.text;
                final password = _passwordController.text;

                print(
                    "Username: $username, Password: $password"); // Debug the inputs

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
                    SnackBar(
                        content: Text("Username and password cannot be empty")),
                  );
                }
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await authService
                      .register(
                    _usernameController.text,
                    _passwordController.text,
                  )
                      .timeout(Duration(seconds: 3), onTimeout: () {
                    throw Exception('Register request timed out');
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Registration successful')),
                  );

                  // Auto login after successful registration
                  await authService
                      .login(
                    _usernameController.text,
                    _passwordController.text,
                  )
                      .timeout(Duration(seconds: 3), onTimeout: () {
                    throw Exception('Login request timed out');
                  });

                  await Future.delayed(
                      Duration(milliseconds: 500)); // Optional delay for async
                  context.go('/wardrobe');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('Register'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  UserCredential userCredential = await authService.signInWithGoogle();
                  print("Signed in as ${userCredential.user?.displayName}");
                } catch (e) {
                  print("Error signing in with Google: $e");
                }
              },
              child: Text('Login with Google'),
            ),

          ],
        ),
      ),
    );
  }
}
