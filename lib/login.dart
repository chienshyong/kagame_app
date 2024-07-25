import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'services/auth_service.dart';
 
class LoginPage extends StatelessWidget {
  LoginPage({Key? key}) : super(key: key);

  final AuthService authService = AuthService();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

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
                if(_usernameController.text == ""){ //Dev entry: TODO remove
                  context.go('/wardrobe');
                }
                else{
                  try {
                    await authService.login(
                      _usernameController.text,
                      _passwordController.text,
                    ).timeout(Duration(seconds: 3), onTimeout: () {
                      throw Exception('Login request timed out');
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Login successful')),
                    );
                    context.go('/wardrobe');
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text('Login'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                await authService.register(
                    _usernameController.text,
                    _passwordController.text,
                  ).timeout(Duration(seconds: 3), onTimeout: () {
                    throw Exception('Register request timed out');
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Registration successful')),
                  );
                  await authService.login( //Login automatically after register
                      _usernameController.text,
                      _passwordController.text,
                    ).timeout(Duration(seconds: 3), onTimeout: () {
                      throw Exception('Login request timed out');
                    });
                  context.go('/wardrobe');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
