import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:supabase_flutter/supabase_flutter.dart'; // We'll use Cloudinary instead

class FormIzinPage extends StatefulWidget {
  const FormIzinPage({super.key});

  @override
  State<FormIzinPage> createState() => _FormIzinPageState();
}

class _FormIzinPageState extends State<FormIzinPage> {
  static const int _maxIzinPerYear = 10;

  String _izinType = 'Sakit';
  final TextEditingController _namaPenyakitController = TextEditingController();
  final TextEditingController _jumlahHariController = TextEditingController();
  final TextEditingController _keteranganIzinController = TextEditingController();
  File? _fotoSurat;
  String? _fotoError;
  bool _isSubmitting = false;
  dynamic _currentUserId;
  Future<int>? _usedQuotaFuture;

  @override
  void initState() {
    super.initState();
    _usedQuotaFuture = _loadUsedQuota();
  }

  void _setFotoError(String? message) {
    if (!mounted) return;
    setState(() {
      _fotoError = message;
    });
  }

  Future<int> _loadUsedQuota() async {
    final userData = await _getUserData();
    final userId = userData?['id'];
    _currentUserId = userId;
    if (userId == null) return 0;
    return _countPerizinanSakitCutiThisYear(userId);
  }

  void _refreshQuota() {
    final userId = _currentUserId;
    setState(() {
      _usedQuotaFuture = userId == null ? _loadUsedQuota() : _countPerizinanSakitCutiThisYear(userId);
    });
  }

  String _basename(String path) {
    final sep = Platform.pathSeparator;
    if (path.contains(sep)) return path.split(sep).last;
    return path.split('/').last;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final file = File(picked.path);
      final bytes = await file.length();
      if (bytes > 5 * 1024 * 1024) {
        setState(() {
          _fotoError = 'Ukuran file maksimal 5MB';
          _fotoSurat = null;
        });
        return;
      }
      final ext = picked.path.split('.').last.toLowerCase();
      if (!(ext == 'png' || ext == 'jpg' || ext == 'jpeg')) {
        setState(() {
          _fotoError = 'Format harus PNG, JPEG, atau JPG';
          _fotoSurat = null;
        });
        return;
      }
      setState(() {
        _fotoSurat = file;
        _fotoError = null;
      });
    }
  }

  Future<String?> _uploadFileToCloudinary(File file) async {
    try {
      const cloudName = 'dkv4vulop';
      const uploadPreset = 'izin_absen_preset';
      
      var uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");
      var request = http.MultipartRequest("POST", uri);
      
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'absensy/perizinan';
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      var response = await request.send().timeout(const Duration(seconds: 45));
      
      if (response.statusCode == 200) {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        var jsonMap = jsonDecode(responseString);
        
        String imageUrl = jsonMap['secure_url']; // Ini adalah URL gambarmu!
        return imageUrl;
      } else {
        var responseData = await response.stream.toBytes();
        var responseString = String.fromCharCodes(responseData);
        String message = 'Gagal upload ke Cloudinary (${response.statusCode})';
        try {
          final decoded = jsonDecode(responseString);
          final err = decoded is Map ? decoded['error'] : null;
          final errMsg = err is Map ? err['message'] : null;
          if (errMsg != null && errMsg.toString().trim().isNotEmpty) {
            message = '$message: ${errMsg.toString()}';
          }
        } catch (_) {}
        _setFotoError(message);
        return null;
      }
    } on TimeoutException {
      _setFotoError('Upload timeout. Coba lagi atau cek koneksi internet.');
      return null;
    } on SocketException catch (e) {
      _setFotoError('Gagal terhubung ke internet: ${e.message}');
      return null;
    } catch (e) {
      _setFotoError('Gagal upload file ke Cloudinary: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userIdStr = prefs.getString('logged_in_user_id');
    if (userIdStr == null) return null;
    final userId = int.parse(userIdStr);
    final snap = await FirebaseFirestore.instance.collection('users').where('id', isEqualTo: userId).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
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

  Future<int> _countPerizinanSakitCutiThisYear(dynamic userId) async {
    final year = DateTime.now().year;
    final queries = <Query>[
      FirebaseFirestore.instance.collection('perizinan').where('user_id', isEqualTo: userId),
    ];
    if (userId is int) {
      queries.add(FirebaseFirestore.instance.collection('perizinan').where('user_id', isEqualTo: userId.toString()));
    } else if (userId is String) {
      final asInt = int.tryParse(userId);
      if (asInt != null) {
        queries.add(FirebaseFirestore.instance.collection('perizinan').where('user_id', isEqualTo: asInt));
      }
    }

    final seen = <String>{};
    final allDocs = <QueryDocumentSnapshot>[];
    for (final q in queries) {
      final snap = await q.limit(1000).get();
      for (final doc in snap.docs) {
        final key = doc.reference.path;
        if (seen.add(key)) allDocs.add(doc);
      }
    }

    const allowedTypes = {'sakit', 'izin cuti'};
    var count = 0;
    for (final doc in allDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final tipe = (data['tipe'] ?? '').toString().toLowerCase();
      if (!allowedTypes.contains(tipe)) continue;
      final tanggal = _parseFirestoreDate(data['start_date'] ?? data['created_at'] ?? data['createdAt']);
      if (tanggal == null) continue;
      if (tanggal.year != year) continue;
      count++;
    }
    return count;
  }

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    setState(() {
      _fotoError = null;
      _isSubmitting = true;
    });
    debugPrint('Submit form pressed');
    try {
      if (_izinType == 'Sakit' && (_namaPenyakitController.text.isEmpty || _fotoSurat == null)) {
        debugPrint('Validasi gagal: field sakit belum lengkap');
        _setFotoError('Lengkapi semua field dan upload surat sakit.');
        return;
      }
      if (_izinType == 'Izin Cuti' && (_keteranganIzinController.text.isEmpty || _jumlahHariController.text.isEmpty)) {
        debugPrint('Validasi gagal: field izin cuti belum lengkap');
        _setFotoError('Lengkapi semua field izin cuti.');
        return;
      }
      if (_jumlahHariController.text.isEmpty || int.tryParse(_jumlahHariController.text) == null) {
        debugPrint('Validasi gagal: jumlah hari tidak valid');
        _setFotoError('Jumlah hari harus diisi dan berupa angka.');
        return;
      }

      final userData = await _getUserData();
      debugPrint('User data: ${userData?.toString() ?? 'null'}');
      if (userData == null) {
        _setFotoError('User tidak ditemukan.');
        return;
      }

      final userId = userData['id'];
      final username = userData['Username'] ?? '-';
      _currentUserId = userId;

      final usedQuota = await _countPerizinanSakitCutiThisYear(userId);
      if (usedQuota >= _maxIzinPerYear) {
        _setFotoError('Batas pengajuan izin sakit/cuti tahun ini sudah tercapai (${_maxIzinPerYear}x).');
        return;
      }

      String? urlLampiran;
      if (_izinType == 'Sakit' && _fotoSurat != null) {
        debugPrint('Mulai upload file ke Cloudinary...');
        urlLampiran = await _uploadFileToCloudinary(_fotoSurat!);
        debugPrint('URL lampiran Cloudinary: $urlLampiran');
        if (urlLampiran == null) return;
      }

      final now = DateTime.now();
      final jumlahHari = int.parse(_jumlahHariController.text);
      final startDate = now;
      final endDate = now.add(Duration(days: jumlahHari - 1));
      final data = <String, dynamic>{
        'user_id': userId,
        'tipe': _izinType.toLowerCase(),
        'start_date': startDate,
        'end_date': endDate,
        'status': 'pending',
        'username': username,
        'waktu': jumlahHari,
      };
      if (_izinType == 'Sakit') {
        data['nama_penyakit'] = _namaPenyakitController.text;
        data['url_lampiran'] = urlLampiran;
      } else if (_izinType == 'Izin Cuti') {
        data['keterangan'] = _keteranganIzinController.text;
      }
      debugPrint('Data yang akan dikirim: $data');

      await FirebaseFirestore.instance.collection('perizinan').add(data);
      debugPrint('Data berhasil dikirim ke Firestore!');
      if (!mounted) return;
      setState(() {
        _fotoSurat = null;
        _fotoError = null;
        _namaPenyakitController.clear();
        _jumlahHariController.clear();
        _keteranganIzinController.clear();
        _usedQuotaFuture = _countPerizinanSakitCutiThisYear(userId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Form izin berhasil disubmit!')),
      );
    } catch (e) {
      debugPrint('Gagal mengirim data: $e');
      _setFotoError('Gagal mengirim data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _namaPenyakitController.dispose();
    _jumlahHariController.dispose();
    _keteranganIzinController.dispose();
    super.dispose();
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
                  'Form Izin',
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder<int>(
                        future: _usedQuotaFuture,
                        builder: (context, snapshot) {
                          final year = DateTime.now().year;
                          final used = snapshot.data ?? 0;
                          final remaining = (_maxIzinPerYear - used).clamp(0, _maxIzinPerYear);
                          return InkWell(
                            onTap: _refreshQuota,
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF178A3D).withAlpha(18),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFF178A3D).withAlpha(70)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.confirmation_number, color: Color(0xFF178A3D)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      snapshot.connectionState == ConnectionState.waiting
                                          ? 'Kuota izin $year: memuat...'
                                          : 'Sisa kuota izin $year: $remaining/$_maxIzinPerYear',
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  const Icon(Icons.refresh, color: Color(0xFF178A3D)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Jenis Izin',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<String>(
                        value: _izinType,
                        items: const [
                          DropdownMenuItem(value: 'Sakit', child: Text('Sakit')),
                          DropdownMenuItem(value: 'Izin Cuti', child: Text('Izin Cuti')),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _izinType = val!;
                            _namaPenyakitController.clear();
                            _jumlahHariController.clear();
                            _keteranganIzinController.clear();
                            _fotoSurat = null;
                            _fotoError = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(12),
                      ),
                      const SizedBox(height: 18),
                      if (_izinType == 'Sakit') ...[
                        const Text('Nama Penyakit', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _namaPenyakitController,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan nama penyakit',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const Text('Jumlah Hari', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _jumlahHariController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan jumlah hari',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (_izinType == 'Sakit') ...[
                        const Text('Foto Surat Sakit', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload Foto'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF178A3D),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            if (_fotoSurat != null)
                              Expanded(
                                child: Text(
                                  _basename(_fotoSurat!.path),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        if (_fotoError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(_fotoError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                          ),
                        if (_fotoSurat != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_fotoSurat!, height: 120),
                            ),
                          ),
                        const SizedBox(height: 6),
                        const Text('Format: PNG, JPEG, JPG. Maks 5MB.', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        const SizedBox(height: 14),
                      ],
                      if (_izinType == 'Izin Cuti') ...[
                        const Text('Keterangan Izin', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _keteranganIzinController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            hintText: 'Masukkan keterangan izin',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF178A3D),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isSubmitting ? null : _submitForm,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Kirim Izin'),
                        ),
                      ),
                    ],
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
