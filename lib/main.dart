import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'app_drawer.dart';  // Make sure AppDrawer is correctly imported
import 'profile.dart';  // Make sure ProfilePage is correctly imported
import 'absensi.dart';  // Make sure AbsensiPage is correctly imported
import 'kelolaakun.dart';  // Make sure KelolaAkunPage is correctly imported
import 'package:firebase_core/firebase_core.dart';
import 'login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';





void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await initializeDateFormatting('id_ID', null);  // <--- Tambah baris ini!
  runApp(MyApp());
}


class AppRouteObserver extends RouteObserver<PageRoute<dynamic>> {}

class MyApp extends StatelessWidget {
  final AppRouteObserver routeObserver = AppRouteObserver();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard Admin - Absensy',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF22B04B)),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFF22B04B)),
          titleTextStyle: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: Color(0xFF484646),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF484646)),
          bodyMedium: TextStyle(color: Color(0xFF484646)),
          headlineMedium: TextStyle(color: Color(0xFF22B04B)),
        ),
      ),
      navigatorObservers: [routeObserver],
      initialRoute: '/login',  // Set initial route to LoginPage
      routes: {
        '/': (context) => const LoginPage(),  // Default route to LoginPage
        '/login': (context) => const LoginPage(),  // Login page route
        '/dashboard': (context) => const DashboardPage(),
        '/profile': (context) => const ProfilePage(),
        '/absensi': (context) => const AbsensiPage(),
        '/kelola-akun': (context) => const KelolaAkunPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
// Halaman Dashboard
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class AttendanceData {
  final String label;
  int hadir;
  int tidakHadir;

  AttendanceData(this.label, this.hadir, this.tidakHadir);
}

class ApprovalCard {
  final String name;
  final String disease;
  final int days;
  final String type;
  final String additionalInfo;
  bool isApproved;
  final String id;
  final String timestamp;
  final String? urlLampiran; // Tambahkan field ini

  ApprovalCard(
    this.id,
    this.name,
    this.disease,
    this.days,
    this.type,
    this.timestamp, {
    this.isApproved = false,
    this.additionalInfo = '',
    this.urlLampiran, // Default null
  });
}


class _DashboardPageState extends State<DashboardPage> {
  String _fullName = '';
  int jumlahHadir = 0;
  int jumlahTidakHadir = 0;
  List<ApprovalCard> approvalCards = [];
  double yInterval = 2; // default ke per hari


  String _selectedFilter = 'Per Hari';
  final List<String> _filterOptions = ['Per Hari', 'Per Bulan', 'Per Tahun'];

  List<AttendanceData> attendanceList = [];

  final List<AttendanceData> allAttendanceList = [
    AttendanceData('Sen', 20, 5),
    AttendanceData('Sel', 22, 3),
    AttendanceData('Rab', 24, 2),
    AttendanceData('Kam', 21, 6),
    AttendanceData('Jum', 23, 3),
    AttendanceData('Jan', 100, 20),
    AttendanceData('Feb', 95, 10),
    AttendanceData('2022', 1000, 80),
    AttendanceData('2023', 980, 90),
  ];

  StreamSubscription<int>? _refreshSub;


  Future<void> fetchJumlahTidakHadirHariIni() async {
  DateTime now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
  DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  QuerySnapshot snapshot = await FirebaseFirestore.instance
    .collection('perizinan')
    .where('status', isEqualTo: 'approved')
    .where('start_date', isGreaterThanOrEqualTo: startOfDay)
    .where('start_date', isLessThanOrEqualTo: endOfDay)
    .get();

if (!mounted) return;
setState(() {
  jumlahTidakHadir = snapshot.docs.length;
});
}

Future<void> _getFullName() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? name = prefs.getString('fullName');
  if (name != null && name.isNotEmpty) {
    if (!mounted) return;
    setState(() {
      _fullName = name;
    });
  }
}



Future<void> fetchApprovalCards() async {
  DateTime now = DateTime.now();
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
  DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  QuerySnapshot snapshot = await FirebaseFirestore.instance
    .collection('perizinan')
    .where('status', isEqualTo: 'pending')
    .where('start_date', isGreaterThanOrEqualTo: startOfDay)
    .where('start_date', isLessThanOrEqualTo: endOfDay)
    .get();

  List<ApprovalCard> cards = [];
  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final tipe = data['tipe'] ?? 'Izin';
    // url_lampiran HANYA untuk 'sakit'
    final urlLampiran = tipe.toLowerCase() == 'sakit' ? data['url_lampiran'] as String? : null;
    cards.add(
      ApprovalCard(
        doc.id,
        data['username'] ?? 'Unknown',
        data['nama_penyakit'] ?? '-',  // fix field: nama_penyakit
        data['waktu'] ?? 1,
        tipe,
        DateFormat('yyyy-MM-dd HH:mm:ss').format(
          (data['start_date'] as Timestamp).toDate()
        ),
        additionalInfo: data['keterangan'] ?? '',
        urlLampiran: urlLampiran,
      )
    );
  }

  if (!mounted) return;
  setState(() {
    approvalCards = cards;
  });
}


Future<void> updateAttendanceChartPerTahun() async {
  final absensiSnapshot = await FirebaseFirestore.instance.collection('absensi').get();
  final izinSnapshot = await FirebaseFirestore.instance
      .collection('perizinan')
      .where('status', isEqualTo: 'approved')
      .get();

  Map<String, AttendanceData> dataPerTahun = {};

  // Data hadir
  for (var doc in absensiSnapshot.docs) {
    final data = doc.data();
    final tgl = (data['in_time'] as Timestamp).toDate();
    final tahun = DateFormat('yyyy').format(tgl); // contoh: '2022', '2023'
    if (!dataPerTahun.containsKey(tahun)) {
      dataPerTahun[tahun] = AttendanceData(tahun, 0, 0);
    }
    if (data['keterangan'] == 'hadir') {
      dataPerTahun[tahun]!.hadir += 1;
    }
  }

  // Data tidak hadir
  for (var doc in izinSnapshot.docs) {
    final data = doc.data();
    final tgl = (data['start_date'] as Timestamp).toDate();
    final tahun = DateFormat('yyyy').format(tgl);
    if (!dataPerTahun.containsKey(tahun)) {
      dataPerTahun[tahun] = AttendanceData(tahun, 0, 0);
    }
    dataPerTahun[tahun]!.tidakHadir += 1;
  }

  // Urut tahun
  List<String> urutanTahun = dataPerTahun.keys.toList()..sort(); // otomatis ascending
  List<AttendanceData> chartData = [];
  for (var t in urutanTahun) {
    chartData.add(dataPerTahun[t]!);
  }

if (!mounted) return;
  setState(() {
    attendanceList = chartData;
  });
}


Future<void> updateAttendanceChartPerBulan() async {
  final absensiSnapshot = await FirebaseFirestore.instance.collection('absensi').get();
  final izinSnapshot = await FirebaseFirestore.instance
      .collection('perizinan')
      .where('status', isEqualTo: 'approved')
      .get();

  Map<String, AttendanceData> dataPerBulan = {};

  // Data hadir
  for (var doc in absensiSnapshot.docs) {
    final data = doc.data();

    final tgl = (data['in_time'] as Timestamp).toDate();
    final bulan = DateFormat('MMM', 'id_ID').format(tgl); // "Jan", "Feb", dst

    if (!dataPerBulan.containsKey(bulan)) {
      dataPerBulan[bulan] = AttendanceData(bulan, 0, 0);
    }
    if (data['keterangan'] == 'hadir') {
      dataPerBulan[bulan]!.hadir += 1;
    }
  }

  // Data tidak hadir
  for (var doc in izinSnapshot.docs) {
    final data = doc.data();
    final tgl = (data['start_date'] as Timestamp).toDate();
    final bulan = DateFormat('MMM', 'id_ID').format(tgl);

    if (!dataPerBulan.containsKey(bulan)) {
      dataPerBulan[bulan] = AttendanceData(bulan, 0, 0);
    }
    dataPerBulan[bulan]!.tidakHadir += 1;
  }

  // Urutkan bulan: Jan–Des
  List<String> urutanBulan = [
    'Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'
  ];
  List<AttendanceData> chartData = [];
  for (var b in urutanBulan) {
    if (dataPerBulan.containsKey(b)) {
      chartData.add(dataPerBulan[b]!);
    }
  }

if (!mounted) return;
  setState(() {
    attendanceList = chartData;
  });
}


Future<Map<String, int>> fetchAbsensiPerHari() async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
    .collection('absensi')
    .get();

  Map<String, int> hadirPerHari = {};
  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final inTime = (data['in_time'] as Timestamp).toDate();
    String hari = DateFormat('E', 'id_ID').format(inTime); // contoh: 'Sen', 'Sel', dst
    if (data['keterangan'] == 'hadir') {
      hadirPerHari[hari] = (hadirPerHari[hari] ?? 0) + 1;
    }
  }
  return hadirPerHari;
}
Future<Map<String, int>> fetchTidakHadirPerHari() async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance
    .collection('perizinan')
    .where('status', isEqualTo: 'approved')
    .get();

  Map<String, int> tidakHadirPerHari = {};
  for (var doc in snapshot.docs) {
    final data = doc.data() as Map<String, dynamic>;
    final startDate = (data['start_date'] as Timestamp).toDate();
    String hari = DateFormat('E', 'id_ID').format(startDate); // contoh: 'Sen', 'Sel', dst
    tidakHadirPerHari[hari] = (tidakHadirPerHari[hari] ?? 0) + 1;
  }
  return tidakHadirPerHari;
}

Future<void> updateAttendanceChartPerHari() async {
  final absensiSnapshot = await FirebaseFirestore.instance.collection('absensi').get();
  final izinSnapshot = await FirebaseFirestore.instance
      .collection('perizinan')
      .where('status', isEqualTo: 'approved')
      .get();

  Map<String, AttendanceData> dataPerHari = {};

  // Data hadir
  for (var doc in absensiSnapshot.docs) {
    final data = doc.data();
    final tgl = (data['in_time'] as Timestamp).toDate();
    final hariNama = DateFormat('E', 'id_ID').format(tgl); // "Sen", "Sel", dst

    if (!dataPerHari.containsKey(hariNama)) {
      dataPerHari[hariNama] = AttendanceData(hariNama, 0, 0);
    }
    if (data['keterangan'] == 'hadir') {
      dataPerHari[hariNama]!.hadir += 1;
    }
  }




  
  // Data tidak hadir
  for (var doc in izinSnapshot.docs) {
    final data = doc.data();

    final tgl = (data['start_date'] as Timestamp).toDate();
    final hariNama = DateFormat('E', 'id_ID').format(tgl);

    if (!dataPerHari.containsKey(hariNama)) {
      dataPerHari[hariNama] = AttendanceData(hariNama, 0, 0);
    }
    dataPerHari[hariNama]!.tidakHadir += 1;
  }

  // Urutkan hari: Sen–Min (sesuai konvensi Indonesia)
  List<String> urutanHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  List<AttendanceData> chartData = [];
  for (var h in urutanHari) {
    if (dataPerHari.containsKey(h)) {
      chartData.add(dataPerHari[h]!);
    }
  }

if (!mounted) return;
  setState(() {
    attendanceList = chartData;
  });
}


  Future<void> fetchJumlahHadirHariIni() async {
  DateTime now = DateTime.now();
  // Buat range awal dan akhir hari ini (WIB)
  DateTime startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
  DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  // Query Firestore (dengan asumsi "in_time" bertipe Timestamp)
  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('absensi')
      .where('keterangan', isEqualTo: 'hadir')
      .where('in_time', isGreaterThanOrEqualTo: startOfDay)
      .where('in_time', isLessThanOrEqualTo: endOfDay)
      .get();
if (!mounted) return;
setState(() {
    jumlahHadir = snapshot.docs.length;
  });
}

 @override
void dispose() {
  _refreshSub?.cancel();
  super.dispose();
}






  @override
  void initState() {
    super.initState();
    _getFullName();
    if (_selectedFilter == 'Per Hari') {
  updateAttendanceChartPerHari();
  _updateAttendanceListByFilter(_selectedFilter);
    fetchJumlahHadirHariIni();
    fetchJumlahTidakHadirHariIni();
    fetchApprovalCards();

     // SETUP AUTO REFRESH 30 DETIK
    _refreshSub = Stream<int>.periodic(
  Duration(seconds: 1),
  (count) => count,
).listen((_) async {
  if (!mounted) return;
  await fetchJumlahHadirHariIni();
  if (!mounted) return;
  await fetchJumlahTidakHadirHariIni();
  if (!mounted) return;
  await fetchApprovalCards();
});
  }
  }
  

  void _updateAttendanceListByFilter(String filter) {
    if (!mounted) return;
    setState(() {
      if (filter == 'Per Hari') {
        attendanceList = allAttendanceList
            .where((data) =>
                ['Sen', 'Sel', 'Rab', 'Kam', 'Jum'].contains(data.label))
            .toList();
      } else if (filter == 'Per Bulan') {
        attendanceList = allAttendanceList
            .where((data) => ['Jan', 'Feb'].contains(data.label))
            .toList();
      } else if (filter == 'Per Tahun') {
        attendanceList = allAttendanceList
            .where((data) => ['2022', '2023'].contains(data.label))
            .toList();
      }
    });
  }

  int getPendingCount() {
  return approvalCards.length;
}


  void updateAttendance(bool isApproved) {
    if (!mounted) return;
    setState(() {
      if (isApproved) {
        jumlahHadir += 1;
      } else {
        jumlahTidakHadir += 1;
      }
    });
  }

  void removeCard(int index) {
    if (!mounted) return;
    setState(() {
      approvalCards.removeAt(index);
    });
  }

    void showDetailPopup(ApprovalCard card, int index) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        backgroundColor: Colors.white,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.5,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("ID: ${card.id}", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                Text("Nama: ${card.name}", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                Text("Timestamp: ${card.timestamp}", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                Text("Jenis: ${card.type}", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                Text("Jumlah Hari: ${card.days}", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                if (card.type.toLowerCase() == 'sakit') ...[
                  Text("Penyakit: ${card.disease}", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                  if (card.urlLampiran != null && card.urlLampiran!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                      child: Image.network(
                        card.urlLampiran!,
                        height: 200,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, size: 60, color: Colors.red),
                      ),
                    ),
                  Text("Input Foto Surat Sakit", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                ] else ...[
                  Text("Keterangan Izin: ${card.additionalInfo}", style: TextStyle(fontSize: 16, color: Color(0xFF484646))),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                          .collection('perizinan')
                          .doc(card.id)
                          .update({'status': 'approved'});
                        fetchApprovalCards();
                        fetchJumlahTidakHadirHariIni();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF22B04B),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                          .collection('perizinan')
                          .doc(card.id)
                          .update({'status': 'rejected'});
                        fetchApprovalCards();
                        Navigator.of(context).pop();
                      },
                      child: const Text("Not Approve"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  double maxY = 0;
  if (attendanceList.isNotEmpty) {
    maxY = attendanceList
        .expand((e) => [e.hadir, e.tidakHadir])
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    if (maxY % yInterval != 0) {
      maxY = ((maxY / yInterval).ceil()) * yInterval;
    }
    if (maxY == 0) maxY = yInterval * 2;
  }
    return Scaffold(
    appBar: AppBar(title: const Text('Dashboard Admin')),
    drawer: AppDrawer(),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Text(
  'Selamat Datang Admin${_fullName.isNotEmpty ? ', $_fullName' : ''}!',
  style: TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Color(0xFF22B04B),
  ),
),

            const SizedBox(height: 40),

            // Left Side: Chart and Statistic Containers
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // WIDGET STATISTIK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatBox(
                            context,
                            label: "Karyawan Hadir Hari Ini",
                            count: jumlahHadir,
                            color: Colors.green,
                            widthFraction: 0.3,
                          ),
                          buildStatBox(
                            context,
                            label: "Karyawan Tidak Hadir Hari Ini",
                            count: jumlahTidakHadir,
                            color: Colors.redAccent,
                            widthFraction: 0.3,
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),

                      // DROPDOWN FILTER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Text(
                            'Filter: ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF484646), // Dark gray from the palette
                            ),
                          ),
                          const SizedBox(width: 15),
                          DropdownButton<String>(
                            value: _selectedFilter,
                            dropdownColor: Color(0xFF8BF0A8), // Light green background for the dropdown
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF484646), // Text color (dark gray)
                            ),
                            items: _filterOptions.map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (val) {
  if (val != null) {
    Future.delayed(Duration.zero, () {
      if (!mounted) return;
      setState(() {
        _selectedFilter = val;
        if (val == 'Per Hari') {
          yInterval = 2;
          updateAttendanceChartPerHari();
        } else if (val == 'Per Bulan') {
          yInterval = 10;
          updateAttendanceChartPerBulan();
        } else if (val == 'Per Tahun') {
          yInterval = 20; // <-- Ini!
          updateAttendanceChartPerTahun(); // Fungsi baru, penjelasan di bawah
        } else {
          yInterval = 10; // fallback
          _updateAttendanceListByFilter(val);
        }
      });
    });
  }
},


                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      
                      // Attendance chart
                      attendanceList.isNotEmpty
              ? SizedBox(
                  height: 400,
                  child: BarChart(
                    BarChartData(
                      maxY: maxY, // <-- PENTING!
                      barGroups: attendanceList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final data = entry.value;
                        return BarChartGroupData(
                          x: index,
                          barsSpace: 10,
                          barRods: [
                            BarChartRodData(
                              toY: data.hadir.toDouble(),
                              color: Colors.green,
                              width: 16,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            BarChartRodData(
                              toY: data.tidakHadir.toDouble(),
                              color: Colors.redAccent,
                              width: 16,
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ],
                        );
                      }).toList(),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              int intValue = value.toInt();
                              if (intValue > 0 && intValue % yInterval == 0) {
                                return Text(
                                  intValue.toString(),
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                            interval: yInterval,
                          ),
                        ),

                                    bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              int index = value.toInt();
                              if (index >= 0 && index < attendanceList.length) {
                                return Text(
                                  attendanceList[index].label,
                                  style: const TextStyle(fontSize: 12),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(show: true),
                      barTouchData: BarTouchData(enabled: false),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    'Data tidak tersedia',
                    style: TextStyle(fontSize: 18, color: Colors.black.withOpacity(0.6)),
                  ),
                ),
                      const SizedBox(height: 20),

                      // Legend Manual
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.square, color: Colors.green, size: 16),
                          SizedBox(width: 6),
                          Text("Hadir"),
                          SizedBox(width: 20),
                          Icon(Icons.square, color: Colors.redAccent, size: 16),
                          SizedBox(width: 6),
                          Text("Tidak Hadir"),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right Side: Approval Cards
                // Right Side: Approval Cards
                Flexible(
                  flex: 1,
                  child: Container(
                    height: 650,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFF22B04B), // Green background for the entire approval section
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          spreadRadius: 2,
                          blurRadius: 12,
                          offset: Offset(0, 4), // Slight shadow for depth
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pending count with white text color for visibility
                        Text(
                          'PENDING ${getPendingCount()}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // White color for Pending text
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
  child: ListView.builder(
    itemCount: approvalCards.length,
    itemBuilder: (context, index) {
      final card = approvalCards[index];
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Nama: ${card.name}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text("Jumlah Hari: ${card.days}"),
              Text("Jenis: ${card.type}"),
              // FOTO HANYA UNTUK SAKIT
              if (card.type.toLowerCase() == 'sakit' && card.urlLampiran != null && card.urlLampiran!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    height: 80,
                    child: Image.network(
                      card.urlLampiran!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.broken_image, color: Colors.red),
                    ),
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      showDetailPopup(card, index);
                    },
                    child: const Text("Detail"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF22B04B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
   Widget buildStatBox(BuildContext context, {
  required String label,
  required int count,
  required Color color,
  double widthFraction = 0.4,
}) {
  return Container(
    width: MediaQuery.of(context).size.width * widthFraction,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: color, // Solid color for the background (green or red)
      borderRadius: BorderRadius.circular(16), // Rounded corners
    ),
    child: Column(
      children: [
        Text(
          "$count",
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Colors.white, // White text for better contrast
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            color: Colors.white, // White text for better contrast
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}
}
