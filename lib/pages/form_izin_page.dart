import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FormIzinPage extends StatefulWidget {
  const FormIzinPage({super.key});

  @override
  State<FormIzinPage> createState() => _FormIzinPageState();
}

class _FormIzinPageState extends State<FormIzinPage> {
  String _izinType = 'Sakit';
  final TextEditingController _namaPenyakitController = TextEditingController();
  final TextEditingController _jumlahHariController = TextEditingController();
  final TextEditingController _keteranganIzinController = TextEditingController();
  File? _fotoSurat;
  String? _fotoError;

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
                                  _fotoSurat!.path.split('/').last,
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
                          onPressed: () {
                            // TODO: Submit logic
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Form izin berhasil disubmit (dummy)!')),
                            );
                          },
                          child: const Text('Kirim Izin'),
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