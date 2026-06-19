import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final Stream<Map<String, dynamic>?> _userProfileStream;

  @override
  void initState() {
    super.initState();
    _userProfileStream = _getUserProfileStream();
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user_id');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  // Tambahkan stream user profile
  Stream<Map<String, dynamic>?> _getUserProfileStream() async* {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('logged_in_user_id');
    if (userId == null) {
      yield null;
      return;
    }
    final snapStream = FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: int.parse(userId))
        .limit(1)
        .snapshots();
    await for (final snap in snapStream) {
      if (snap.docs.isEmpty) {
        yield null;
      } else {
        yield snap.docs.first.data();
      }
    }
  }

  Future<String?> _getUserDocId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('logged_in_user_id');
    if (userId == null) return null;
    return userId;
  }

  void _scanAndSaveNfcCard() async {
    final userDocId = await _getUserDocId();
    if (!mounted) return;
    if (userDocId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan')),
      );
      return;
    }

    // Cek apakah user sudah memiliki NFC card ID
    final userSnap = await FirebaseFirestore.instance
        .collection('users')
        .where('id', isEqualTo: int.parse(userDocId))
        .limit(1)
        .get();
    if (!mounted) return;
    
    if (userSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User tidak ditemukan')),
      );
      return;
    }

    final userData = userSnap.docs.first.data();
    final currentCardId = userData['card_id'];
    
    // Jika user sudah memiliki NFC card ID, tampilkan pesan
    if (currentCardId != null && currentCardId.toString().isNotEmpty && currentCardId != '-') {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Tidak Dapat Mendaftarkan NFC'),
          content: const Text('Anda sudah memiliki NFC card ID. Untuk mengubah NFC card ID, silakan hubungi admin.'),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
        ),
      );
      return;
    }

    bool dialogOpen = true;
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    splashRadius: 18,
                    onPressed: () {
                      dialogOpen = false;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              Icon(Icons.nfc, size: 64, color: Color(0xFF178A3D)),
              const SizedBox(height: 16),
              const Text(
                'Tempelkan kartu NFC Anda ke belakang HP',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pastikan NFC HP sudah aktif',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
      if (dialogOpen) {
        final tag = await FlutterNfcKit.poll();
        final nfcId = tag.id;
        
        final cek = await FirebaseFirestore.instance
            .collection('users')
            .where('card_id', isEqualTo: nfcId)
            .get();
        if (!mounted) return;
        
        debugPrint('NFC ID yang di-scan: $nfcId');
        debugPrint('User ID yang sedang login: $userDocId');
        debugPrint('Jumlah document dengan card_id yang sama: ${cek.docs.length}');
        
        bool isDuplicate = false;
        for (var doc in cek.docs) {
          final docData = doc.data();
          final docUserId = docData['id'];
          debugPrint('Document user ID: $docUserId, tipe: ${docUserId.runtimeType}');
          if (docUserId != int.parse(userDocId)) {
            isDuplicate = true;
            debugPrint('NFC card sudah digunakan oleh user ID: $docUserId');
            break;
          }
        }
        
        if (isDuplicate) {
          if (dialogOpen) {
            Navigator.pop(context);
          }
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Gagal'),
              content: const Text('NFC card ini sudah terdaftar pada user lain!'),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
            ),
          );
          return;
        }
        
        await userSnap.docs.first.reference.update({'card_id': nfcId});
        if (!mounted) return;
        
        if (dialogOpen) {
          Navigator.pop(context);
        }
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Berhasil'),
            content: Text('NFC card $nfcId berhasil didaftarkan!'),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (dialogOpen) {
        Navigator.pop(context);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membaca NFC: $e')),
      );
    } finally {
      await FlutterNfcKit.finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 32, top: 60),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF178A3D), Color(0xFF4ADE80)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Center(
                child: Text(
                  'Profil User',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 28,
                  ),
                  child: StreamBuilder<Map<String, dynamic>?>(
                    stream: _userProfileStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final user = snapshot.data;
                      if (user == null) {
                        return const Center(child: Text('User tidak ditemukan'));
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user['fullname'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFF178A3D))),
                                  const SizedBox(height: 4),
                                  Text(user['position'] ?? '-', style: const TextStyle(fontSize: 15, color: Colors.black54)),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          const Text('No. HP', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(user['phone_number'] ?? '-', style: const TextStyle(fontSize: 15)),
                          ),
                          const SizedBox(height: 28),
                          const Text('NFC Card ID', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(user['card_id'] ?? '-', style: const TextStyle(fontSize: 15)),
                          ),
                          const SizedBox(height: 28),
                          // Input NFC Card (opsional, bisa diaktifkan jika ingin edit)
                          const Text('Input NFC Card', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.nfc),
                            label: const Text('Tap NFC Card'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF178A3D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                              textStyle: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: _scanAndSaveNfcCard,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _logout,
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
