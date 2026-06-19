import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'main.dart'; // Import main.dart which contains your DashboardPage
import 'register.dart';  // Import the RegisterPage
import 'package:shared_preferences/shared_preferences.dart'; // Tambah ini di import


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Controllers for the input fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Method to check the login credentials against Firestore

Future<void> _loginUser(String username, String password) async {
  print('LOGIN TRIGGERED: $username, $password');
  try {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('Username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .where('isAdmin', isEqualTo: true)
        .limit(1)
        .get();

    print('SNAPSHOT FOUND: ${snapshot.docs.length}');
    if (snapshot.docs.isNotEmpty) {
      String userId = snapshot.docs.first.id;
      // AMBIL full name dari field Firestore
      String fullName = '';
      try {
        fullName = snapshot.docs.first['fullname'] ?? '';
      } catch (e) {
        print('Field fullname not found: $e');
      }

      print('USER LOGGED IN, ID: $userId, FULLNAME: $fullName');
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('fullName', fullName); // <- INI TAMBAHKAN

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardPage()),
      );
    } else {
      print('NO USER FOUND MATCH');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username, password, or not an admin')),
      );
    }
  } catch (e) {
    print('LOGIN ERROR: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error logging in. Please try again')),
    );
  }
}
bool _showPassword = false;




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3), // Set the background color
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600), // Maximum width for desktop
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Admin Icon
                Icon(Icons.account_circle, size: 100, color: Color(0xFF22B04B)),
                const SizedBox(height: 20),
                // Title
                const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22B04B), // Green title color
                  ),
                ),
                const SizedBox(height: 40),
                // Username input
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person, color: Color(0xFF22B04B)),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                // Password input
                TextField(
  controller: _passwordController,
  obscureText: !_showPassword,
  decoration: InputDecoration(
    labelText: 'Password',
    prefixIcon: Icon(Icons.lock, color: Color(0xFF22B04B)),
    border: OutlineInputBorder(),
    suffixIcon: IconButton(
      icon: Icon(
        _showPassword ? Icons.visibility : Icons.visibility_off,
        color: Colors.grey[700],
      ),
      onPressed: () {
        setState(() {
          _showPassword = !_showPassword;
        });
      },
    ),
  ),
),
const SizedBox(height: 20),
                // Login button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Trigger the login process
                      _loginUser(
                        _usernameController.text,
                        _passwordController.text,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF22B04B), // Green button color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Link to Register Page
                TextButton(
                  onPressed: () {
                    // Navigate to the Register page
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => RegisterPage()), // Correct navigation to Register Page
                    );
                  },
                  child: const Text(
                    'Don\'t have an account? Register here',
                    style: TextStyle(
                      color: Color(0xFF22B04B),
                      fontWeight: FontWeight.bold,
                    ),
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
