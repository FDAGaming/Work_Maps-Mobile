import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminUsersTab extends StatefulWidget {
  const AdminUsersTab({super.key});

  @override
  State<AdminUsersTab> createState() => _AdminUsersTabState();
}

class _AdminUsersTabState extends State<AdminUsersTab> {
  final _api = ApiService();
  List<dynamic> _users = [];
  List<dynamic> _filtered = [];
  bool _loading = true;
  String? _error;
  final _searchCtrl = TextEditingController();

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
      final users = await _api.getAdminUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _filtered = users;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filterSearch(String query) {
    setState(() {
      _filtered = _users.where((u) {
        final name = (u['name'] ?? '').toString().toLowerCase();
        final email = (u['email'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase()) ||
            email.contains(query.toLowerCase());
      }).toList();
    });
  }

  Future<void> _changeRole(Map<String, dynamic> user) async {
    final current = user['role'] ?? 'user';
    final newRole = current == 'admin' ? 'user' : 'admin';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ubah Role',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            'Ubah role "${user['name']}" dari $current menjadi $newRole?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Ubah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await _api.updateUserRole(user['id'], newRole);
      if (ok && mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Role diubah menjadi $newRole.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  Future<void> _toggleActive(Map<String, dynamic> user) async {
    final isActive = user['is_active'] ?? true;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isActive ? 'Nonaktifkan User' : 'Aktifkan User',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            '${isActive ? 'Nonaktifkan' : 'Aktifkan'} akun "${user['name']}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child:
                  const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.orange : Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text(isActive ? 'Nonaktifkan' : 'Aktifkan',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final ok = await _api.toggleUserActive(user['id']);
      if (ok && mounted) {
        _load();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Akun "${user['name']}" ${isActive ? 'dinonaktifkan' : 'diaktifkan'}.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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
          child: TextField(
            controller: _searchCtrl,
            onChanged: _filterSearch,
            decoration: InputDecoration(
              hintText: 'Cari nama atau email...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Colors.blueAccent),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        _filterSearch('');
                      })
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        if (!_loading && _error == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_filtered.length} user',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _buildError()
                  : _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: Colors.blueAccent,
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _buildUserCard(_filtered[i]),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final name = user['name'] ?? '-';
    final email = user['email'] ?? '-';
    final role = user['role'] ?? 'user';
    final isActive = user['is_active'] ?? true;
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase()
        : 'U';
    final createdAt = user['created_at'];

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
        border: !isActive
            ? Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 1)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: role == 'admin'
                  ? Colors.blueAccent.withValues(alpha: 0.15)
                  : Colors.grey[100]!,
              child: Text(initials,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: role == 'admin'
                          ? Colors.blueAccent
                          : Colors.grey[600],
                      fontSize: 14)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Color(0xFF2D3142))),
                      ),
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: role == 'admin'
                              ? Colors.blue[50]
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(role,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: role == 'admin'
                                    ? Colors.blueAccent
                                    : Colors.grey[600])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(email,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  if (createdAt != null) ...[
                    const SizedBox(height: 2),
                    Text('Bergabung: ${_formatDate(createdAt)}',
                        style:
                            TextStyle(fontSize: 11, color: Colors.grey[400])),
                  ],
                  if (!isActive)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text('⚠️ Akun Nonaktif',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.orange,
                              fontWeight: FontWeight.w600)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Action buttons
            Column(
              children: [
                _iconBtn(
                  icon: role == 'admin'
                      ? Icons.person_outline_rounded
                      : Icons.admin_panel_settings_outlined,
                  color: Colors.blueAccent,
                  tooltip: role == 'admin' ? 'Jadikan User' : 'Jadikan Admin',
                  onTap: () => _changeRole(user),
                ),
                const SizedBox(height: 6),
                _iconBtn(
                  icon: isActive
                      ? Icons.block_rounded
                      : Icons.check_circle_outline_rounded,
                  color: isActive ? Colors.orange : Colors.green,
                  tooltip: isActive ? 'Nonaktifkan' : 'Aktifkan',
                  onTap: () => _toggleActive(user),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBtn({
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
          Icon(Icons.people_outline_rounded,
              size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          const Text('Tidak ada user ditemukan.',
              style: TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
