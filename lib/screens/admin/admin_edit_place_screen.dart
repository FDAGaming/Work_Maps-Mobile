import 'package:flutter/material.dart';
import '../../models/place_model.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';

class AdminEditPlaceScreen extends StatefulWidget {
  /// Jika [place] null → mode tambah, jika ada → mode edit
  final PlaceModel? place;

  const AdminEditPlaceScreen({super.key, this.place});

  @override
  State<AdminEditPlaceScreen> createState() => _AdminEditPlaceScreenState();
}

class _AdminEditPlaceScreenState extends State<AdminEditPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();

  // Controllers
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _openHoursCtrl;
  late final TextEditingController _websiteCtrl;
  late final TextEditingController _priceRangeCtrl;
  late final TextEditingController _photoUrlCtrl;
  late final TextEditingController _tagsCtrl;

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  bool _loadingCategories = true;
  bool _saving = false;

  bool get _isEdit => widget.place != null;

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _latCtrl = TextEditingController(
        text: p != null ? p.lat.toString() : '');
    _lngCtrl = TextEditingController(
        text: p != null ? p.lng.toString() : '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _openHoursCtrl = TextEditingController(text: p?.openHours ?? '');
    _websiteCtrl = TextEditingController(text: p?.website ?? '');
    _priceRangeCtrl = TextEditingController(text: p?.priceRange ?? '');
    _photoUrlCtrl = TextEditingController(text: p?.photoUrl ?? '');
    _tagsCtrl =
        TextEditingController(text: p?.tags.isNotEmpty == true ? p!.tags.join(', ') : '');
    _selectedCategoryId = (p?.categoryId != null && p!.categoryId > 0) ? p.categoryId : null;
    _loadCategories();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _descCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    _phoneCtrl.dispose();
    _openHoursCtrl.dispose();
    _websiteCtrl.dispose();
    _priceRangeCtrl.dispose();
    _photoUrlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _api.getCategories();
      if (mounted) {
        setState(() {
          _categories = cats;
          _loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      _showSnack('Pilih kategori terlebih dahulu.', isError: true);
      return;
    }

    setState(() => _saving = true);

    final tagsRaw = _tagsCtrl.text.trim();
    final tags = tagsRaw.isNotEmpty
        ? tagsRaw
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList()
        : <String>[];

    final data = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'lat': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
      'lng': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
      'category_id': _selectedCategoryId,
      if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_openHoursCtrl.text.trim().isNotEmpty)
        'open_hours': _openHoursCtrl.text.trim(),
      if (_websiteCtrl.text.trim().isNotEmpty)
        'website': _websiteCtrl.text.trim(),
      if (_priceRangeCtrl.text.trim().isNotEmpty)
        'price_range': _priceRangeCtrl.text.trim(),
      if (_photoUrlCtrl.text.trim().isNotEmpty)
        'photo_url': _photoUrlCtrl.text.trim(),
      if (tags.isNotEmpty) 'tags': tags,
    };

    final bool ok;
    if (_isEdit) {
      ok = await _api.updatePlace(widget.place!.id, data);
    } else {
      ok = await _api.createPlace(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context, true); // true = data berubah, trigger reload
      _showSnack(
        _isEdit ? '✅ Tempat berhasil diperbarui!' : '✅ Tempat berhasil ditambahkan!',
        isError: false,
      );
    } else {
      _showSnack('Gagal menyimpan. Coba lagi.', isError: true);
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D3142)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Tempat' : 'Tambah Tempat',
          style: const TextStyle(
            color: Color(0xFF2D3142),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saving ? null : _save,
              style: TextButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Simpan',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: _loadingCategories
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // ── FOTO PREVIEW ─────────────────────────────────
                  if (_photoUrlCtrl.text.isNotEmpty)
                    _buildPhotoPreview(),

                  // ── INFORMASI DASAR ───────────────────────────────
                  _sectionCard(
                    title: 'Informasi Dasar',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _field(
                        _nameCtrl,
                        'Nama Tempat',
                        Icons.storefront_rounded,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _addressCtrl,
                        'Alamat Lengkap',
                        Icons.location_on_rounded,
                        maxLines: 2,
                        required: true,
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _descCtrl,
                        'Deskripsi',
                        Icons.description_rounded,
                        maxLines: 4,
                        hint: 'Ceritakan tentang tempat ini...',
                      ),
                      const SizedBox(height: 14),
                      // Kategori dropdown
                      DropdownButtonFormField<int>(
                        value: _categories.any((c) => c.id == _selectedCategoryId)
                            ? _selectedCategoryId
                            : null,
                        isExpanded: true,
                        decoration:
                            _decor('Kategori', Icons.category_rounded),
                        hint: const Text('Pilih kategori'),
                        items: _categories
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                        validator: (v) =>
                            v == null ? 'Pilih kategori' : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── KOORDINAT ─────────────────────────────────────
                  _sectionCard(
                    title: 'Koordinat',
                    icon: Icons.map_rounded,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _field(
                              _latCtrl,
                              'Latitude',
                              Icons.south_rounded,
                              keyboard: TextInputType.number,
                              required: true,
                              hint: '-7.5555',
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Wajib';
                                if (double.tryParse(v) == null) {
                                  return 'Format angka';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(
                              _lngCtrl,
                              'Longitude',
                              Icons.east_rounded,
                              keyboard: TextInputType.number,
                              required: true,
                              hint: '112.2270',
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Wajib';
                                if (double.tryParse(v) == null) {
                                  return 'Format angka';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                color: Colors.blueAccent, size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Gunakan Google Maps untuk mendapatkan koordinat yang akurat.',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.blueAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── KONTAK & JAM ──────────────────────────────────
                  _sectionCard(
                    title: 'Kontak & Jam Operasional',
                    icon: Icons.contact_phone_rounded,
                    children: [
                      _field(
                        _phoneCtrl,
                        'Nomor Telepon',
                        Icons.phone_rounded,
                        keyboard: TextInputType.phone,
                        hint: '0812-3456-7890',
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _openHoursCtrl,
                        'Jam Operasional',
                        Icons.access_time_rounded,
                        hint: 'Senin-Jumat 08.00–22.00',
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _websiteCtrl,
                        'Website',
                        Icons.language_rounded,
                        keyboard: TextInputType.url,
                        hint: 'https://example.com',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── HARGA & FOTO ──────────────────────────────────
                  _sectionCard(
                    title: 'Harga & Foto',
                    icon: Icons.image_rounded,
                    children: [
                      _field(
                        _priceRangeCtrl,
                        'Rentang Harga',
                        Icons.payments_rounded,
                        hint: 'Rp 10.000 – Rp 50.000',
                      ),
                      const SizedBox(height: 14),
                      _field(
                        _photoUrlCtrl,
                        'URL Foto Utama',
                        Icons.image_outlined,
                        keyboard: TextInputType.url,
                        hint: 'https://...',
                        onChanged: (_) => setState(() {}),
                      ),
                      // Live preview foto
                      if (_photoUrlCtrl.text.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _photoUrlCtrl.text.trim(),
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text('URL foto tidak valid',
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── TAGS / FASILITAS ──────────────────────────────
                  _sectionCard(
                    title: 'Fasilitas & Tags',
                    icon: Icons.tag_rounded,
                    children: [
                      _field(
                        _tagsCtrl,
                        'Tags (pisahkan dengan koma)',
                        Icons.label_outline_rounded,
                        hint: 'WiFi, AC, Parkir, Colokan, QRIS',
                      ),
                      const SizedBox(height: 10),
                      // Preview tags
                      if (_tagsCtrl.text.trim().isNotEmpty)
                        _buildTagPreview(_tagsCtrl.text),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── TOMBOL SIMPAN ─────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : Icon(
                              _isEdit
                                  ? Icons.save_rounded
                                  : Icons.add_location_alt_rounded,
                              color: Colors.white,
                            ),
                      label: Text(
                        _isEdit ? 'Simpan Perubahan' : 'Tambah Tempat',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  // ── WIDGETS HELPER ─────────────────────────────────────────────────────

  Widget _buildPhotoPreview() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          _photoUrlCtrl.text.trim(),
          height: 180,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _buildTagPreview(String raw) {
    final tags = raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: tags
          .map((t) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(t,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600)),
              ))
          .toList(),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(icon, color: Colors.blueAccent, size: 18),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3142))),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _decor(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: Colors.grey[200]!, width: 1)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.blueAccent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.redAccent, width: 1.5)),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? hint,
    bool required = false,
    void Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      onChanged: onChanged,
      validator: validator ??
          (required
              ? (v) => (v == null || v.trim().isEmpty) ? '$label wajib diisi' : null
              : null),
      decoration: _decor(
        required ? '$label *' : label,
        icon,
        hint: hint,
      ),
    );
  }
}
