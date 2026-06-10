import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/place_model.dart';
import '../services/api_service.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final LatLng _initialPosition = const LatLng(-7.5555, 112.2270);

  List<PlaceModel> _places = [];
  bool _loading = true;
  LatLng? _currentUserPosition;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces({double? lat, double? lng}) async {
    setState(() => _loading = true);
    try {
      List<PlaceModel> places;
      if (lat != null && lng != null) {
        places = await _api.getNearby(lat: lat, lng: lng, limit: 50);
      } else {
        final result = await _api.getPlaces(limit: 50);
        places = result['places'] as List<PlaceModel>;
      }
      setState(() => _places = places);
    } catch (_) {
      setState(() => _places = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Layanan GPS mati. Harap nyalakan GPS Anda.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin akses lokasi ditolak.')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin lokasi ditolak permanen. Buka pengaturan HP Anda.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mencari lokasi Anda...')),
    );

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentUserPosition = LatLng(position.latitude, position.longitude);
      });
      _mapController.move(_currentUserPosition!, 16.0);
      // Reload places terdekat berdasarkan posisi user
      await _loadPlaces(lat: position.latitude, lng: position.longitude);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mendapatkan titik koordinat.')),
      );
    }
  }

  void _showPlaceBottomSheet(PlaceModel place) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
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
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: place.photoUrl != null
                        ? Image.network(place.photoUrl!, width: 70, height: 70, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _markerPlaceholder(place))
                        : _markerPlaceholder(place),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(place.name,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        const SizedBox(height: 4),
                        Text(place.categoryName,
                            style: const TextStyle(fontSize: 13, color: Colors.blueAccent, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(place.address,
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              place.rating > 0 ? place.rating.toStringAsFixed(1) : 'Baru',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            if (place.priceRange != null) ...[
                              const SizedBox(width: 8),
                              Text('• ${place.priceRange}',
                                  style: const TextStyle(fontSize: 12, color: Colors.blueAccent)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => DetailScreen(place: place)),
                    );
                  },
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                  label: const Text('Lihat Detail Tempat',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.direktori_kampus.work_maps',
                retinaMode: true,
                maxZoom: 19,
              ),
              if (_currentUserPosition != null)
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _currentUserPosition!,
                      radius: 60,
                      useRadiusInMeter: true,
                      color: Colors.blueAccent.withAlpha(38),
                      borderColor: Colors.blueAccent.withAlpha(102),
                      borderStrokeWidth: 1,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  // Marker tempat dari API
                  ..._places.map((place) => Marker(
                        point: LatLng(place.lat, place.lng),
                        width: 50,
                        height: 50,
                        child: GestureDetector(
                          onTap: () => _showPlaceBottomSheet(place),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3)),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                          ),
                        ),
                      )),
                  // Marker posisi user
                  if (_currentUserPosition != null)
                    Marker(
                      point: _currentUserPosition!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.blueAccent.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 4),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Tombol Back
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Color(0xFF2D3142)),
                ),
              ),
            ),
          ),

          // Loading indicator
          if (_loading)
            const Positioned(
              top: 80,
              left: 0,
              right: 0,
              child: Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Memuat tempat...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getCurrentLocation,
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location_rounded, color: Colors.blueAccent),
      ),
    );
  }

  Widget _markerPlaceholder(PlaceModel place) {
    return Container(
      width: 70, height: 70, color: Colors.blue[50],
      child: Icon(_getCategoryIcon(place.categoryIcon), color: Colors.blueAccent, size: 28),
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
