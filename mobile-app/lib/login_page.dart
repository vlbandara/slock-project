import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class LoginPage extends StatefulWidget {
  final Function(bool) onLogin;

  LoginPage({required this.onLogin});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _passwordController = TextEditingController();
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  String _currentPassword = "";
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _database.child('newPassword').onValue.listen((event) {
      if (event.snapshot.value != null) {
        setState(() {
          _currentPassword = event.snapshot.value as String;
        });
      }
    });
  }

  void _login() {
    if (_passwordController.text == _currentPassword) {
      widget.onLogin(true);
    } else {
      setState(() {
        _errorMessage = "Incorrect password. Please try again.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 80, color: Colors.blue),
              SizedBox(height: 20),
              Text(
                'Smart Lock Login',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 40),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _login,
                child: Text('Login'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                ),
              ),
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
