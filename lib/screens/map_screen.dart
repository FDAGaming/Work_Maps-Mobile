import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controller khusus untuk OpenStreetMap
  final MapController _mapController = MapController();
  
  // Titik tengah awal (Contoh: Surabaya)
  final LatLng _initialPosition = const LatLng(-7.2673, 112.7521);
  
  List<Marker> _markers = [];

  @override
  void initState() {
    super.initState();
    _loadMockMarkers();
  }

  // Memuat data mock menjadi Marker Widget
  void _loadMockMarkers() {
    final mockPlaces = [
      {
        'id': '1',
        'name': 'Kafe Literasi',
        'category': 'Cafe',
        'lat': -7.2680,
        'lng': 112.7510,
        'distance': '450 m',
        'rating': 4.8
      },
      {
        'id': '2',
        'name': 'Fotokopi Jaya',
        'category': 'Fotokopi',
        'lat': -7.2660,
        'lng': 112.7535,
        'distance': '120 m',
        'rating': 4.5
      },
    ];

    setState(() {
      _markers = mockPlaces.map((place) {
        return Marker(
          point: LatLng(place['lat'] as double, place['lng'] as double),
          width: 50,
          height: 50,
          // Di flutter_map, marker adalah widget bebas, jadi kita bisa membuatnya sangat kustom
          child: GestureDetector(
            onTap: () => _showPlaceBottomSheet(place),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        );
      }).toList();
    });
  }

// Desain Bottom Sheet Modern
  void _showPlaceBottomSheet(Map<String, dynamic> place) {
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
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.blueAccent, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place['name'],
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${place['category']} • Jarak: ${place['distance']}',
                          style: const TextStyle(fontSize: 14, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              place['rating'].toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  // UBAHAN: Ganti fungsi onPressed di sini
                  onPressed: () {
                    Navigator.pop(context); // tutup bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(place: place),
                      ),
                    );
                  },
                  // UBAHAN: Ganti ikon agar lebih sesuai dengan "Detail"
                  icon: const Icon(Icons.info_outline_rounded, color: Colors.white),
                  // UBAHAN: Ganti teks label
                  label: const Text(
                    'Lihat Detail Tempat',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
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
          // 1. Lapisan Dasar: OpenStreetMap via flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialPosition,
              initialZoom: 15.0,
            ),
            children: [
              // Mengambil data gambar peta (Tiles) dari server gratis OSM
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.work_maps',
              ),
              // Lapisan Marker di atas peta
              MarkerLayer(
                markers: _markers,
              ),
            ],
          ),
          
          // 2. Lapisan Atas: Tombol Back Custom
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: InkWell(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 48,
                  height: 48,
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
        ],
      ),
      
      // FAB untuk menuju lokasi GPS
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Nanti integrasikan geolocator di sini, sementara kita arahkan ulang ke tengah peta
          _mapController.move(_initialPosition, 16.0);
        },
        backgroundColor: Colors.white,
        child: const Icon(Icons.my_location_rounded, color: Colors.blueAccent),
      ),
    );
  }
}