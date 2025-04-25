import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

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
          title: const Text(
            'Pencarian',
            style: TextStyle(color: Colors.white), // Teks putih
          ),
          backgroundColor: Colors.blue,
          leading: IconButton(
            icon:
                const Icon(Icons.arrow_back, color: Colors.white), // Ikon putih
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () => _logout(context),
              tooltip: 'Logout',
            ),
          ],
        ),
        body: const Center(
          child: Text(
            'Halaman Pencarian',
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
