import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'login_screen.dart';

class FavoriteScreen extends StatefulWidget {
  const FavoriteScreen({super.key});

  @override
  State<FavoriteScreen> createState() => _FavoriteScreenState();
}

class _FavoriteScreenState extends State<FavoriteScreen> {
  List<PlaceModel> _favorites = [];
  bool _loading = true;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _loading = true);
    try {
      final list = await _api.getFavorites();
      setState(() => _favorites = list);
    } catch (_) {
      setState(() => _favorites = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _removeFavorite(PlaceModel place) async {
    final ok = await _api.removeFavorite(place.id);
    if (ok) {
      setState(() => _favorites.removeWhere((p) => p.id == place.id));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${place.name} dihapus dari favorit.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Tempat Favorit',
            style: TextStyle(color: Color(0xFF2D3142), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.blueAccent),
              onPressed: _loadFavorites,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : !_api.isLoggedIn
              ? _buildLoginPrompt()
              : _favorites.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadFavorites,
                      color: Colors.blueAccent,
                      child: _buildFavoriteList(),
                    ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded, size: 60, color: Colors.blueAccent),
            ),
            const SizedBox(height: 24),
            const Text('Login Diperlukan',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const SizedBox(height: 8),
            const Text(
              'Login untuk melihat dan menyimpan tempat favorit Anda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                  // Reload setelah kembali dari login
                  _loadFavorites();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Masuk Sekarang',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
          const Text('Belum ada favorit',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 8),
          const Text('Tempat yang Anda simpan akan muncul di sini.',
              style: TextStyle(fontSize: 15, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildFavoriteList() {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final place = _favorites[index];
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DetailScreen(place: place)),
            );
            _loadFavorites();
          },
          child: Container(
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: place.photoUrl != null
                        ? Image.network(place.photoUrl!, width: 80, height: 80, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(place))
                        : _placeholder(place),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 4),
                        Text(place.categoryName,
                            style: const TextStyle(
                                fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(place.address,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              place.rating > 0 ? place.rating.toStringAsFixed(1) : 'Baru',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => _removeFavorite(place),
                              icon: const Icon(Icons.bookmark_remove_rounded,
                                  color: Colors.redAccent, size: 22),
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
          ),
        );
      },
    );
  }

  Widget _placeholder(PlaceModel place) {
    return Container(
      width: 80, height: 80, color: Colors.blue[50],
      child: Icon(_getCategoryIcon(place.categoryIcon), color: Colors.blueAccent, size: 32),
    );
  }

  IconData _getCategoryIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'coffee': return Icons.local_cafe_rounded;
      case 'utensils': return Icons.restaurant_rounded;
      case 'copy': return Icons.print_rounded;
      case 'credit-card': return Icons.local_atm_rounded;
      case 'home': return Icons.home_rounded;
      case 'shopping-bag': return Icons.shopping_bag_rounded;
      case 'heart': return Icons.local_hospital_rounded;
      case 'building': return Icons.business_rounded;
      case 'wind': return Icons.local_laundry_service_rounded;
      default: return Icons.storefront_rounded;
    }
  }
}
