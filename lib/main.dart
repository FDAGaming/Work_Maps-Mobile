import 'package:flutter/material.dart';
import 'package:work_maps/screens/home_screen.dart';
import 'package:work_maps/screens/login_screen.dart';
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
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/map': (context) => const MapScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}