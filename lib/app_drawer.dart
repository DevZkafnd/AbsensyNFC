import 'package:flutter/material.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  _AppDrawerState createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> with RouteAware {
  String currentPage = 'Absensy'; // Mengganti nama halaman dengan logo teks "Absensy"

  @override
  void didPopNext() {
    super.didPopNext();
    _updateCurrentPage();
  }

  @override
  void didPushNext() {
    super.didPushNext();
    _updateCurrentPage();
  }

  @override
  void didPush() {
    super.didPush();
    _updateCurrentPage();
  }

  // Fungsi untuk memperbarui nama halaman di header saat rute berubah
  void _updateCurrentPage() {
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '';
    setState(() {
      switch (currentRoute) {
        case '/dashboard':
          currentPage = 'Absensy'; // Mengganti nama halaman dengan logo teks "Absensy"
          break;
        case '/absensi':
          currentPage = 'Data Absensi';
          break;
        case '/kelola-akun':
          currentPage = 'Kelola Akun';
          break;
        case '/profile':
          currentPage = 'Profile Admin';
          break;
        default:
          currentPage = 'Absensy'; // Default ke logo teks "Absensy"
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mendapatkan rute yang aktif saat ini
    String currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    return Drawer(
      child: Container(
        color: Colors.white, // Setting the background of the entire drawer to white
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            // Header Drawer yang menampilkan nama aplikasi "Absensy"
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF22B04B), // Warna hijau untuk header
              ),
              padding: EdgeInsets.only(top: 0), // Mengatur padding atas untuk mengangkat background lebih tinggi
              child: Align(
                alignment: Alignment.center, // Align text to the center
                child: Text(
                  'Absensy', // Menampilkan logo teks aplikasi "Absensy"
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30, // Ukuran font lebih besar untuk logo teks
                    fontWeight: FontWeight.bold, // Memberikan ketebalan font untuk logo
                  ),
                ),
              ),
            ),
            // List item untuk Dashboard Admin
            _buildDrawerItem('Dashboard Admin', '/dashboard', currentRoute),
            // List item untuk Data Absensi
            _buildDrawerItem('Data Absensi', '/absensi', currentRoute),
            // List item untuk Kelola Akun
            _buildDrawerItem('Kelola Akun', '/kelola-akun', currentRoute),
            // List item untuk Profile Admin
            _buildDrawerItem('Profile Admin', '/profile', currentRoute),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk membangun setiap item pada drawer dengan efek hover
  Widget _buildDrawerItem(String title, String route, String currentRoute) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          // Trigger hover effect (background gray on hover)
          _hoverEffect(route);
        });
      },
      onExit: (_) {
        setState(() {
          // Reset to normal color when the mouse exits
        });
      },
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: currentRoute == route
                ? Color(0xFF22B04B) // Warna hijau untuk item yang aktif
                : Color(0xFF484646), // Warna abu-abu untuk item yang tidak aktif
          ),
        ),
        onTap: () {
          setState(() {
            currentPage = title; // Mengubah teks header sesuai dengan halaman yang dipilih
          });
          Navigator.pushReplacementNamed(context, route); // Pindah halaman
        },
      ),
    );
  }

  // Function to apply hover effect
  void _hoverEffect(String route) {
    setState(() {
      // On hover change the color to a light gray (for example)
      Color hoverColor = Color(0xFFBDBDBD); // Light Gray color
      _updateListItemStyle(route, hoverColor);
    });
  }

  void _updateListItemStyle(String route, Color hoverColor) {
    // Change the style of the hovered list item (this is just a placeholder, adjust based on design)
  }
}
