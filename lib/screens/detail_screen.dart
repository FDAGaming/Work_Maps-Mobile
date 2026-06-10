import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/place_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';

class DetailScreen extends StatefulWidget {
  final PlaceModel place;

  const DetailScreen({Key? key, required this.place}) : super(key: key);

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;
  bool _loadingFavorite = true;
  bool _loadingReviews = true;
  List<ReviewModel> _reviews = [];
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    await Future.wait([_checkFavorite(), _loadReviews()]);
  }

  Future<void> _checkFavorite() async {
    if (!_api.isLoggedIn) {
      setState(() => _loadingFavorite = false);
      return;
    }
    try {
      final fav = await _api.checkFavorite(widget.place.id);
      setState(() => _isFavorite = fav);
    } catch (_) {}
    setState(() => _loadingFavorite = false);
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _api.getReviews(widget.place.id);
      setState(() => _reviews = reviews);
    } catch (_) {}
    setState(() => _loadingReviews = false);
  }

  Future<void> _toggleFavorite() async {
    if (!_api.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login terlebih dahulu untuk menyimpan favorit.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }
    final prev = _isFavorite;
    setState(() => _isFavorite = !prev);
    bool ok;
    if (prev) {
      ok = await _api.removeFavorite(widget.place.id);
    } else {
      ok = await _api.addFavorite(widget.place.id);
    }
    if (!ok) setState(() => _isFavorite = prev); // revert on fail
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isFavorite ? '❤️ Ditambahkan ke Favorit!' : 'Dihapus dari Favorit.'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openNavigation() async {
    final lat = widget.place.lat;
    final lng = widget.place.lng;
    final Uri googleMapsUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final Uri fallbackUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
    try {
      if (await canLaunchUrl(googleMapsUrl)) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(fallbackUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal membuka navigasi.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _callPhone() async {
    final phone = widget.place.phone;
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSliverAppBar(place),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoCard(place),
                    if (place.tags.isNotEmpty) _buildTagsCard(place),
                    _buildOperationalHoursCard(place),
                    _buildReviewsSection(place),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _buildBottomActionBar(place),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(PlaceModel place) {
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D3142)),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: _toggleFavorite,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: Colors.white, shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: _loadingFavorite
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: _isFavorite ? Colors.blueAccent : Colors.grey,
                    ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: place.photoUrl != null
            ? Image.network(place.photoUrl!, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAppBarPlaceholder(place))
            : _buildAppBarPlaceholder(place),
      ),
    );
  }

  Widget _buildAppBarPlaceholder(PlaceModel place) {
    return Container(
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
            width: 100, height: 100,
            decoration: BoxDecoration(
              color: Colors.white, shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Icon(_getCategoryIcon(place.categoryIcon), color: Colors.blueAccent, size: 48),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              place.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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
              place.categoryName,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(PlaceModel place) {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStatChip(
                icon: Icons.star_rounded, iconColor: Colors.amber,
                value: place.rating > 0 ? place.rating.toStringAsFixed(1) : 'Baru',
                label: 'Rating',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.reviews_rounded, iconColor: Colors.purpleAccent,
                value: place.reviewCount.toString(),
                label: 'Ulasan',
              ),
              if (place.priceRange != null) ...[
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.payments_rounded, iconColor: Colors.green,
                  value: place.priceRange!,
                  label: 'Harga',
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const Text('Tentang Tempat Ini',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
          const SizedBox(height: 8),
          Text(
            place.description.isNotEmpty ? place.description : 'Tidak ada deskripsi.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.blueAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(place.address,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ),
            ],
          ),
          if (place.isVerified) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 16),
                const SizedBox(width: 6),
                Text('Tempat Terverifikasi',
                    style: TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTagsCard(PlaceModel place) {
    return _buildCard(
      title: 'Fasilitas & Tag',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: place.tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getTagIcon(tag), color: Colors.blueAccent, size: 15),
                const SizedBox(width: 6),
                Text(tag,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2D3142))),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOperationalHoursCard(PlaceModel place) {
    return _buildCard(
      title: 'Jam Operasional',
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              place.openHours ?? 'Informasi jam tidak tersedia',
              style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(PlaceModel place) {
    return _buildCard(
      title: 'Ulasan Pengguna',
      trailing: place.rating > 0
          ? Row(children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 4),
              Text(place.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
            ])
          : null,
      child: _loadingReviews
          ? const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
          : _reviews.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text('Belum ada ulasan. Jadilah yang pertama!',
                        style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                  ),
                )
              : Column(children: _reviews.map(_buildReviewItem).toList()),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    final initials = review.userName.isNotEmpty
        ? review.userName.trim().split(' ').map((w) => w[0]).take(2).join().toUpperCase()
        : '?';
    final date = _formatDate(review.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blueAccent.withOpacity(0.15),
            child: Text(initials,
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent, fontSize: 13)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(review.userName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
                    Text(date, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (i) => Icon(
                    i < review.rating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber, size: 14,
                  )),
                ),
                const SizedBox(height: 6),
                Text(review.comment,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(PlaceModel place) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -6))],
      ),
      child: Row(
        children: [
          if (place.phone != null)
            GestureDetector(
              onTap: _callPhone,
              child: Container(
                width: 52, height: 52,
                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.phone_rounded, color: Colors.blueAccent, size: 24),
              ),
            ),
          if (place.phone != null) const SizedBox(width: 12),
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _openNavigation,
                icon: const Icon(Icons.directions_rounded, color: Colors.white),
                label: const Text('Buka Navigasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────

  Widget _buildCard({String? title, Widget? trailing, required Widget child}) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
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

  Widget _buildStatChip({required IconData icon, required Color iconColor, required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF8F9FA), borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  IconData _getTagIcon(String tag) {
    switch (tag.toLowerCase()) {
      case 'wifi': return Icons.wifi_rounded;
      case 'ac': return Icons.ac_unit_rounded;
      case 'colokan': return Icons.electrical_services_rounded;
      case 'parkir': return Icons.local_parking_rounded;
      case 'non-smoking': return Icons.smoke_free_rounded;
      case 'qris': return Icons.qr_code_rounded;
      default: return Icons.check_circle_outline_rounded;
    }
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

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inDays == 0) return 'Hari ini';
      if (diff.inDays == 1) return 'Kemarin';
      if (diff.inDays < 7) return '${diff.inDays} hari lalu';
      if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} minggu lalu';
      return '${(diff.inDays / 30).floor()} bulan lalu';
    } catch (_) {
      return '';
    }
  }
}
