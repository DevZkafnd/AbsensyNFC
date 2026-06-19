import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login.dart';  // Import the LoginPage
import 'app_drawer.dart'; // Import the AppDrawer
import 'package:shared_preferences/shared_preferences.dart'; // Tambah ini

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Define the user data variables
  String fullName = '';
  String phoneNumber = '';
  String position = '';

  // Method to fetch user data from Firestore
Future<void> _fetchUserData() async {
  try {
    // AMBIL userId dari SharedPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (snapshot.exists) {
      setState(() {
        fullName = snapshot['fullname'];
        phoneNumber = snapshot['phone_number'];
        position = snapshot['position'];
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User data not found')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Error fetching data')),
    );
  }
}


  @override
  void initState() {
    super.initState();
    _fetchUserData(); // Fetch user data when the profile page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile Admin',
          style: TextStyle(
            fontSize: 30, // Set the desired font size
            fontWeight: FontWeight.bold, // Make the text bold
          ),
        ),
        backgroundColor: Color(0xFFFFFFFF), // White background for AppBar
        iconTheme: const IconThemeData(color: Color(0xFF22B04B)), // Green icon color for AppBar
        elevation: 0, // Remove the shadow under the AppBar
      ),
      drawer: AppDrawer(), // Include the sidebar drawer here
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.account_circle, size: 100, color: Color(0xFF22B04B)), // Green profile icon
              const SizedBox(height: 10), // Reduced space here
              // Display Full Name
              Text(
                'Full Name: $fullName',
                style: const TextStyle(fontSize: 16, color: Color(0xFF484646)), // Dark grey for text
              ),
              const SizedBox(height: 5), // Reduced space here
              // Display Phone Number
              Text(
                'Phone: $phoneNumber',
                style: const TextStyle(fontSize: 16, color: Color(0xFF484646)),
              ),
              const SizedBox(height: 5), // Reduced space here
              // Display Position
              Text(
                'Position: $position',
                style: const TextStyle(fontSize: 16, color: Color(0xFF484646)),
              ),
              const SizedBox(height: 20),
              // Logout button
              ElevatedButton(
                onPressed: () async {
                  // Hapus userId dari SharedPreferences
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.remove('userId');

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Green button color
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
