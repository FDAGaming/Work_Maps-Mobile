import 'package:flutter/material.dart';
import '../../models/place_model.dart';
import '../../services/api_service.dart';
import 'admin_edit_place_screen.dart';

class AdminPlacesTab extends StatefulWidget {
  const AdminPlacesTab({super.key});

  @override
  State<AdminPlacesTab> createState() => _AdminPlacesTabState();
}

class _AdminPlacesTabState extends State<AdminPlacesTab> {
  final _api = ApiService();
  List<PlaceModel> _places = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final placesResult = await _api.getAdminPlaces(
          search: _search.isEmpty ? null : _search);
      if (mounted) {
        setState(() {
          _places = placesResult['places'] as List<PlaceModel>;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleVerify(PlaceModel place) async {
    final ok = await _api.verifyPlace(place.id);
    if (ok && mounted) {
      _load();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(place.isVerified
            ? 'Verifikasi dibatalkan.'
            : '✅ Tempat berhasil diverifikasi!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _deletePlace(PlaceModel place) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Tempat',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus "${place.name}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await _api.deletePlace(place.id);
      if (ok && mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${place.name}" dihapus.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  void _openEditScreen({PlaceModel? place}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminEditPlaceScreen(place: place),
      ),
    );
    // Reload jika ada perubahan
    if (changed == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  onSubmitted: (v) {
                    setState(() => _search = v);
                    _load();
                  },
                  decoration: InputDecoration(
                    hintText: 'Cari tempat...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.blueAccent),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                              _load();
                            })
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                onPressed: () => _openEditScreen(),
                backgroundColor: Colors.blueAccent,
                child: const Icon(Icons.add_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _places.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: Colors.blueAccent,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _places.length,
                            itemBuilder: (_, i) => _buildPlaceCard(_places[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildPlaceCard(PlaceModel place) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(place.name,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3142))),
                          ),
                          if (place.isVerified)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.verified_rounded,
                                      color: Colors.green, size: 12),
                                  SizedBox(width: 3),
                                  Text('Verified',
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(place.categoryName,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(place.address,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                const SizedBox(width: 4),
                Text(
                    place.rating > 0
                        ? place.rating.toStringAsFixed(1)
                        : 'Baru',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(width: 10),
                Text('${place.reviewCount} ulasan',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                const Spacer(),
                // Verify button
                _actionButton(
                  icon: place.isVerified
                      ? Icons.cancel_outlined
                      : Icons.verified_outlined,
                  color: place.isVerified ? Colors.orange : Colors.green,
                  tooltip: place.isVerified ? 'Batalkan' : 'Verifikasi',
                  onTap: () => _toggleVerify(place),
                ),
                const SizedBox(width: 6),
                // Edit button
                _actionButton(
                  icon: Icons.edit_outlined,
                  color: Colors.blueAccent,
                  tooltip: 'Edit',
                  onTap: () => _openEditScreen(place: place),
                ),
                const SizedBox(width: 6),
                // Delete button
                _actionButton(
                  icon: Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  tooltip: 'Hapus',
                  onTap: () => _deletePlace(place),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Colors.redAccent, size: 48),
          const SizedBox(height: 12),
          Text(_error ?? 'Terjadi kesalahan',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: _load,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              child: const Text('Coba Lagi',
                  style: TextStyle(color: Colors.white))),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.place_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Belum ada tempat.',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _openEditScreen(),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Tambah Tempat',
                style: TextStyle(color: Colors.white)),
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
          ),
        ],
      ),
    );
  }
}
