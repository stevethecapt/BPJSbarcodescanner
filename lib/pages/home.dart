import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart'; // Import mobile_scanner untuk scan barcode
import 'package:cloud_firestore/cloud_firestore.dart'; // Import firestore untuk mengambil data barang

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isScanning = true; // Flag untuk mengecek apakah sedang scan
  String? scannedCode; // Menyimpan hasil barcode yang dipindai
  Map<String, dynamic>?
      itemData; // Menyimpan data barang yang diambil dari Firestore

  @override
  void initState() {
    super.initState();
    // Otomatis buka kamera setelah login
    isScanning = true;
  }

  // Fungsi logout untuk pengguna
  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  // Fungsi untuk navigasi ke halaman lain
  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  // Fungsi untuk menangani deteksi barcode
  void onBarcodeDetected(BarcodeCapture capture) async {
    final code = capture.barcodes.first.rawValue;
    if (code != null && isScanning) {
      setState(() {
        scannedCode = code;
        isScanning = false;
      });

      // Mengambil data barang berdasarkan barcode dari Firestore
      try {
        final firestore = FirebaseFirestore.instance;
        final snapshot = await firestore
            .collection('barang')
            .where('barcode', isEqualTo: scannedCode)
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            itemData = snapshot.docs.first.data();
          });
        } else {
          setState(() {
            itemData = null; // Barang tidak ditemukan
          });
        }
      } catch (e) {
        print('Terjadi kesalahan: $e');
        setState(() {
          itemData = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'BPJS Barcode Scanner',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: isScanning
            ? Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Memasukkan pemindaian barcode
                    SizedBox(
                      height: 300,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: MobileScanner(
                        onDetect: onBarcodeDetected, // Deteksi barcode
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    const Positioned(
                      bottom: 32,
                      child: Text(
                        "Arahkan barcode ke dalam kotak",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              )
            : itemData != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Barang Ditemukan',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 16),
                        Text(
                            'Barcode: ${itemData?['barcode'] ?? 'Tidak Ditemukan'}'),
                        Text(
                            'Nama Barang: ${itemData?['nama_barang'] ?? 'Tidak Ditemukan'}'),
                        Text(
                            'Kondisi: ${itemData?['kondisi'] ?? 'Tidak Ditemukan'}'),
                        Text(
                            'Kantor: ${itemData?['kantor'] ?? 'Tidak Ditemukan'}'),
                        Text(
                            'Lantai: ${itemData?['lantai'] ?? 'Tidak Ditemukan'}'),
                        Text(
                            'Ruangan: ${itemData?['ruangan'] ?? 'Tidak Ditemukan'}'),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'Barang Tidak Ditemukan.',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
        bottomNavigationBar: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search),
              label: 'Search',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.edit),
              label: 'Input',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                _navigateTo(context, '/home');
                break;
              case 1:
                _navigateTo(context, '/search');
                break;
              case 2:
                _navigateTo(context, '/input');
                break;
            }
          },
        ),
      ),
    );
  }
}
