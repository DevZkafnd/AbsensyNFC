import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Konstanta untuk magic number
  static const double kHeaderFontSize = 22;
  static const double kUserFontSize = 28;
  static const double kCardTitleFontSize = 20;
  static const double kCardPaddingHorizontal = 22;
  static const double kCardPaddingVertical = 28;
  static const double kCardBorderRadius = 28;
  static const double kCardElevation = 4;
  static const double kStatusIconSize = 22;
  static const double kStatusFontSize = 15;
  static const double kStatusContainerPaddingH = 12;
  static const double kStatusContainerPaddingV = 5;
  static const double kStatusBorderRadius = 14;
  static const double kAbsensiRowFontSize = 16;

  late final Stream<List<Map<String, dynamic>>> _lastAbsensiStream;
  late final Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _lastAbsensiStream = _getLastAbsensiStream();
    _userNameFuture = _getUserName();
  }

  DateTime? _parseFirestoreDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.isUtc ? value.toLocal() : value;
    if (value is Timestamp) {
      final dt = value.toDate();
      return dt.isUtc ? dt.toLocal() : dt;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      final dt = DateTime.tryParse(value);
      if (dt == null) return null;
      return dt.isUtc ? dt.toLocal() : dt;
    }
    return null;
  }

  bool _isMissingIndexError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('failed-precondition') && msg.contains('requires an index') ||
        msg.contains('requires an index') ||
        msg.contains('no matching index') ||
        msg.contains('missing index');
  }

  Stream<List<QueryDocumentSnapshot>> _queryDocsSmart({
    required String collection,
    required String field,
    required dynamic value,
    required String orderByField,
    required int orderedLimit,
    required int fallbackLimit,
  }) {
    final base = FirebaseFirestore.instance.collection(collection).where(field, isEqualTo: value);

    final ordered = base
        .orderBy(orderByField, descending: true)
        .limit(orderedLimit)
        .snapshots()
        .map((snap) => snap.docs);

    final fallback = base.limit(fallbackLimit).snapshots().map((snap) => snap.docs);

    return ordered.onErrorResume((error, stackTrace) {
      if (_isMissingIndexError(error)) return fallback;
      return Stream.error(error, stackTrace);
    });
  }

  List<QueryDocumentSnapshot> _mergeManyDocLists(List<List<QueryDocumentSnapshot>> lists) {
    final seen = <String>{};
    final out = <QueryDocumentSnapshot>[];
    for (final list in lists) {
      for (final doc in list) {
        final key = doc.reference.path;
        if (seen.add(key)) out.add(doc);
      }
    }
    return out;
  }

  Stream<List<Map<String, dynamic>>> _getLastAbsensiStream() {
    final prefsFuture = SharedPreferences.getInstance();
    return Stream.fromFuture(prefsFuture).switchMap((prefs) {
      final userIdStr = prefs.getString('logged_in_user_id');
      if (userIdStr == null) return Stream.value([]);
      final userIdInt = int.tryParse(userIdStr);

      // Fetch user profile to get registration date (created_at)
      final userStream = userIdInt == null
          ? Stream.value(null)
          : FirebaseFirestore.instance
              .collection('users')
              .where('id', isEqualTo: userIdInt)
              .limit(1)
              .snapshots();

      return userStream.switchMap((userSnap) {
        DateTime? joinDate;
        if (userSnap != null && userSnap.docs.isNotEmpty) {
          final userData = userSnap.docs.first.data();
          // Assume 'created_at' exists, if not use a very old date
          joinDate = (userData['created_at'] as Timestamp?)?.toDate();
          final now = DateTime.now();
          if (joinDate != null && joinDate.isAfter(now.add(const Duration(minutes: 5)))) {
            joinDate = null;
          }
        }

        final absensiSources = <Stream<List<QueryDocumentSnapshot>>>[
          _queryDocsSmart(
            collection: 'absensi',
            field: 'user_id',
            value: userIdStr,
            orderByField: 'in_time',
            orderedLimit: 20,
            fallbackLimit: 200,
          ),
          _queryDocsSmart(
            collection: 'absensi',
            field: 'id_user',
            value: userIdStr,
            orderByField: 'in_time',
            orderedLimit: 20,
            fallbackLimit: 200,
          ),
        ];
        if (userIdInt != null) {
          absensiSources.addAll([
            _queryDocsSmart(
              collection: 'absensi',
              field: 'user_id',
              value: userIdInt,
              orderByField: 'in_time',
              orderedLimit: 20,
              fallbackLimit: 200,
            ),
            _queryDocsSmart(
              collection: 'absensi',
              field: 'id_user',
              value: userIdInt,
              orderByField: 'in_time',
              orderedLimit: 20,
              fallbackLimit: 200,
            ),
          ]);
        }
        final absensiDocsStream = CombineLatestStream.list(absensiSources).map(_mergeManyDocLists);

        final perizinanSources = <Stream<List<QueryDocumentSnapshot>>>[
          _queryDocsSmart(
            collection: 'perizinan',
            field: 'user_id',
            value: userIdStr,
            orderByField: 'start_date',
            orderedLimit: 20,
            fallbackLimit: 200,
          ),
        ];
        if (userIdInt != null) {
          perizinanSources.add(
            _queryDocsSmart(
              collection: 'perizinan',
              field: 'user_id',
              value: userIdInt,
              orderByField: 'start_date',
              orderedLimit: 20,
              fallbackLimit: 200,
            ),
          );
        }
        final perizinanDocsStream = CombineLatestStream.list(perizinanSources).map(_mergeManyDocLists);

        return CombineLatestStream.combine2(
          absensiDocsStream,
          perizinanDocsStream,
          (List<QueryDocumentSnapshot> absensiDocs, List<QueryDocumentSnapshot> perizinanDocs) {
            final absensiList = <Map<String, dynamic>>[];
            for (final doc in absensiDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final tanggal = _parseFirestoreDate(
                data['in_time'] ?? data['created_at'] ?? data['createdAt'] ?? data['tanggal'] ?? data['time'],
              );
              if (tanggal == null) continue;
              absensiList.add({
                'tanggal': tanggal,
                'status': (data['keterangan'] ?? '').toString().toLowerCase() == 'hadir' ? 'hadir' : 'tidak hadir',
                'keterangan': data['keterangan'] ?? '-',
                'tipe': 'absensi',
              });
            }

            final izinList = <Map<String, dynamic>>[];
            for (final doc in perizinanDocs) {
              final data = doc.data() as Map<String, dynamic>;
              final tanggal = _parseFirestoreDate(data['start_date'] ?? data['created_at'] ?? data['createdAt']);
              if (tanggal == null) continue;
              final rawStatus = (data['status'] ?? '').toString().toLowerCase();
              final status = rawStatus == 'approved'
                  ? 'disetujui'
                  : rawStatus == 'rejected'
                      ? 'ditolak'
                      : rawStatus == 'pending'
                          ? 'pending'
                          : (rawStatus.isEmpty ? 'pending' : rawStatus);
              izinList.add({
                'tanggal': tanggal,
                'status': status,
                'keterangan': status == 'ditolak'
                    ? 'Ditolak'
                    : status == 'disetujui'
                        ? 'Disetujui'
                        : 'Menunggu',
                'tipe': 'perizinan',
              });
            }

            final combined = [...absensiList, ...izinList];

            // Filter out records before the user was created
            final filtered = joinDate != null
                ? combined.where((item) {
                    final itemDate = item['tanggal'] as DateTime;
                    // Give 1 minute buffer for records created exactly at join time
                    return itemDate.isAfter(joinDate!.subtract(const Duration(minutes: 1)));
                  }).toList()
                : combined;

            filtered.sort((a, b) => b['tanggal'].compareTo(a['tanggal']));
            return filtered.take(5).toList();
          },
        );
      });
    });
  }

  Future<String> _getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('logged_in_user_id');
    if (userIdStr == null) return '-';
    final userIdInt = int.tryParse(userIdStr);
    final query = FirebaseFirestore.instance.collection('users').where('id', isEqualTo: userIdInt ?? userIdStr).limit(1);
    final snap = await query.get();
    if (snap.docs.isEmpty) return '-';
    return snap.docs.first.data()['fullname'] ?? '-';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient dengan welcome
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
              child: Column(
                children: [
                  const Text(
                    'Selamat datang,',
                    style: TextStyle(
                      fontSize: kHeaderFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<String>(
                    future: _userNameFuture,
                    builder: (context, snapshot) {
                      final name = snapshot.data ?? '-';
                      return Text(
                        name,
                        style: TextStyle(
                          fontSize: kUserFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withAlpha(46),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            // SVG dekoratif di tengah
            Padding(
              padding: const EdgeInsets.only(top: 16, bottom: 8),
              child: Image.asset(
                'assets/images/checklist-1-18.png',
                height: 200,
                width: 200,
                fit: BoxFit.contain,
              ),
            ),
            // Card absensi
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8,
              ),
              child: Card(
                elevation: kCardElevation,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(kCardBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kCardPaddingHorizontal,
                    vertical: kCardPaddingVertical,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Absensi Terakhir',
                        style: TextStyle(
                          fontSize: kCardTitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF178A3D),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _lastAbsensiStream,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  'Gagal memuat data absensi: ${snapshot.error}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: Colors.red),
                                ),
                              ),
                            );
                          }
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Text(
                                  'Belum ada data absensi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            );
                          }
                          final absensiList = snapshot.data!;
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: absensiList.length,
                            separatorBuilder: (context, idx) => Divider(height: 1, color: Colors.grey[200]),
                            itemBuilder: (context, idx) {
                              final data = absensiList[idx];
                              final tanggal = data['tanggal'] as DateTime;
                              final status = data['status'];
                              Color statusColor;
                              IconData statusIcon;
                              if (status == 'hadir') {
                                statusColor = const Color(0xFF178A3D);
                                statusIcon = Icons.check_circle;
                              } else if (status == 'disetujui') {
                                statusColor = const Color(0xFF178A3D);
                                statusIcon = Icons.check_circle;
                              } else if (status == 'pending') {
                                statusColor = Colors.amber;
                                statusIcon = Icons.hourglass_empty;
                              } else {
                                statusColor = Colors.redAccent;
                                statusIcon = Icons.cancel;
                              }
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        DateFormat('dd/MM/yyyy').format(tanggal),
                                        style: const TextStyle(
                                          fontSize: kAbsensiRowFontSize,
                                          color: Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          Semantics(
                                            label: status == 'hadir'
                                                ? 'Status hadir'
                                                : status == 'disetujui'
                                                    ? 'Status disetujui'
                                                    : status == 'ditolak'
                                                        ? 'Status ditolak'
                                                        : status == 'pending'
                                                            ? 'Status pending'
                                                            : 'Status tidak hadir',
                                            child: Icon(
                                              statusIcon,
                                              color: statusColor,
                                              size: kStatusIconSize,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: kStatusContainerPaddingH,
                                              vertical: kStatusContainerPaddingV,
                                            ),
                                            decoration: BoxDecoration(
                                              color: statusColor.withAlpha(46),
                                              borderRadius: BorderRadius.circular(kStatusBorderRadius),
                                            ),
                                            child: Text(
                                              data['keterangan'] ?? '-',
                                              style: TextStyle(
                                                color: statusColor,
                                                fontWeight: FontWeight.w600,
                                                fontSize: kStatusFontSize,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
