import 'package:flutter/material.dart';
import 'main_user_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadRememberedUser();
  }

  Future<void> _loadRememberedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final remembered = prefs.getBool('remember_me') ?? false;
    if (remembered) {
      setState(() {
        _rememberMe = true;
        _usernameController.text = prefs.getString('remembered_username') ?? '';
        _passwordController.text = prefs.getString('remembered_password') ?? '';
      });
    }
  }

  Future<void> _setRememberedUser(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool('remember_me', true);
      await prefs.setString('remembered_username', _usernameController.text);
      await prefs.setString('remembered_password', _passwordController.text);
    } else {
      await prefs.setBool('remember_me', false);
      await prefs.remove('remembered_username');
      await prefs.remove('remembered_password');
    }
  }

  Future<String?> _loginUser(String username, String password) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('Username', isEqualTo: username)
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    // Simpan id sebagai String
    return snap.docs.first.data()['id'].toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Stack(
        children: [
          // Header gradient hijau dengan bentuk melengkung
          SizedBox(
            width: double.infinity,
            height: 340,
            child: ClipPath(
              clipper: _HeaderClipper(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF178A3D), Color(0xFF4ADE80)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    // Dekorasi icon lampu
                    Positioned(
                      left: 40,
                      top: 60,
                      child: Icon(Icons.lightbulb_outline, size: 48, color: Colors.white.withAlpha(64)),
                    ),
                    // Dekorasi icon jam
                    Positioned(
                      right: 40,
                      top: 40,
                      child: Icon(Icons.access_time, size: 40, color: Colors.white.withAlpha(64)),
                    ),
                    // Dekorasi icon tanaman
                    Positioned(
                      right: 80,
                      bottom: 30,
                      child: Icon(Icons.eco, size: 50, color: Colors.white.withAlpha(46)),
                    ),
                    // Tulisan Login
                    Align(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80.0),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            shadows: [
                              Shadow(
                                color: Colors.black.withAlpha(38),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Form login
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 220.0, left: 24, right: 24),
                child: Column(
                  children: [
                    // Gambar authentication di atas card login
                    Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Image.asset(
                        'assets/images/authentication-65.png',
                        height: 300,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                labelText: 'Username',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock),
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) {
                                    setState(() {
                                      _rememberMe = val ?? false;
                                    });
                                    _setRememberedUser(_rememberMe);
                                  },
                                  activeColor: const Color(0xFF178A3D),
                                ),
                                const Text('Remember Me'),
                              ],
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF178A3D), Color(0xFF4ADE80)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    FocusScope.of(context).unfocus();
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (context) => const Center(child: CircularProgressIndicator()),
                                    );
                                    final userId = await _loginUser(_usernameController.text.trim(), _passwordController.text.trim());
                                    if (!context.mounted) return;
                                    Navigator.pop(context); // close loading
                                    if (userId != null) {
                                      if (_rememberMe) {
                                        await _setRememberedUser(true);
                                      } else {
                                        await _setRememberedUser(false);
                                      }
                                      final prefs = await SharedPreferences.getInstance();
                                      await prefs.setString('logged_in_user_id', userId);
                                      if (!context.mounted) return;
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(builder: (context) => const MainUserPage()),
                                      );
                                    } else {
                                      if (!context.mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Username atau password salah!')),
                                      );
                                    }
                                  },
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom clipper untuk header melengkung
class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 60);
    path.quadraticBezierTo(
      size.width / 2, size.height,
      size.width, size.height - 60,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
} 
