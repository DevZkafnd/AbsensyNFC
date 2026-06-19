import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'app_drawer.dart';

class KelolaAkunPage extends StatefulWidget {
  const KelolaAkunPage({super.key});

  @override
  _KelolaAkunPageState createState() => _KelolaAkunPageState();
}

class _KelolaAkunPageState extends State<KelolaAkunPage> {
  // Controllers for the input fields
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _posisiController = TextEditingController();
  final TextEditingController _noHapeController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Controller for the search field

  // Controller for the search field
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = ''; // To hold the search query
  
  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch accounts from Firestore
  Future<List<Map<String, String>>> _fetchAccounts() async {
  QuerySnapshot snapshot = await _firestore.collection('users').get();
  return snapshot.docs.map((doc) {
    var data = doc.data() as Map<String, dynamic>?;

    return {
      'docId': doc.id,  // Ambil document ID dari Firestore
      'id': data?['id']?.toString() ?? 'No ID', // Mengambil ID auto-increment yang telah disimpan di Firestore
      'fullname': data?['fullname']?.toString() ?? 'No Fullname',
      'position': data?['position']?.toString() ?? 'No Position',
      'phone_number': data?['phone_number']?.toString() ?? 'No Phone Number',
      'Username': data?['Username']?.toString() ?? 'No Username',
      'password': data?['password']?.toString() ?? 'No Password',
      'card_id': data?['card_id']?.toString() ?? 'No Card ID',
      'isAdmin': data?['isAdmin']?.toString() ?? 'false',
    };
  }).toList();
}
    Future<int> _getNextId() async {
  // Ambil semua akun dari Firestore
  QuerySnapshot snapshot = await _firestore.collection('users').orderBy('id', descending: true).limit(1).get();

  // Jika tidak ada data, ID pertama adalah 1
  if (snapshot.docs.isEmpty) {
    return 1;
  }

  // Ambil ID terakhir dan hitung ID berikutnya
  var lastDoc = snapshot.docs.first;
  int lastId = int.tryParse(lastDoc['id'].toString()) ?? 0;

  return lastId + 1; // ID berikutnya
}


   // Function to show the Add Account popup
  void _showAddAccountPopup() {
    // Clear the form before showing the dialog
    _namaController.clear();
    _posisiController.clear();
    _noHapeController.clear();
    _usernameController.clear();
    _passwordController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Tambah Akun User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF22B04B),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                ),
              ),
              TextField(
                controller: _posisiController,
                decoration: const InputDecoration(
                  labelText: 'Posisi',
                ),
              ),
              TextField(
                controller: _noHapeController,
                decoration: const InputDecoration(
                  labelText: 'No. Hape',
                ),
              ),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                ),
              ),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                ),
                obscureText: true, // Hide the password input
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF22B04B), // Green color for the button text
            ),
            child: const Text(
              'Batal',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Dapatkan ID berikutnya
              int newId = await _getNextId();

              // Tambahkan data ke Firestore dengan ID yang baru
              await _firestore.collection('users').add({
                'id': newId, // Gunakan ID auto-increment
                'fullname': _namaController.text,
                'position': _posisiController.text,
                'phone_number': _noHapeController.text,
                'Username': _usernameController.text,
                'password': _passwordController.text,
                'card_id': "", // Set card_id ke string kosong (bukan null)
                'isAdmin': false, // Set isAdmin ke false
              });

              // Tutup dialog
              Navigator.of(context).pop();

              // Refresh halaman untuk menampilkan data terbaru
              setState(() {});
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF22B04B), // Warna tombol hijau
            ),
            child: const Text(
              'Tambah',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Function to show account details
  void _showAccountDetails(Map<String, String> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Detail Akun ${data['name']}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF22B04B),
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID Karyawan: ${data['id']}'),
            Text('Full Name: ${data['fullname']}'),
            Text('Posisi: ${data['position']}'),
            Text('No. Hape: ${data['phone_number']}'),
            Text('Username: ${data['Username']}'),
            Text('Password: ${data['password']}'),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF22B04B), // Green color for the button text
            ),
            child: const Text(
              'Tutup',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>( 
      future: _fetchAccounts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          List<Map<String, String>> accounts = snapshot.data ?? [];

          // Filter the accounts list based on the search query
          List<Map<String, String>> filteredAccounts = accounts
            .where((account) =>
                account['id']!.contains(_searchQuery) ||
                account['fullname']!.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

          // Sort by 'id' in ascending order
          filteredAccounts.sort((a, b) {
            int idA = int.tryParse(a['id'] ?? '0') ?? 0;
            int idB = int.tryParse(b['id'] ?? '0') ?? 0;
            return idA.compareTo(idB); // Compare 'id' numerically
          });


          return Scaffold(
            appBar: AppBar(
              title: const Text(
                'Kelola Akun',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Color(0xFF22B04B)),
              elevation: 0,
            ),
            drawer: AppDrawer(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 160.0),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 200,
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                labelText: 'Cari ID/Nama',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.search),
                              ),
                              onSubmitted: (value) {
                                setState(() {
                                  _searchQuery = value;
                                });
                              },
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _showAddAccountPopup, 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF22B04B),
                            ),
                            child: const Text(
                              'Tambah Akun',
                                style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                )
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 120.0,
                          headingRowHeight: 30,
                          dataRowHeight: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'ID Karyawan',
                                style: TextStyle(
                                  color: Color(0xFF22B04B),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Nama',
                                style: TextStyle(
                                  color: Color(0xFF22B04B),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Posisi',
                                style: TextStyle(
                                  color: Color(0xFF22B04B),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'No. Hape',
                                style: TextStyle(
                                  color: Color(0xFF22B04B),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Detail',
                                style: TextStyle(
                                  color: Color(0xFF22B04B),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Hapus',
                                style: TextStyle(
                                  color: Color(0xFF22B04B),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          rows: filteredAccounts.map((data) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(data['id']!, style: const TextStyle(fontSize: 18, color: Colors.black)),
                                ),
                                DataCell(
                                  Text(data['fullname']!, style: const TextStyle(fontSize: 18, color: Colors.black)),
                                ),
                                DataCell(
                                  Text(data['position']!, style: const TextStyle(fontSize: 18, color: Colors.black)),
                                ),
                                DataCell(
                                  Text(data['phone_number']!, style: const TextStyle(fontSize: 18, color: Colors.black)),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.info, color: Color(0xFF22B04B)),
                                    onPressed: () {
                                      _showAccountDetails(data);
                                    },
                                  ),
                                ),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () async {
                                      try {
                                        // Ambil docId yang terkait dengan akun yang ingin dihapus
                                        String docIdToDelete = data['docId']!;

                                        // Hapus dokumen berdasarkan docId
                                        await _firestore.collection('users').doc(docIdToDelete).delete();

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Account deleted successfully!')),
                                        );
                                        setState(() {}); // Refresh data setelah penghapusan
                                      } catch (error) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to delete account: $error')),
                                        );
                                      }
                                    },
                                  )
                                )
                              ],
                            );
                          }).toList(),
                          dividerThickness: 2, // Divider thickness between rows
                          horizontalMargin: 5, // Add horizontal margin to avoid the edges touching the content
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      },
    );
  }
}
