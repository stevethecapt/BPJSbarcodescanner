import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  List<DocumentSnapshot> searchResults = [];
  List<DocumentSnapshot> recentResults = [];
  bool isLoading = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchRecentData();
  }

  Future<void> searchData() async {
    setState(() {
      isLoading = true;
      errorMessage = ''; // Reset error message
    });

    try {
      final query = searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          searchResults.clear();
          isLoading = false; // Stop loading if query is empty
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;

      final result = await firestore
          .collection('barang')
          .where('nama_barang', isGreaterThanOrEqualTo: query)
          .where('nama_barang', isLessThanOrEqualTo: query + '\uf8ff')
          .get();

      if (result.docs.isEmpty) {
        final barcodeResult = await firestore
            .collection('barang')
            .where('barcode', isEqualTo: query)
            .get();

        setState(() {
          searchResults =
              barcodeResult.docs.isNotEmpty ? barcodeResult.docs : [];
          isLoading = false;
        });
      } else {
        setState(() {
          searchResults = result.docs;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
        isLoading = false;
      });
    }
  }

  Future<void> fetchRecentData() async {
    try {
      final firestore = FirebaseFirestore.instance;

      final recentData = await firestore
          .collection('barang')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .get();

      setState(() {
        recentResults = recentData.docs;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan saat mengambil data terbaru: $e';
      });
    }
  }

  void _showItemDetail(DocumentSnapshot item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailPage(item: item),
      ),
    );
  }

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _navigateTo(BuildContext context, String routeName) {
    Navigator.pushNamed(context, routeName);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async =>
          false, // Disable physical back button for this page
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pencarian Barang',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              // Pop to home after going through step-by-step
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (route) => false);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: searchController,
                decoration: const InputDecoration(
                  labelText: 'Cari berdasarkan nama atau barcode',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    searchData();
                  } else {
                    setState(() {
                      searchResults.clear();
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (isLoading) const CircularProgressIndicator(),
              Expanded(
                child: searchController.text.isEmpty
                    ? ListView.builder(
                        itemCount:
                            recentResults.isNotEmpty ? recentResults.length : 0,
                        itemBuilder: (context, index) {
                          final item = recentResults[index];
                          final itemData = item.data() as Map<String, dynamic>;
                          final barcode =
                              itemData['barcode'] ?? 'Tidak Tersedia';
                          final namaBarang = itemData['nama_barang'] ??
                              'Nama Barang Tidak Ditemukan';

                          return ListTile(
                            title: Text(namaBarang),
                            subtitle: Text('Barcode: $barcode'),
                            onTap: () => _showItemDetail(item),
                          );
                        },
                      )
                    : ListView.builder(
                        itemCount:
                            searchResults.isNotEmpty ? searchResults.length : 0,
                        itemBuilder: (context, index) {
                          final item = searchResults[index];
                          final itemData = item.data() as Map<String, dynamic>;

                          return ListTile(
                            title: Text(itemData['nama_barang'] ??
                                'Nama Barang Tidak Ditemukan'),
                            subtitle: Text(
                                'Barcode: ${itemData['barcode'] ?? 'Tidak Tersedia'}'),
                            onTap: () => _showItemDetail(item),
                          );
                        },
                      ),
              ),
            ],
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

class ItemDetailPage extends StatelessWidget {
  final DocumentSnapshot item;

  const ItemDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final itemData = item.data() as Map<String, dynamic>;
    final namaBarang = itemData['nama_barang'] ?? 'Tidak Tersedia';
    final kondisi = itemData['kondisi'] ?? 'Tidak Tersedia';
    final kantor = itemData['kantor'] ?? 'Tidak Tersedia';
    final lantai = itemData['lantai'] ?? 'Tidak Tersedia';
    final ruangan = itemData['ruangan'] ?? 'Tidak Tersedia';
    final barcode = itemData['barcode'] ?? 'Tidak Tersedia';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // This goes back to the search results
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nama Barang: $namaBarang',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Kondisi: $kondisi', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Kantor: $kantor', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Lantai: $lantai', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Ruangan: $ruangan', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Barcode: $barcode', style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}
