import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rxdart/rxdart.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  static const double kHeaderFontSize = 22;
  static const double kCardTitleFontSize = 20;
  static const double kCardPaddingHorizontal = 22;
  static const double kCardPaddingVertical = 28;
  static const double kCardBorderRadius = 28;
  static const double kCardElevation = 4;

  String _statusFilter = 'Semua';
  DateTime? _startDate;
  DateTime? _endDate;
  late final Stream<List<Map<String, dynamic>>> _combinedRiwayatStream;

  @override
  void initState() {
    super.initState();
    _combinedRiwayatStream = _getCombinedRiwayatStream().shareReplay(maxSize: 1);
  }

  DateTime? _parseFirestoreDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.isUtc ? value.toLocal() : value;
    if (value is Timestamp) {
      final dt = value.toDate();
      return dt.isUtc ? dt.toLocal() : dt;
    }
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
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

  String _statusLabel(String status) {
    switch (status) {
      case 'hadir':
        return 'Hadir';
      case 'tidak hadir':
        return 'Tidak Hadir';
      case 'pending':
        return 'Pending';
      case 'disetujui':
        return 'Disetujui';
      case 'ditolak':
        return 'Ditolak';
      default:
        return status.capitalize();
    }
  }

  Stream<List<QueryDocumentSnapshot>> _queryDocsSmart({
    required String collection,
    required String field,
    required dynamic value,
    required String orderByField,
    required int fallbackLimit,
  }) {
    final base = FirebaseFirestore.instance.collection(collection).where(field, isEqualTo: value);

    final ordered = base
        .orderBy(orderByField, descending: true)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
        children: [
          // Header
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
            child: const Center(
              child: Text(
                'Riwayat Absensi',
                style: TextStyle(
                  fontSize: kHeaderFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ),
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Dropdown Status
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          items: const [
                            DropdownMenuItem(
                              value: 'Semua',
                              child: Text('Semua'),
                            ),
                            DropdownMenuItem(
                              value: 'Hadir',
                              child: Text('Hadir'),
                            ),
                            DropdownMenuItem(
                              value: 'Tidak Hadir',
                              child: Text('Tidak Hadir'),
                            ),
                            DropdownMenuItem(
                              value: 'Pending',
                              child: Text('Pending'),
                            ),
                            DropdownMenuItem(
                              value: 'Disetujui',
                              child: Text('Disetujui'),
                            ),
                            DropdownMenuItem(
                              value: 'Ditolak',
                              child: Text('Ditolak'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() {
                              _statusFilter = val!;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Date Range Picker
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF178A3D),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          initialDateRange:
                              _startDate != null && _endDate != null
                              ? DateTimeRange(
                                  start: _startDate!,
                                  end: _endDate!,
                                )
                              : null,
                        );
                        if (picked != null) {
                          setState(() {
                            _startDate = picked.start;
                            _endDate = picked.end;
                          });
                        }
                      },
                      icon: const Icon(Icons.date_range),
                      label: Text(
                        (_startDate == null || _endDate == null)
                            ? 'Pilih Rentang Tanggal'
                            : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                      ),
                    ),
                    if (_startDate != null || _endDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _startDate = null;
                            _endDate = null;
                          });
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
          // Riwayat list
          Expanded(
            child: Padding(
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
                        'Riwayat Absensi',
                        style: TextStyle(
                          fontSize: kCardTitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF178A3D),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: _combinedRiwayatStream,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                                  child: Text(
                                    'Gagal memuat riwayat: ${snapshot.error}',
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
                                    'Belum ada data riwayat',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }
                            final riwayatList = snapshot.data!;
                            // Filter status dan tanggal
                            final filtered = riwayatList.where((data) {
                              final statusFilter = _statusFilter.toLowerCase();
                              final tanggal = data['tanggal'] as DateTime;
                              final status = (data['status'] ?? '').toString().toLowerCase();
                              if (statusFilter != 'semua') {
                                if (status != statusFilter) return false;
                              }
                              if (_startDate != null) {
                                final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day);
                                if (tanggal.isBefore(start)) return false;
                              }
                              if (_endDate != null) {
                                final end = DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59, 999);
                                if (tanggal.isAfter(end)) return false;
                              }
                              return true;
                            }).toList();
                            if (filtered.isEmpty) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24.0),
                                  child: Text(
                                    'Tidak ada data sesuai filter saat ini',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              );
                            }
                            filtered.sort((a, b) => (b['tanggal'] as DateTime).compareTo(a['tanggal'] as DateTime));
                            return ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (context, idx) => Divider(height: 1, color: Colors.grey[200]),
                              itemBuilder: (context, idx) {
                                final data = filtered[idx];
                                final tanggal = data['tanggal'] as DateTime;
                                final status = (data['status'] ?? '').toString().toLowerCase();
                                final tipe = (data['tipe'] ?? '').toString().toLowerCase();
                                final keterangan = (data['keterangan'] ?? '-').toString();

                                Color statusColor;
                                IconData statusIcon;
                                if (status == 'hadir' || status == 'disetujui') {
                                  statusColor = const Color(0xFF178A3D);
                                  statusIcon = Icons.check_circle;
                                } else if (status == 'pending') {
                                  statusColor = Colors.amber;
                                  statusIcon = Icons.hourglass_empty;
                                } else if (status == 'ditolak') {
                                  statusColor = Colors.red;
                                  statusIcon = Icons.cancel;
                                } else if (status == 'tidak hadir') {
                                  statusColor = Colors.redAccent;
                                  statusIcon = Icons.cancel;
                                } else {
                                  statusColor = Colors.blueGrey;
                                  statusIcon = Icons.info;
                                }

                                final detail = (data['detail'] is Map<String, dynamic>) ? (data['detail'] as Map<String, dynamic>) : <String, dynamic>{};
                                final izinTipe = (detail['tipe'] ?? '').toString();
                                final jumlahHari = detail['waktu']?.toString() ?? '-';
                                final startDate = _parseFirestoreDate(detail['start_date']);
                                final endDate = _parseFirestoreDate(detail['end_date']);
                                final lampiranUrl = (detail['url_lampiran'] ?? '').toString();
                                final namaPenyakit = (detail['nama_penyakit'] ?? '-').toString();
                                final keteranganIzin = (detail['keterangan'] ?? '-').toString();

                                return ExpansionTile(
                                  tilePadding: const EdgeInsets.symmetric(horizontal: 0),
                                  childrenPadding: const EdgeInsets.only(top: 8, bottom: 12),
                                  title: Text(
                                    DateFormat('dd/MM/yyyy').format(tanggal),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: statusColor.withAlpha(28),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: statusColor.withAlpha(90)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(statusIcon, color: statusColor, size: 18),
                                        const SizedBox(width: 6),
                                        Text(
                                          _statusLabel(status),
                                          style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  children: [
                                    if (tipe == 'absensi') ...[
                                      Row(
                                        children: [
                                          const SizedBox(width: 2),
                                          const Icon(Icons.access_time, size: 18, color: Colors.black54),
                                          const SizedBox(width: 8),
                                          Text(DateFormat('HH:mm').format(tanggal)),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(width: 2),
                                          const Icon(Icons.notes, size: 18, color: Colors.black54),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(keterangan)),
                                        ],
                                      ),
                                    ] else if (tipe == 'perizinan') ...[
                                      Row(
                                        children: [
                                          const SizedBox(width: 2),
                                          const Icon(Icons.assignment, size: 18, color: Colors.black54),
                                          const SizedBox(width: 8),
                                          Text('Tipe: ${izinTipe.isEmpty ? '-' : izinTipe}'),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          const SizedBox(width: 2),
                                          const Icon(Icons.timelapse, size: 18, color: Colors.black54),
                                          const SizedBox(width: 8),
                                          Text('Jumlah Hari: $jumlahHari'),
                                        ],
                                      ),
                                      if (startDate != null || endDate != null) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const SizedBox(width: 2),
                                            const Icon(Icons.date_range, size: 18, color: Colors.black54),
                                            const SizedBox(width: 8),
                                            Text(
                                              '${startDate != null ? DateFormat('dd/MM/yyyy').format(startDate) : '-'}'
                                              ' - '
                                              '${endDate != null ? DateFormat('dd/MM/yyyy').format(endDate) : '-'}',
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (izinTipe.toLowerCase() == 'sakit') ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(width: 2),
                                            const Icon(Icons.sick, size: 18, color: Colors.black54),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Nama Penyakit: $namaPenyakit')),
                                          ],
                                        ),
                                      ],
                                      if (izinTipe.toLowerCase() == 'izin cuti') ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(width: 2),
                                            const Icon(Icons.subject, size: 18, color: Colors.black54),
                                            const SizedBox(width: 8),
                                            Expanded(child: Text('Keterangan: $keteranganIzin')),
                                          ],
                                        ),
                                      ],
                                      if (lampiranUrl.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            lampiranUrl,
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) => const Padding(
                                              padding: EdgeInsets.symmetric(vertical: 8),
                                              child: Text('Gagal memuat gambar'),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getCombinedRiwayatStream() {
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
          joinDate = _parseFirestoreDate(userData['created_at']);
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
            fallbackLimit: 500,
          ),
          _queryDocsSmart(
            collection: 'absensi',
            field: 'id_user',
            value: userIdStr,
            orderByField: 'in_time',
            fallbackLimit: 500,
          ),
        ];
        if (userIdInt != null) {
          absensiSources.addAll([
            _queryDocsSmart(
              collection: 'absensi',
              field: 'user_id',
              value: userIdInt,
              orderByField: 'in_time',
              fallbackLimit: 500,
            ),
            _queryDocsSmart(
              collection: 'absensi',
              field: 'id_user',
              value: userIdInt,
              orderByField: 'in_time',
              fallbackLimit: 500,
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
            fallbackLimit: 500,
          ),
        ];
        if (userIdInt != null) {
          perizinanSources.add(
            _queryDocsSmart(
              collection: 'perizinan',
              field: 'user_id',
              value: userIdInt,
              orderByField: 'start_date',
              fallbackLimit: 500,
            ),
          );
        }
        final perizinanDocsStream = CombineLatestStream.list(perizinanSources).map(_mergeManyDocLists);

        return CombineLatestStream.combine2(
          absensiDocsStream,
          perizinanDocsStream,
          (List<QueryDocumentSnapshot> absensiDocs, List<QueryDocumentSnapshot> perizinanDocs) {
            final absensiList = absensiDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final keterangan = (data['keterangan'] ?? '').toString().toLowerCase();
              return {
                'tanggal': _parseFirestoreDate(
                      data['in_time'] ?? data['created_at'] ?? data['createdAt'] ?? data['tanggal'] ?? data['time'],
                    ) ??
                    DateTime.fromMillisecondsSinceEpoch(0),
                'status': keterangan == 'hadir' ? 'hadir' : 'tidak hadir',
                'keterangan': data['keterangan'] ?? '-',
                'tipe': 'absensi',
              };
            }).where((e) => (e['tanggal'] as DateTime).millisecondsSinceEpoch != 0).toList();

            final izinList = perizinanDocs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final tipe = (data['tipe'] ?? '').toString().toLowerCase();
              final rawStatus = (data['status'] ?? '').toString().toLowerCase();
              final status = rawStatus == 'approved'
                  ? 'disetujui'
                  : rawStatus == 'rejected'
                      ? 'ditolak'
                      : rawStatus == 'pending'
                          ? 'pending'
                          : (rawStatus.isEmpty ? 'pending' : rawStatus);
              String keterangan;
              if (status == 'pending') {
                keterangan = 'Menunggu persetujuan';
              } else if (status == 'disetujui') {
                keterangan = 'Disetujui';
              } else if (status == 'ditolak') {
                keterangan = 'Ditolak';
              } else {
                keterangan = tipe.isEmpty ? '-' : tipe;
              }
              return {
                'tanggal': _parseFirestoreDate(data['start_date'] ?? data['created_at'] ?? data['createdAt']) ??
                    DateTime.fromMillisecondsSinceEpoch(0),
                'status': status,
                'keterangan': keterangan,
                'tipe': 'perizinan',
                'detail': data,
              };
            }).where((e) => (e['tanggal'] as DateTime).millisecondsSinceEpoch != 0).toList();

            final combined = [...absensiList, ...izinList];

            // Filter out records before the user was created
            final filtered = joinDate != null
                ? combined.where((item) {
                    final itemDate = item['tanggal'] as DateTime;
                    return itemDate.isAfter(joinDate!.subtract(const Duration(minutes: 1)));
                  }).toList()
                : combined;

            filtered.sort((a, b) => b['tanggal'].compareTo(a['tanggal']));
            return filtered;
          },
        );
      }).onErrorReturn([]);
    });
  }
}

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}
