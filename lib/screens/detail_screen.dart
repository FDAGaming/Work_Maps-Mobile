import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';
import '../models/review_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class DetailScreen extends StatefulWidget {
  final PlaceModel place;

  const DetailScreen({super.key, required this.place});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isFavorite = false;
  bool _loadingFavorite = true;
  bool _loadingReviews = true;
  List<ReviewModel> _reviews = [];
  PlaceModel? _detail; // detail terbaru dari API
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  PlaceModel get _place => _detail ?? widget.place;

  Future<void> _initData() async {
    await Future.wait([_loadDetail(), _checkFavorite(), _loadReviews()]);
  }

  Future<void> _loadDetail() async {
    try {
      final detail = await _api.getPlaceDetail(widget.place.id);
      if (mounted) setState(() => _detail = detail);
    } catch (_) {}
  }

  Future<void> _checkFavorite() async {
    if (!_api.isLoggedIn) {
      if (mounted) setState(() => _loadingFavorite = false);
      return;
    }
    try {
      final fav = await _api.checkFavorite(widget.place.id);
      if (mounted) setState(() => _isFavorite = fav);
    } catch (_) {}
    if (mounted) setState(() => _loadingFavorite = false);
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _api.getReviews(widget.place.id);
      if (mounted) setState(() => _reviews = reviews);
    } catch (_) {}
    if (mounted) setState(() => _loadingReviews = false);
  }

  Future<void> _toggleFavorite() async {
    if (!_api.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login terlebih dahulu untuk menyimpan favorit.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Masuk',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ),
      );
      return;
    }
    final prev = _isFavorite;
    setState(() => _isFavorite = !prev);
    final bool ok;
    if (prev) {
      ok = await _api.removeFavorite(_place.id);
    } else {
      ok = await _api.addFavorite(_place.id);
    }
    if (!ok && mounted) setState(() => _isFavorite = prev);
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
    final destLat = _place.lat;
    final destLng = _place.lng;

    // Tampilkan loading sementara mengambil lokasi user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Text('Mengambil lokasi Anda...'),
            ],
          ),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    // Coba ambil posisi GPS user
    double? originLat;
    double? originLng;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 5),
            ),
          );
          originLat = position.latitude;
          originLng = position.longitude;
        }
      }
    } catch (_) {
      // Jika gagal ambil lokasi, lanjutkan tanpa origin (Google Maps pakai lokasi sendiri)
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    // Bangun URL dengan origin (jika tersedia) dan destination
    final Uri googleMapsUrl;
    final Uri fallbackUrl;

    if (originLat != null && originLng != null) {
      // Dengan titik asal dari GPS user
      googleMapsUrl = Uri.parse(
        'google.navigation:q=$destLat,$destLng&mode=d',
      );
      fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&origin=$originLat,$originLng'
        '&destination=$destLat,$destLng'
        '&travelmode=driving',
      );
    } else {
      // Tanpa titik asal — Google Maps pakai lokasi perangkat otomatis
      googleMapsUrl = Uri.parse('google.navigation:q=$destLat,$destLng&mode=d');
      fallbackUrl = Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=$destLat,$destLng'
        '&travelmode=driving',
      );
    }

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
    final phone = _place.phone;
    if (phone == null) return;
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showWriteReviewSheet() {
    if (!_api.isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Login terlebih dahulu untuk menulis ulasan.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: SnackBarAction(
            label: 'Masuk',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            ),
          ),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReviewSheet(
        placeId: _place.id,
        placeName: _place.name,
        api: _api,
        onSubmitted: () {
          _loadReviews();
          _loadDetail();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final place = _place;
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
            bottom: 0,
            left: 0,
            right: 0,
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
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3))
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
            onTap: _toggleFavorite,
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 10,
                      offset: const Offset(0, 3))
                ],
              ),
              child: _loadingFavorite
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      _isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
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
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Icon(_getCategoryIcon(place.categoryIcon),
                color: Colors.blueAccent, size: 48),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              place.name,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.blueAccent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              place.categoryName,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blueAccent),
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
                icon: Icons.star_rounded,
                iconColor: Colors.amber,
                value: place.rating > 0 ? place.rating.toStringAsFixed(1) : 'Baru',
                label: 'Rating',
              ),
              const SizedBox(width: 12),
              _buildStatChip(
                icon: Icons.reviews_rounded,
                iconColor: Colors.purpleAccent,
                value: place.reviewCount.toString(),
                label: 'Ulasan',
              ),
              if (place.priceRange != null) ...[
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.payments_rounded,
                  iconColor: Colors.green,
                  value: place.priceRange!,
                  label: 'Harga',
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          const Text('Tentang Tempat Ini',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3142))),
          const SizedBox(height: 8),
          Text(
            place.description.isNotEmpty
                ? place.description
                : 'Tidak ada deskripsi.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.6),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded,
                  color: Colors.blueAccent, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(place.address,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ),
            ],
          ),
          if (place.website != null && place.website!.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () async {
                final uri = Uri.parse(place.website!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: Row(
                children: [
                  const Icon(Icons.language_rounded,
                      color: Colors.blueAccent, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place.website!,
                      style: const TextStyle(
                          fontSize: 13,
                          color: Colors.blueAccent,
                          decoration: TextDecoration.underline),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (place.isVerified) ...[
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 16),
                SizedBox(width: 6),
                Text('Tempat Terverifikasi',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600)),
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
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3142))),
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
          const Icon(Icons.access_time_rounded,
              color: Colors.blueAccent, size: 20),
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
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (place.rating > 0) ...[
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 4),
            Text(place.rating.toStringAsFixed(1),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF2D3142))),
            const SizedBox(width: 12),
          ],
          GestureDetector(
            onTap: _showWriteReviewSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.rate_review_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Tulis',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
      child: _loadingReviews
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ))
          : _reviews.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.rate_review_outlined,
                            color: Colors.grey[300], size: 40),
                        const SizedBox(height: 8),
                        Text('Belum ada ulasan. Jadilah yang pertama!',
                            style:
                                TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  ),
                )
              : Column(children: _reviews.map(_buildReviewItem).toList()),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    final initials = review.userName.isNotEmpty
        ? review.userName
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? w[0] : '')
            .take(2)
            .join()
            .toUpperCase()
        : '?';
    final date = _formatDate(review.createdAt);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
            child: Text(initials,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueAccent,
                    fontSize: 13)),
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
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF2D3142))),
                    Text(date,
                        style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < review.rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(review.comment,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[600], height: 1.5)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -6))
        ],
      ),
      child: Row(
        children: [
          if (place.phone != null)
            GestureDetector(
              onTap: _callPhone,
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.phone_rounded,
                    color: Colors.blueAccent, size: 24),
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
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
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
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142))),
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
            borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  IconData _getTagIcon(String tag) {
    switch (tag.toLowerCase()) {
      case 'wifi':
        return Icons.wifi_rounded;
      case 'ac':
        return Icons.ac_unit_rounded;
      case 'colokan':
        return Icons.electrical_services_rounded;
      case 'parkir':
        return Icons.local_parking_rounded;
      case 'non-smoking':
        return Icons.smoke_free_rounded;
      case 'qris':
        return Icons.qr_code_rounded;
      default:
        return Icons.check_circle_outline_rounded;
    }
  }

  IconData _getCategoryIcon(String icon) {
    switch (icon.toLowerCase()) {
      case 'coffee':
        return Icons.local_cafe_rounded;
      case 'utensils':
        return Icons.restaurant_rounded;
      case 'copy':
        return Icons.print_rounded;
      case 'credit-card':
        return Icons.local_atm_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'shopping-bag':
        return Icons.shopping_bag_rounded;
      case 'heart':
        return Icons.local_hospital_rounded;
      case 'building':
        return Icons.business_rounded;
      case 'wind':
        return Icons.local_laundry_service_rounded;
      default:
        return Icons.storefront_rounded;
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

// ── WRITE REVIEW BOTTOM SHEET ─────────────────────────────────────────────

class _ReviewSheet extends StatefulWidget {
  final int placeId;
  final String placeName;
  final ApiService api;
  final VoidCallback onSubmitted;

  const _ReviewSheet({
    required this.placeId,
    required this.placeName,
    required this.api,
    required this.onSubmitted,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih rating terlebih dahulu.')),
      );
      return;
    }
    if (_commentCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tulis komentar terlebih dahulu.')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final ok = await widget.api
          .postReview(widget.placeId, _rating, _commentCtrl.text.trim());
      if (!mounted) return;
      if (ok) {
        Navigator.pop(context);
        widget.onSubmitted();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Ulasan berhasil dikirim!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengirim ulasan. Coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi kesalahan. Coba lagi.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Text('Ulasan untuk ${widget.placeName}',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142))),
            const SizedBox(height: 16),
            const Text('Rating',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (i) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      i < _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: Colors.amber,
                      size: 36,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            const Text('Komentar',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Bagikan pengalamanmu di tempat ini...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Colors.blueAccent, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Kirim Ulasan',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
