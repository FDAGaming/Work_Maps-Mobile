import 'package:flutter/material.dart';
import 'package:work_maps/screens/home_screen.dart'; 
// 1. Tambahkan import untuk map_screen.dart
import 'package:work_maps/screens/map_screen.dart'; 


void main() {
  runApp(const WorkspaceApp());
}

class WorkspaceApp extends StatelessWidget {
  const WorkspaceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workspace Directory',
      debugShowCheckedModeBanner: false, 
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 2. HAPUS properti `home: const HomeScreen(),`
      
      // 3. GUNAKAN sistem Routes untuk mendaftarkan semua halaman
      initialRoute: '/', // Halaman pertama yang dibuka
      routes: {
        '/': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(), // Rute untuk halaman peta
      },
    );
  }
}