import 'package:flutter/material.dart';
import 'package:madtrack/models/sensors_data.dart';
import 'package:madtrack/screens/routes/detail_lux_screen.dart';
import 'package:madtrack/screens/routes/detail_map_screen.dart';
import 'package:madtrack/screens/routes/detail_noise_screen.dart';

class DetailRoutesScreen extends StatefulWidget {
  final SensorsData sensorsData;

  const DetailRoutesScreen({super.key, required this.sensorsData});

  @override
  // ignore: library_private_types_in_public_api
  _DetailRoutesScreenState createState() => _DetailRoutesScreenState();
}

class _DetailRoutesScreenState extends State<DetailRoutesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sensorsData.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.map)),
            Tab(icon: Icon(Icons.volume_up)),
            Tab(icon: Icon(Icons.sunny)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DetailMapScreen(sensorsData: widget.sensorsData),
          _buildNoiseWidget(
            condition: widget.sensorsData.averageNoise == 0,
            text:
                'El ruido no ha sido registrado. No hay detalles adicionales disponibles.',
          ),
          _buildLuxWidget(
            condition: widget.sensorsData.averageLux == 0,
            text:
                'La luz no ha sido registrada. No hay detalles adicionales disponibles.',
          ),
        ],
      ),
    );
  }

  Widget _buildNoiseWidget({required bool condition, required String text}) {
    return condition
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          )
        : DetailNoiseScreen(sensorsData: widget.sensorsData);
  }

  Widget _buildLuxWidget({required bool condition, required String text}) {
    return condition
        ? Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          )
        : DetailLuxScreen(sensorsData: widget.sensorsData);
  }
}
