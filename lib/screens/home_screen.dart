import 'package:flutter/material.dart';
import '../models/place_model.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';
import 'favorite_screen.dart';
import 'map_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int? _selectedCategoryId;

  List<CategoryModel> _categories = [];
  List<PlaceModel> _places = [];
  bool _loadingCategories = true;
  bool _loadingPlaces = true;
  String _searchQuery = '';

  final _searchController = TextEditingController();
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadCategories(), _loadPlaces()]);
  }

  Future<void> _loadCategories() async {
    setState(() => _loadingCategories = true);
    try {
      final cats = await _api.getCategories();
      setState(() => _categories = cats);
    } catch (_) {
    } finally {
      setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadPlaces() async {
    setState(() => _loadingPlaces = true);
    try {
      final result = await _api.getPlaces(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
        limit: 20,
      );
      setState(() => _places = result['places'] as List<PlaceModel>);
    } catch (_) {
      setState(() => _places = []);
    } finally {
      setState(() => _loadingPlaces = false);
    }
  }

  void _onCategoryTap(int? categoryId) {
    setState(() => _selectedCategoryId = categoryId);
    _loadPlaces();
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapScreen()),
      ).then((_) => setState(() => _selectedIndex = 0));
      return;
    }
    setState(() => _selectedIndex = index);
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 2:
        return const FavoriteScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeBody();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildHomeBody() {
    return RefreshIndicator(
      color: Colors.blueAccent,
      onRefresh: _loadData,
      child: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              _buildSearchBar(),
              _buildCategoryFilter(),
              _buildPlacesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Halo, Selamat Datang! 👋',
                  style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
              SizedBox(height: 4),
              Text('Mau nugas di mana hari ini?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            ],
          ),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.blue[100],
            backgroundImage: const NetworkImage(
                'https://ui-avatars.com/api/?name=User&background=0D8ABC&color=fff'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: TextField(
          controller: _searchController,
          onSubmitted: (val) {
            setState(() => _searchQuery = val);
            _loadPlaces();
          },
          decoration: InputDecoration(
            hintText: 'Cari workspace, kafe...',
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: const Icon(Icons.search_rounded, color: Colors.blueAccent),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                      _loadPlaces();
                    },
                  )
                : Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text('Kategori',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
        ),
        SizedBox(
          height: 95,
          child: _loadingCategories
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _categories.length + 1,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final cat = isAll ? null : _categories[index - 1];
                    final isSelected = isAll ? _selectedCategoryId == null : _selectedCategoryId == cat!.id;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: GestureDetector(
                        onTap: () => _onCategoryTap(isAll ? null : cat!.id),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.blueAccent : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))],
                              ),
                              child: Icon(
                                isAll ? Icons.apps_rounded : _getCategoryIcon(cat!.icon),
                                color: isSelected ? Colors.white : Colors.blueAccent,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: 64,
                              child: Text(
                                isAll ? 'Semua' : cat!.name,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.blueAccent : Colors.black54),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPlacesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _selectedCategoryId == null ? 'Semua Tempat' : 'Hasil Filter',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
              ),
              if (!_loadingPlaces)
                Text('${_places.length} tempat',
                    style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ],
          ),
        ),
        if (_loadingPlaces)
          const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()))
        else if (_places.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: Text('Tidak ada tempat ditemukan.', style: TextStyle(color: Colors.grey))),
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _places.length,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            itemBuilder: (context, index) {
              final place = _places[index];
              return GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(place: place))),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 6))],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: place.photoUrl != null
                              ? Image.network(place.photoUrl!, width: 90, height: 90, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _placeholderIcon(place))
                              : _placeholderIcon(place),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(6)),
                                child: Text(place.categoryName,
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                              ),
                              const SizedBox(height: 6),
                              Text(place.name,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(place.address,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    place.rating > 0 ? place.rating.toStringAsFixed(1) : 'Baru',
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                                  ),
                                  if (place.priceRange != null) ...[
                                    const Spacer(),
                                    Text(place.priceRange!,
                                        style: const TextStyle(fontSize: 12, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                                  ],
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
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _placeholderIcon(PlaceModel place) {
    return Container(
      width: 90, height: 90, color: Colors.blue[50],
      child: Icon(_getCategoryIcon(place.categoryIcon), color: Colors.blueAccent, size: 36),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.grey[400],
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Peta'),
            BottomNavigationBarItem(icon: Icon(Icons.bookmark_rounded), label: 'Favorit'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
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
