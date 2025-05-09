import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class InputDataPage extends StatefulWidget {
  const InputDataPage({super.key});

  @override
  State<InputDataPage> createState() => _InputDataPageState();
}

class _InputDataPageState extends State<InputDataPage> {
  bool isScanning = false;
  String? scannedCode;
  late MobileScannerController controller;
  File? _capturedImage;
  bool isLoading = false;

  final TextEditingController namaController = TextEditingController();
  final TextEditingController kondisiController = TextEditingController();
  final TextEditingController kantorController = TextEditingController();
  final TextEditingController lantaiController = TextEditingController();
  final TextEditingController ruanganController = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    isScanning = true;
    controller.start();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void onBarcodeDetected(BarcodeCapture capture) {
    final code = capture.barcodes.first.rawValue;
    if (code != null && isScanning) {
      setState(() {
        scannedCode = code;
        isScanning = false;
      });
      controller.stop();
    }
  }

  InputDecoration buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.black),
      border: const OutlineInputBorder(),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.black),
      ),
    );
  }

  Future<DocumentSnapshot?> checkIfItemExists(String barcode) async {
    var result = await FirebaseFirestore.instance
        .collection('barang')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    if (result.docs.isNotEmpty) {
      return result.docs.first;
    }
    return null;
  }

  Future<void> captureImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> saveData() async {
    if (namaController.text.isEmpty ||
        kondisiController.text.isEmpty ||
        kantorController.text.isEmpty ||
        lantaiController.text.isEmpty ||
        ruanganController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua data')),
      );
      return;
    }

    if (_capturedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap ambil foto terlebih dahulu')),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      if (scannedCode == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barcode tidak terdeteksi')),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harap login terlebih dahulu')),
        );
        return;
      }

      var existingItem = await checkIfItemExists(scannedCode!);

      if (existingItem != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Data Barang Sudah Ada'),
            content: const Text(
                'Barang ini sudah ada, apakah Anda ingin memperbarui datanya?'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await FirebaseFirestore.instance
                      .collection('barang')
                      .doc(existingItem.id)
                      .update({
                    'nama_barang': namaController.text,
                    'kondisi': kondisiController.text,
                    'kantor': kantorController.text,
                    'lantai': lantaiController.text,
                    'ruangan': ruanganController.text,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Data berhasil diperbarui')),
                  );
                  resetForm();
                },
                child: const Text('Ya, Perbarui'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tidak, Batalkan'),
              ),
            ],
          ),
        );
      } else {
        await FirebaseFirestore.instance.collection('barang').add({
          'barcode': scannedCode,
          'nama_barang': namaController.text,
          'kondisi': kondisiController.text,
          'kantor': kantorController.text,
          'lantai': lantaiController.text,
          'ruangan': ruanganController.text,
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data berhasil disimpan')),
        );
        resetForm();
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void resetForm() {
    setState(() {
      isScanning = false;
      scannedCode = null;
      namaController.clear();
      kondisiController.clear();
      kantorController.clear();
      lantaiController.clear();
      ruanganController.clear();
      _capturedImage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        automaticallyImplyLeading: false,
        title: Image.asset('lib/img/bpjs.png',
            height: 40, width: 100, fit: BoxFit.contain),
      ),
      backgroundColor: Colors.white,
      body: isScanning
          ? Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    height: 300,
                    width: MediaQuery.of(context).size.width * 0.85,
                    child: MobileScanner(
                      controller: controller,
                      onDetect: onBarcodeDetected,
                      fit: BoxFit.cover,
                    ),
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
                    'Arahkan barcode ke dalam kotak',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                children: [
                  const Text('Form Pengisian Data',
                      style: TextStyle(fontSize: 20, color: Colors.black),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: scannedCode,
                    readOnly: true,
                    style: const TextStyle(color: Colors.black),
                    decoration: buildInputDecoration('Hasil Barcode'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: namaController,
                      style: const TextStyle(color: Colors.black),
                      decoration: buildInputDecoration('Nama Barang')),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: kondisiController,
                      style: const TextStyle(color: Colors.black),
                      decoration: buildInputDecoration('Kondisi')),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: kantorController,
                      style: const TextStyle(color: Colors.black),
                      decoration: buildInputDecoration('Kantor')),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: lantaiController,
                      style: const TextStyle(color: Colors.black),
                      decoration: buildInputDecoration('Lantai')),
                  const SizedBox(height: 16),
                  TextFormField(
                      controller: ruanganController,
                      style: const TextStyle(color: Colors.black),
                      decoration: buildInputDecoration('Ruangan')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: captureImage,
                    child: const Text('Ambil Foto'),
                  ),
                  if (_capturedImage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Image.file(_capturedImage!, height: 150),
                    ),
                  const SizedBox(height: 24),
                  isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: saveData, child: const Text('Simpan')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: resetForm, child: const Text('Scan Ulang')),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: 2,
        selectedItemColor: Colors.green,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Input'),
        ],
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/search');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/input');
              break;
          }
        },
      ),
    );
  }
}
