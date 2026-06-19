import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> absensiList = [
      {'tanggal': '01/06/2024', 'status': 'Hadir'},
      {'tanggal': '31/05/2024', 'status': 'Hadir'},
      {'tanggal': '30/05/2024', 'status': 'Tidak Hadir'},
      {'tanggal': '29/05/2024', 'status': 'Hadir'},
      {'tanggal': '28/05/2024', 'status': 'Hadir'},
    ];

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
                  Text(
                    'Selamat datang,',
                    style: TextStyle(
                      fontSize: kHeaderFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.13),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'User',
                    style: TextStyle(
                      fontSize: kUserFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
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
                      absensiList.isEmpty
                          ? const Center(
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
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: absensiList.length,
                              separatorBuilder: (context, idx) =>
                                  Divider(height: 1, color: Colors.grey[200]),
                              itemBuilder: (context, idx) {
                                final data = absensiList[idx];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          data['tanggal']!,
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
                                              label: data['status'] == 'Hadir'
                                                  ? 'Status hadir'
                                                  : 'Status tidak hadir',
                                              child: Icon(
                                                data['status'] == 'Hadir'
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: data['status'] == 'Hadir'
                                                    ? const Color(0xFF178A3D)
                                                    : Colors.redAccent,
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
                                                color: data['status'] == 'Hadir'
                                                    ? const Color(0xFF4ADE80).withOpacity(0.18)
                                                    : Colors.redAccent.withOpacity(0.13),
                                                borderRadius: BorderRadius.circular(kStatusBorderRadius),
                                              ),
                                              child: Text(
                                                data['status']!,
                                                style: TextStyle(
                                                  color: data['status'] == 'Hadir'
                                                      ? const Color(0xFF178A3D)
                                                      : Colors.redAccent,
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
