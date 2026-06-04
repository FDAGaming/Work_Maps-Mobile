import 'package:flutter/material.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Mock Data
  final List<Map<String, dynamic>> _mockCategories = [
    {'name': 'Cafe', 'icon': Icons.local_cafe_rounded},
    {'name': 'Kantin', 'icon': Icons.restaurant_rounded},
    {'name': 'Fotokopi', 'icon': Icons.print_rounded},
    {'name': 'ATM', 'icon': Icons.local_atm_rounded},
  ];

  final List<Map<String, dynamic>> _mockPlaces = [
    {'name': 'Kafe Literasi', 'category': 'Cafe', 'distance': '450 m', 'rating': 4.8},
    {'name': 'Fotokopi Jaya', 'category': 'Fotokopi', 'distance': '120 m', 'rating': 4.5},
    {'name': 'Kantin Pusat', 'category': 'Kantin', 'distance': '800 m', 'rating': 4.2},
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Logika Navigasi: Jika tombol index 1 (Peta) di Bottom Nav ditekan
    if (index == 1) {
      Navigator.pushNamed(context, '/map').then((_) {
        // Mengembalikan warna icon Bottom Nav ke Home saat kembali dari layar peta
        setState(() {
          _selectedIndex = 0;
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Warna abu-abu super terang yang lebih modern
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(), // Animasi scroll lebih mulus ala iOS
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryFilter(),
              _buildPlacesList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // --- KOMPONEN UI MODERN ---

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Halo, Selamat Pagi! 👋',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Mau nugas di mana hari ini?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
            ],
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            backgroundImage: const NetworkImage('https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Cari workspace atau kafe...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueAccent),
            suffixIcon: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Text(
            'Kategori Pilihan',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
        ),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _mockCategories.length,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(_mockCategories[index]['icon'], color: Colors.blueAccent, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _mockCategories[index]['name'],
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

    Widget _buildPlacesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Terdekat dari Anda',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Lihat Semua', style: TextStyle(color: Colors.blueAccent)),
              )
            ],
          ),
        ),
        ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _mockPlaces.length,
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          itemBuilder: (context, index) {
            final place = _mockPlaces[index];
            
            // TAMBAHAN: Bungkus Container dengan GestureDetector
            return GestureDetector(
              onTap: () {
                // TAMBAHAN: Navigasi ke DetailScreen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetailScreen(place: place),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      // Area Gambar Placeholder yang lebih modern
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.blueAccent, size: 40),
                      ),
                      const SizedBox(width: 16),
                      // Area Teks
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                place['category'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              place['name'],
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  place['distance'],
                                  style: const TextStyle(fontSize: 13, color: Colors.black54, fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  place['rating'].toString(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ); // Akhir dari GestureDetector
          },
        ),
        const SizedBox(height: 24), // Spacing ekstra di bawah
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Peta'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Favorit'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}