import 'package:flutter/material.dart';
import '../../../models/place_model.dart';
import '../../../models/category_model.dart';
import '../../../services/api_service.dart';

class PlaceFormSheet extends StatefulWidget {
  final PlaceModel? place;
  final List<CategoryModel> categories;
  final ApiService api;
  final VoidCallback onSaved;

  const PlaceFormSheet({
    super.key,
    this.place,
    required this.categories,
    required this.api,
    required this.onSaved,
  });

  @override
  State<PlaceFormSheet> createState() => _PlaceFormSheetState();
}

class _PlaceFormSheetState extends State<PlaceFormSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

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

  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _addressCtrl = TextEditingController(text: p?.address ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _latCtrl = TextEditingController(text: p?.lat.toString() ?? '');
    _lngCtrl = TextEditingController(text: p?.lng.toString() ?? '');
    _phoneCtrl = TextEditingController(text: p?.phone ?? '');
    _openHoursCtrl = TextEditingController(text: p?.openHours ?? '');
    _websiteCtrl = TextEditingController(text: p?.website ?? '');
    _priceRangeCtrl = TextEditingController(text: p?.priceRange ?? '');
    _photoUrlCtrl = TextEditingController(text: p?.photoUrl ?? '');
    _tagsCtrl = TextEditingController(text: p?.tags.join(', ') ?? '');
    _selectedCategoryId = p?.categoryId;
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu.')),
      );
      return;
    }
    setState(() => _saving = true);

    final tagsRaw = _tagsCtrl.text.trim();
    final tags = tagsRaw.isNotEmpty
        ? tagsRaw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
        : <String>[];

    final data = {
      'name': _nameCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'lat': double.tryParse(_latCtrl.text.trim()) ?? 0.0,
      'lng': double.tryParse(_lngCtrl.text.trim()) ?? 0.0,
      'category_id': _selectedCategoryId,
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_openHoursCtrl.text.isNotEmpty) 'open_hours': _openHoursCtrl.text.trim(),
      if (_websiteCtrl.text.isNotEmpty) 'website': _websiteCtrl.text.trim(),
      if (_priceRangeCtrl.text.isNotEmpty) 'price_range': _priceRangeCtrl.text.trim(),
      if (_photoUrlCtrl.text.isNotEmpty) 'photo_url': _photoUrlCtrl.text.trim(),
      if (tags.isNotEmpty) 'tags': tags,
    };

    bool ok;
    if (widget.place != null) {
      ok = await widget.api.updatePlace(widget.place!.id, data);
    } else {
      ok = await widget.api.createPlace(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.place != null
            ? '✅ Tempat berhasil diperbarui!'
            : '✅ Tempat berhasil ditambahkan!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Gagal menyimpan. Coba lagi.'),
        backgroundColor: Colors.redAccent,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.place != null;
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40, height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(isEdit ? 'Edit Tempat' : 'Tambah Tempat',
                      style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionLabel('Informasi Dasar'),
                      _field(_nameCtrl, 'Nama Tempat *', Icons.storefront_rounded,
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                      const SizedBox(height: 12),
                      _field(_addressCtrl, 'Alamat *', Icons.location_on_rounded,
                          maxLines: 2,
                          validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
                      const SizedBox(height: 12),
                      _field(_descCtrl, 'Deskripsi', Icons.description_rounded,
                          maxLines: 3),
                      const SizedBox(height: 12),

                      // Kategori
                      DropdownButtonFormField<int>(
                        value: _selectedCategoryId,
                        decoration: _decor('Kategori *', Icons.category_rounded),
                        hint: const Text('Pilih kategori'),
                        items: widget.categories
                            .map((c) => DropdownMenuItem(
                                value: c.id, child: Text(c.name)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedCategoryId = v),
                        validator: (v) =>
                            v == null ? 'Pilih kategori' : null,
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Koordinat'),
                      Row(
                        children: [
                          Expanded(
                            child: _field(_latCtrl, 'Latitude *', Icons.explore_rounded,
                                keyboard: TextInputType.number,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Wajib';
                                  if (double.tryParse(v) == null) return 'Angka';
                                  return null;
                                }),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _field(_lngCtrl, 'Longitude *', Icons.explore_rounded,
                                keyboard: TextInputType.number,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Wajib';
                                  if (double.tryParse(v) == null) return 'Angka';
                                  return null;
                                }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      _sectionLabel('Detail Tambahan'),
                      _field(_phoneCtrl, 'Nomor Telepon', Icons.phone_rounded,
                          keyboard: TextInputType.phone),
                      const SizedBox(height: 12),
                      _field(_openHoursCtrl, 'Jam Operasional',
                          Icons.access_time_rounded,
                          hint: 'Contoh: Senin-Jumat 08.00-22.00'),
                      const SizedBox(height: 12),
                      _field(_websiteCtrl, 'Website', Icons.language_rounded,
                          keyboard: TextInputType.url),
                      const SizedBox(height: 12),
                      _field(
                          _priceRangeCtrl, 'Rentang Harga', Icons.payments_rounded,
                          hint: 'Contoh: Rp 10.000 - Rp 50.000'),
                      const SizedBox(height: 12),
                      _field(_photoUrlCtrl, 'URL Foto', Icons.image_rounded,
                          keyboard: TextInputType.url),
                      const SizedBox(height: 12),
                      _field(_tagsCtrl, 'Tags (pisah koma)', Icons.tag_rounded,
                          hint: 'Contoh: WiFi, AC, Parkir'),
                      const SizedBox(height: 28),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _saving
                              ? const SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5))
                              : Text(
                                  isEdit ? 'Simpan Perubahan' : 'Tambah Tempat',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent)),
    );
  }

  InputDecoration _decor(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Colors.blueAccent, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent)),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboard = TextInputType.text,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboard,
      validator: validator,
      decoration: _decor(label, icon, hint: hint),
    );
  }
}
