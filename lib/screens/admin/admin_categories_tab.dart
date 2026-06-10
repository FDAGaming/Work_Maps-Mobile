import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/api_service.dart';

class AdminCategoriesTab extends StatefulWidget {
  const AdminCategoriesTab({super.key});

  @override
  State<AdminCategoriesTab> createState() => _AdminCategoriesTabState();
}

class _AdminCategoriesTabState extends State<AdminCategoriesTab> {
  final _api = ApiService();
  List<CategoryModel> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final cats = await _api.getCategories();
      if (mounted) setState(() => _categories = cats);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _openForm({CategoryModel? cat}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        category: cat,
        api: _api,
        onSaved: _load,
      ),
    );
  }

  Future<void> _delete(CategoryModel cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Kategori',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin hapus kategori "${cat.name}"?'),
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
            child:
                const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await _api.deleteCategory(cat.id);
      if (ok && mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${cat.name}" dihapus.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_categories.length} Kategori',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3142),
                      fontSize: 15)),
              ElevatedButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                label: const Text('Tambah', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _categories.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: Colors.blueAccent,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _categories.length,
                            itemBuilder: (_, i) =>
                                _buildCatCard(_categories[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildCatCard(CategoryModel cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: _parseColor(cat.color).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_getCategoryIcon(cat.icon),
              color: _parseColor(cat.color), size: 22),
        ),
        title: Text(cat.name,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Color(0xFF2D3142))),
        subtitle: Text('${cat.placeCount} tempat',
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _iconBtn(Icons.edit_outlined, Colors.blueAccent,
                () => _openForm(cat: cat)),
            const SizedBox(width: 6),
            _iconBtn(Icons.delete_outline_rounded, Colors.redAccent,
                () => _delete(cat)),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
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
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent),
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
          Icon(Icons.category_outlined, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Belum ada kategori.',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      final h = hex.replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return Colors.blueAccent;
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
}

// ── CATEGORY FORM SHEET ───────────────────────────────────────────────────

class _CategoryFormSheet extends StatefulWidget {
  final CategoryModel? category;
  final ApiService api;
  final VoidCallback onSaved;

  const _CategoryFormSheet(
      {this.category, required this.api, required this.onSaved});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _colorCtrl;
  bool _saving = false;

  final _iconOptions = [
    'coffee', 'utensils', 'copy', 'credit-card',
    'home', 'shopping-bag', 'heart', 'building', 'wind',
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    _iconCtrl = TextEditingController(text: widget.category?.icon ?? 'building');
    _colorCtrl =
        TextEditingController(text: widget.category?.color ?? '#4285F4');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _iconCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    bool ok;
    if (widget.category != null) {
      ok = await widget.api.updateCategory(
          widget.category!.id, _nameCtrl.text.trim(),
          _iconCtrl.text.trim(), _colorCtrl.text.trim());
    } else {
      ok = await widget.api.createCategory(
          _nameCtrl.text.trim(), _iconCtrl.text.trim(), _colorCtrl.text.trim());
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.category != null
            ? '✅ Kategori diperbarui!'
            : '✅ Kategori ditambahkan!'),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Text(
                widget.category != null ? 'Edit Kategori' : 'Tambah Kategori',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3142)),
              ),
              const SizedBox(height: 16),
              _buildField(_nameCtrl, 'Nama Kategori', Icons.category_rounded,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 12),
              // Icon dropdown
              DropdownButtonFormField<String>(
                value: _iconOptions.contains(_iconCtrl.text)
                    ? _iconCtrl.text
                    : _iconOptions.first,
                decoration: _inputDecoration('Icon', Icons.image_rounded),
                items: _iconOptions
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => _iconCtrl.text = v ?? '',
              ),
              const SizedBox(height: 12),
              _buildField(_colorCtrl, 'Warna (hex, contoh: #4285F4)',
                  Icons.color_lens_rounded,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
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
                          width: 20, height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5))
                      : Text(
                          widget.category != null ? 'Simpan Perubahan' : 'Tambah Kategori',
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
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 1.5)),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }
}
