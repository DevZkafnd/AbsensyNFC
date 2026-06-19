import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  // Style constants (sama dengan HomePage)
  static const double kHeaderFontSize = 22;
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

  // Dummy data
  final List<Map<String, dynamic>> _allData = List.generate(23, (i) {
    final now = DateTime.now().subtract(Duration(days: i));
    final status = i % 5 == 2 ? 'Tidak Hadir' : 'Hadir';
    final keterangan = status == 'Hadir'
        ? (i % 3 == 0 ? 'Tepat Waktu' : 'Telat')
        : (i % 2 == 0 ? 'Alfa' : (i % 4 == 1 ? 'Izin Cuti' : 'Sakit'));
    return {
      'tanggal': DateFormat('dd/MM/yyyy').format(now),
      'tanggalDate': now,
      'waktu': DateFormat('HH:mm').format(now),
      'status': status,
      'keterangan': keterangan,
      'detail': keterangan == 'Izin Cuti' || keterangan == 'Sakit',
      'detailData': keterangan == 'Izin Cuti'
          ? {
              'jumlahHari': 2,
              'keteranganIzin': 'Pulang kampung',
            }
          : keterangan == 'Sakit'
              ? {
                  'namaPenyakit': 'Flu Berat',
                  'jumlahHari': 3,
                  'fotoSurat': null,
                }
              : null,
    };
  });

  // Filter state
  String _statusFilter = 'Semua';
  DateTime? _startDate;
  DateTime? _endDate;

  // Pagination
  int _currentPage = 0;
  static const int _rowsPerPage = 10;

  List<Map<String, dynamic>> get _filteredData {
    return _allData.where((data) {
      // Filter status
      if (_statusFilter != 'Semua' && data['status'] != _statusFilter) {
        return false;
      }
      // Filter tanggal range
      if (_startDate != null && data['tanggalDate'].isBefore(_startDate!)) {
        return false;
      }
      if (_endDate != null && data['tanggalDate'].isAfter(_endDate!)) {
        return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> get _pagedData {
    final filtered = _filteredData;
    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    return filtered.sublist(start, end > filtered.length ? filtered.length : end);
  }

  int get _totalPages => (_filteredData.length / _rowsPerPage).ceil();

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
        _currentPage = 0;
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _currentPage = 0;
      });
    }
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    final isSakit = data['keterangan'] == 'Sakit';
    final isIzinCuti = data['keterangan'] == 'Izin Cuti';
    final detail = data['detailData'] ?? {};
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isSakit ? Icons.sick : Icons.beach_access,
                      color: isSakit ? Colors.redAccent : const Color(0xFF178A3D),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isSakit ? 'Detail Sakit' : 'Detail Izin Cuti',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF178A3D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (isSakit) ...[
                  const Text('Nama Penyakit:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(detail['namaPenyakit'] ?? '-', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 10),
                  const Text('Jumlah Hari:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${detail['jumlahHari'] ?? '-'} hari', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 10),
                  const Text('Foto Surat Sakit:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: detail['fotoSurat'] == null
                        ? const Center(child: Text('Belum ada foto surat sakit'))
                        : Image.network(detail['fotoSurat'], fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 6),
                  const Text('Format: PNG, JPEG, JPG. Maks 5MB.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                ] else if (isIzinCuti) ...[
                  const Text('Jumlah Hari:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('${detail['jumlahHari'] ?? '-'} hari', style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 10),
                  const Text('Keterangan Izin:', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(detail['keteranganIzin'] ?? '-', style: const TextStyle(fontSize: 15)),
                ],
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF178A3D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F3F3),
      body: Column(
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
                'Riwayat Absensi',
                style: TextStyle(
                  fontSize: kHeaderFontSize,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.13),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Filter bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baris 1: Status filter
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _statusFilter,
                              items: const [
                                DropdownMenuItem(value: 'Semua', child: Text('Semua')),
                                DropdownMenuItem(value: 'Hadir', child: Text('Hadir')),
                                DropdownMenuItem(value: 'Tidak Hadir', child: Text('Tidak Hadir')),
                              ],
                              onChanged: (val) {
                                setState(() {
                                  _statusFilter = val!;
                                  _currentPage = 0;
                                });
                              },
                              style: const TextStyle(fontSize: 15, color: Colors.black87),
                              borderRadius: BorderRadius.circular(12),
                              dropdownColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Date range button
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF178A3D),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            ),
                            onPressed: () async {
                              final picked = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                                initialDateRange: _startDate != null && _endDate != null
                                    ? DateTimeRange(start: _startDate!, end: _endDate!)
                                    : null,
                              );
                              if (picked != null) {
                                setState(() {
                                  _startDate = picked.start;
                                  _endDate = picked.end;
                                  _currentPage = 0;
                                });
                              }
                            },
                            icon: const Icon(Icons.date_range, size: 18),
                            label: Text(
                              (_startDate == null || _endDate == null)
                                  ? 'Pilih Rentang Tanggal'
                                  : '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                        if (_startDate != null || _endDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear),
                            tooltip: 'Reset tanggal',
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                                _currentPage = 0;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Card tabel riwayat
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
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
                        'Tabel Riwayat Absensi',
                        style: TextStyle(
                          fontSize: kCardTitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF178A3D),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Expanded(
                        child: _filteredData.isEmpty
                            ? const Center(
                                child: Text(
                                  'Belum ada riwayat absensi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black54,
                                  ),
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('Tanggal')),
                                    DataColumn(label: Text('Waktu')),
                                    DataColumn(label: Text('Status')),
                                    DataColumn(label: Text('Keterangan')),
                                    DataColumn(label: Text('')),
                                  ],
                                  rows: _pagedData.map((data) {
                                    return DataRow(
                                      cells: [
                                        DataCell(Text(
                                          data['tanggal'],
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        )),
                                        DataCell(Text(data['waktu'])),
                                        DataCell(Row(
                                          children: [
                                            Icon(
                                              data['status'] == 'Hadir'
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color: data['status'] == 'Hadir'
                                                  ? const Color(0xFF178A3D)
                                                  : Colors.redAccent,
                                              size: kStatusIconSize,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              data['status'],
                                              style: TextStyle(
                                                color: data['status'] == 'Hadir'
                                                    ? const Color(0xFF178A3D)
                                                    : Colors.redAccent,
                                                fontWeight: FontWeight.w600,
                                                fontSize: kStatusFontSize,
                                              ),
                                            ),
                                          ],
                                        )),
                                        DataCell(Text(data['keterangan'])),
                                        DataCell(
                                          data['detail']
                                              ? ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(0xFF4ADE80),
                                                    foregroundColor: Colors.white,
                                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    _showDetailDialog(data);
                                                  },
                                                  child: const Text('Lebih Detail'),
                                                )
                                              : const SizedBox.shrink(),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                      ),
                      // Pagination
                      if (_filteredData.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: _currentPage > 0
                                    ? () => setState(() => _currentPage--)
                                    : null,
                                child: Icon(
                                  Icons.chevron_left,
                                  size: 28,
                                  color: _currentPage > 0 ? const Color(0xFF178A3D) : Colors.grey[400],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Halaman ${_currentPage + 1} / ${_totalPages == 0 ? 1 : _totalPages}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF178A3D),
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _currentPage < _totalPages - 1
                                    ? () => setState(() => _currentPage++)
                                    : null,
                                child: Icon(
                                  Icons.chevron_right,
                                  size: 28,
                                  color: _currentPage < _totalPages - 1 ? const Color(0xFF178A3D) : Colors.grey[400],
                                ),
                              ),
                            ],
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
} 