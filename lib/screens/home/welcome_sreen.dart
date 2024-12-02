import 'package:flutter/material.dart';
import 'package:madtrack/screens/home/map_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa - GreenTracks'),
      ),
      body: Container(
        color: const Color(0xFFE0E0E0),
        child: const SizedBox(
          height: double.infinity,
          child: MapScreen(),
        ),
      ),
    );
  }
}
