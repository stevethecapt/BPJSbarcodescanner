import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isScanning = false;
  bool hasScanned = false;
  bool isLoading = false;
  String? scannedCode;
  Map<String, dynamic>? itemData;

  final MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  void deactivate() {
    cameraController.stop();
    super.deactivate();
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  void onBarcodeDetected(BarcodeCapture capture) async {
    final code = capture.barcodes.first.rawValue;
    if (code != null && isScanning && !isLoading) {
      setState(() {
        scannedCode = code;
        isLoading = true;
        isScanning = false;
        hasScanned = true;
      });

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
            itemData = null;
          });
        }
      } catch (e) {
        print('Error occurred: $e');
        setState(() {
          itemData = null;
        });
      } finally {
        setState(() {
          isLoading = false;
        });
      }

      cameraController.stop(); // stop scanner only after reading is done
    }
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value?.toString() ?? '-'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (hasScanned && itemData != null) {
          setState(() {
            isScanning = false;
            itemData = null;
            hasScanned = false;
          });
          return false;
        }

        if (isScanning) {
          setState(() {
            isScanning = false;
            scannedCode = null;
            itemData = null;
          });
          return false;
        }

        SystemNavigator.pop();
        return true;
      },
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
                    SizedBox(
                      height: 300,
                      width: MediaQuery.of(context).size.width * 0.85,
                      child: MobileScanner(
                        controller: cameraController,
                        onDetect: onBarcodeDetected,
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
            : isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                    ),
                  )
                : itemData != null
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Data Barang Ditemukan',
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Card(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow(
                                        'Barcode', itemData?['barcode']),
                                    _buildInfoRow('Nama Barang',
                                        itemData?['nama_barang']),
                                    _buildInfoRow(
                                        'Kondisi', itemData?['kondisi']),
                                    _buildInfoRow(
                                        'Kantor', itemData?['kantor']),
                                    _buildInfoRow(
                                        'Lantai', itemData?['lantai']),
                                    _buildInfoRow(
                                        'Ruangan', itemData?['ruangan']),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : hasScanned
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Informasi Tidak Ditemukan.',
                                  style: TextStyle(fontSize: 18),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      isScanning = true;
                                      scannedCode = null;
                                      itemData = null;
                                      hasScanned = false;
                                      cameraController.start();
                                    });
                                  },
                                  icon: const Icon(Icons.qr_code_scanner),
                                  label: const Text("Coba Scan Lagi"),
                                )
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Expanded(child: Container()),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 60),
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.qr_code_scanner,
                                      color: Colors.white),
                                  label: const Text(
                                    'Scan Barcode',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 16),
                                    textStyle: const TextStyle(fontSize: 16),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      isScanning = true;
                                      scannedCode = null;
                                      itemData = null;
                                      hasScanned = false;
                                      isLoading = false;
                                      cameraController.start();
                                    });
                                  },
                                ),
                              ),
                            ],
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
                setState(() {
                  isScanning = true;
                  scannedCode = null;
                  itemData = null;
                  hasScanned = false;
                  isLoading = false;
                  cameraController.start();
                });
                break;
              case 1:
                cameraController.stop();
                _navigateTo(context, '/search');
                break;
              case 2:
                cameraController.stop();
                _navigateTo(context, '/input');
                break;
            }
          },
        ),
      ),
    );
  }
}
