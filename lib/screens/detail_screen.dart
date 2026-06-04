import 'package:flutter/material.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> place;

  const DetailScreen({Key? key, required this.place}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;

  // Data review mock
  final List<Map<String, dynamic>> _mockReviews = [
    {
      'name': 'Andi Saputra',
      'avatar': 'AS',
      'rating': 5,
      'date': '2 hari lalu',
      'comment': 'Tempatnya nyaman banget buat nugas! WiFi kencang, colokan banyak, dan kopinya enak.',
    },
    {
      'name': 'Rina Kartika',
      'avatar': 'RK',
      'rating': 4,
      'date': '1 minggu lalu',
      'comment': 'Suka banget sama suasananya, tenang dan tidak terlalu ramai. Cocok untuk kerja atau belajar.',
    },
    {
      'name': 'Budi Santoso',
      'avatar': 'BS',
      'rating': 5,
      'date': '2 minggu lalu',
      'comment': 'Harganya terjangkau untuk mahasiswa. Rekomen deh!',
    },
  ];

  // Data fasilitas mock
  final List<Map<String, dynamic>> _facilities = [
    {'icon': Icons.wifi_rounded, 'label': 'Free WiFi'},
    {'icon': Icons.electrical_services_rounded, 'label': 'Colokan'},
    {'icon': Icons.ac_unit_rounded, 'label': 'AC'},
    {'icon': Icons.local_parking_rounded, 'label': 'Parkir'},
    {'icon': Icons.no_drinks_rounded, 'label': 'Non-Smoking'},
    {'icon': Icons.accessible_rounded, 'label': 'Akses Difabel'},
  ];

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final double rating = (place['rating'] as num?)?.toDouble() ?? 4.5;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          // Konten utama yang bisa di-scroll
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(place),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(place, rating),
                    _buildFacilitiesCard(),
                    _buildOperationalHoursCard(),
                    _buildReviewsSection(rating),
                    const SizedBox(height: 100), // ruang untuk tombol bawah
                  ],
                ),
              ),
            ],
          ),

          // Tombol aksi bawah (sticky)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomActionBar(),
          ),
        ],
      ),
    );
  }

  // --- KOMPONEN UI ---

  Widget _buildSliverAppBar(Map<String, dynamic> place) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D3142)),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite ? '❤️ Ditambahkan ke Favorit!' : 'Dihapus dari Favorit.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: _isFavorite ? Colors.blueAccent : Colors.grey,
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue[100]!, Colors.blue[50]!],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  _getCategoryIcon(place['category'] ?? ''),
                  color: Colors.blueAccent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                place['name'] ?? 'Nama Tempat',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  place['category'] ?? 'Kategori',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(Map<String, dynamic> place, double rating) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatChip(
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                value: rating.toString(),
                label: 'Rating',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.location_on_rounded,
                iconColor: Colors.redAccent,
                value: place['distance'] ?? '-',
                label: 'Jarak',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.reviews_rounded,
                iconColor: Colors.purpleAccent,
                value: '${_mockReviews.length}',
                label: 'Ulasan',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Tentang Tempat Ini',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tempat ini merupakan salah satu spot favorit di sekitar kampus. '
            'Suasananya nyaman dan kondusif untuk belajar atau bekerja. '
            'Dilengkapi dengan berbagai fasilitas modern untuk mendukung aktivitas produktif Anda.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Jl. Kampus No. 45, Surabaya, Jawa Timur',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3142),
              ),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return _buildCard(
      title: 'Fasilitas',
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _facilities.length,
        itemBuilder: (context, index) {
          final facility = _facilities[index];
          return Container(
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(facility['icon'], color: Colors.blueAccent, size: 26),
                const SizedBox(height: 6),
                Text(
                  facility['label'],
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3142),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOperationalHoursCard() {
    // TAMBAHAN: Mendefinisikan tipe data secara eksplisit agar tidak dianggap Object
    final List<Map<String, dynamic>> hours = [
      {'day': 'Senin – Jumat', 'time': '07.00 – 22.00', 'isOpen': true},
      {'day': 'Sabtu', 'time': '08.00 – 21.00', 'isOpen': true},
      {'day': 'Minggu', 'time': 'Tutup', 'isOpen': false},
    ];

    return _buildCard(
      title: 'Jam Operasional',
      child: Column(
        children: hours.map((h) {
          final isOpen = h['isOpen'] as bool;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  // UBAHAN: Casting eksplisit menjadi String
                  h['day'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    // UBAHAN: Casting eksplisit menjadi String
                    h['time'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isOpen ? Colors.green[700] : Colors.red[400],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReviewsSection(double avgRating) {
    return _buildCard(
      title: 'Ulasan Pengguna',
      trailing: Row(
        children: [
          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
          const SizedBox(width: 4),
          Text(
            avgRating.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF2D3142),
            ),
          ),
        ],
      ),
      child: Column(
        children: _mockReviews.map((review) => _buildReviewItem(review)).toList(),
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blueAccent.withOpacity(0.15),
            child: Text(
              review['avatar'],
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      review['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF2D3142),
                      ),
                    ),
                    Text(
                      review['date'],
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < (review['rating'] as int) ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  review['comment'],
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Tombol call
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.phone_rounded, color: Colors.blueAccent, size: 24),
          ),
          const SizedBox(width: 12),
          // Tombol navigasi utama
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Integrasikan url_launcher untuk membuka Google Maps / OSM
                },
                icon: const Icon(Icons.directions_rounded, color: Colors.white),
                label: const Text(
                  'Buka Navigasi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- HELPER ---

  /// Card wrapper umum supaya konsisten
  Widget _buildCard({
    String? title,
    Widget? trailing,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142),
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 16),
          ],
          child,
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'cafe':
        return Icons.local_cafe_rounded;
      case 'kantin':
        return Icons.restaurant_rounded;
      case 'fotokopi':
        return Icons.print_rounded;
      case 'atm':
        return Icons.local_atm_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }
}