import 'package:flutter/material.dart';
import 'package:madtrack/screens/home/map_screen.dart';

class PublicTransportScreen extends StatelessWidget {
  const PublicTransportScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public transport'),
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

