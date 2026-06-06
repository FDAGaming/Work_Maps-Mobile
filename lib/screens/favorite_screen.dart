import 'package:flutter/material.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Nanti data ini diisi dari database lokal (SQLite/SharedPrefs) atau API
    final List<Map<String, dynamic>> favoritePlaces = [
      {'name': 'Kafe Literasi', 'category': 'Cafe', 'distance': '450 m', 'rating': 4.8},
      // Hapus atau komentari isi list ini untuk melihat tampilan "Empty State"
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tempat Favorit', style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: favoritePlaces.isEmpty
          ? _buildEmptyState()
          : _buildFavoriteList(favoritePlaces),
    );
  }

  // Tampilan jika belum ada favorit
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
            child: const Icon(Icons.bookmark_border_rounded, size: 80, color: Colors.blueAccent),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum ada favorit',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tempat yang Anda simpan akan muncul di sini.',
            style: TextStyle(fontSize: 15, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // Tampilan jika ada data favorit
  Widget _buildFavoriteList(List<Map<String, dynamic>> places) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: places.length,
      itemBuilder: (context, index) {
        final place = places[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.storefront_rounded, color: Colors.blueAccent, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                      ),
                      const SizedBox(height: 6),
                      Text(place['category'], style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(place['rating'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          // Tombol hapus dari favorit
                          IconButton(
                            onPressed: () {
                              // TODO: Logika hapus dari favorit
                            },
                            icon: const Icon(Icons.bookmark_remove_rounded, color: Colors.redAccent, size: 22),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}