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
      errorMessage = '';
    });

    try {
      final query = searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          searchResults.clear();
          isLoading = false;
        });
        return;
      }

      final firestore = FirebaseFirestore.instance;

      final result = await firestore
          .collection('barang')
          .where('nama_barang', isGreaterThanOrEqualTo: query)
          .where('nama_barang', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      if (result.docs.isEmpty) {
        final barcodeResult = await firestore
            .collection('barang')
            .where('barcode', isEqualTo: query)
            .get();

        setState(() {
          searchResults = barcodeResult.docs;
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
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pencarian Barang',
              style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
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
              if (errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(errorMessage,
                      style: const TextStyle(color: Colors.red)),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: searchController.text.isEmpty
                      ? recentResults.length
                      : searchResults.length,
                  itemBuilder: (context, index) {
                    final item = searchController.text.isEmpty
                        ? recentResults[index]
                        : searchResults[index];
                    final itemData = item.data() as Map<String, dynamic>;
                    final namaBarang = itemData['nama_barang'] ??
                        'Nama Barang Tidak Ditemukan';
                    final barcode = itemData['barcode'] ?? 'Tidak Tersedia';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          namaBarang,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        subtitle: Text('Barcode: $barcode'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () => _showItemDetail(item),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 1,
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            BottomNavigationBarItem(icon: Icon(Icons.edit), label: 'Input'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Barang'),
        backgroundColor: Colors.blue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildDetailCard('Nama Barang', itemData['nama_barang']),
            _buildDetailCard('Kondisi', itemData['kondisi']),
            _buildDetailCard('Kantor', itemData['kantor']),
            _buildDetailCard('Lantai', itemData['lantai']),
            _buildDetailCard('Ruangan', itemData['ruangan']),
            _buildDetailCard('Barcode', itemData['barcode']),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String label, dynamic value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      child: ListTile(
        title: Text(label),
        subtitle: Text(
          value?.toString() ?? 'Tidak Tersedia',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
