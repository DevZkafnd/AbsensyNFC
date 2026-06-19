import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';  // Add this import for date formatting
import 'app_drawer.dart';


class AbsensiPage extends StatefulWidget {
  const AbsensiPage({super.key});

  @override
  _AbsensiPageState createState() => _AbsensiPageState();
}

class _AbsensiPageState extends State<AbsensiPage> {
  final TextEditingController _searchController = TextEditingController();
  String filter = ''; // Filter for ID, Nama, or Tanggal
  int entriesPerPage = 5; // Default number of entries to show per page

  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetch absensi data
  Future<List<Map<String, String>>> _fetchAbsensiData() async {
    // Query the absensi collection
    QuerySnapshot absensiSnapshot = await _firestore.collection('absensi').get();

    // Query the users collection to map card_id to usernames
    QuerySnapshot usersSnapshot = await _firestore.collection('users').get();

    // Map to hold card_id to fullname (username) for easy lookup
    Map<String, String> usersMap = {};
    usersSnapshot.docs.forEach((userDoc) {
      usersMap[userDoc['card_id']] = userDoc['fullname'];
    });

    // Combine absensi data with user name
    List<Map<String, String>> absensiData = [];
    for (var absensiDoc in absensiSnapshot.docs) {
      String cardId = absensiDoc['card_id'];
      String userName = usersMap[cardId] ?? 'Unknown'; // Default to 'Unknown' if no match

      // Convert Firestore timestamp to DateTime and add 7 hours for WIB
      DateTime dateTime = absensiDoc['in_time'].toDate().add(Duration(hours: 7));

      // Format the date and time
      String formattedDate = DateFormat('yyyy-MM-dd').format(dateTime); // Date in 'YYYY-MM-DD' format
      String formattedTime = DateFormat('HH:mm').format(dateTime); // Time in 'HH:mm' format

      absensiData.add({
        'id': absensiDoc['id'].toString(),
        'nama_user': userName,
        'tanggal': formattedDate,
        'waktu': formattedTime,
        'status': absensiDoc['keterangan'],
      });
    }

    return absensiData;
  }

  // Function to determine the status based on waktu
  String getStatus(String waktu) {
    DateTime time = DateTime.parse('2025-07-21 $waktu'); // Parsing the time
    if (time.hour < 7) {
      return 'hadir';
    } else if (time.hour >= 7 && time.hour < 9) {
      return 'hadir';
    } else {
      return 'terlambat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, String>>>( 
      future: _fetchAbsensiData(), // Fetch data from Firestore
      builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No data available'));
      }


        // Filter data based on the search input (ID, Nama, or Tanggal)
        // Copy data dulu, lalu urutkan ID ASCENDING (terkecil ke terbesar)
        List<Map<String, String>> sortedData = List<Map<String, String>>.from(snapshot.data!);
        sortedData.sort((a, b) => int.parse(a['id']!).compareTo(int.parse(b['id']!)));

        // Baru filter
        List<Map<String, String>> filteredData = sortedData
            .where((data) =>
                data['id']!.contains(filter) ||
                data['nama_user']!.toLowerCase().contains(filter.toLowerCase()) ||
                data['tanggal']!.contains(filter))
            .toList();

        // Limit the number of rows shown based on the selected entries per page
        filteredData = filteredData.take(entriesPerPage).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Data Absensi Karyawan',
              style: TextStyle(
                fontSize: 30, // Set the desired font size
                fontWeight: FontWeight.bold, // Make the text bold
              ),
            ),
            backgroundColor: Colors.white, // Set app bar to white
            iconTheme: const IconThemeData(color: Color(0xFF22B04B)), // Dark gray icons
          ),
          drawer: const AppDrawer(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Row containing both search and "Show entries" dropdown
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0), // Padding around the row
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // "Show entries" dropdown
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          width: MediaQuery.of(context).size.width * 0.05, // Reduced width for dropdown
                          child: DropdownButton<int>(
                            value: entriesPerPage,
                            items: [5, 10, 15, 20].map((int value) {
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('Show $value'),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                entriesPerPage = value!; // Update the number of entries per page
                              });
                            },
                            style: const TextStyle(color: Color(0xFF484646)),
                            icon: const Icon(Icons.arrow_drop_down),
                            iconEnabledColor: const Color(0xFF484646),
                            underline: Container(
                              height: 2,
                              color: const Color(0xFF22B04B),
                            ),
                          ),
                        ),
                        // Search bar aligned right and shortened
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          width: MediaQuery.of(context).size.width * 0.4, // Shorten the width (40% of screen width)
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Cari...',
                              labelStyle: const TextStyle(color: Color(0xFF484646)), // Dark gray label color
                              hintText: 'Masukkan ID, Nama, atau Tanggal',
                              hintStyle: const TextStyle(color: Color(0xFF484646)), // Dark gray hint color
                              border: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFF22B04B), width: 2), // Green border
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                              suffixIcon: const Icon(Icons.search, color: Color(0xFF22B04B)), // Green search icon
                            ),
                            style: const TextStyle(fontSize: 14, color: Color(0xFF484646)), // Dark gray text color
                            onChanged: (value) {
                              setState(() {
                                filter = value; // Update the filter as user types
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // DataTable displaying the filtered results
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50.0), // Add padding from sides
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: 245.0, // Adjust column spacing to add more space between columns
                          headingRowHeight: 30, // Height for the header row
                          dataRowHeight: 50, // Height for the data rows
                          decoration: BoxDecoration(
                            color: Colors.white, // White background for the table
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'ID',
                                style: TextStyle(
                                  color: Color(0xFF22B04B), // Green font color
                                  fontSize: 20, // Font size
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Nama User',
                                style: TextStyle(
                                  color: Color(0xFF22B04B), // Green font color
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Tanggal',
                                style: TextStyle(
                                  color: Color(0xFF22B04B), // Green font color
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Waktu',
                                style: TextStyle(
                                  color: Color(0xFF22B04B), // Green font color
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Status',
                                style: TextStyle(
                                  color: Color(0xFF22B04B), // Green font color
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          rows: filteredData.map((data) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    data['id']!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    data['nama_user']!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    data['tanggal']!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    data['waktu']!,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                DataCell(
                                  Text(
                                    getStatus(data['waktu']!),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                          dividerThickness: 2, // Adjust thickness for the divider
                          horizontalMargin: 0, // Set horizontal margin to 0 to avoid any extra space between the columns
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
