import 'package:flutter/material.dart';
import 'package:madtrack/models/sensors_data.dart';
import 'package:madtrack/widgets/chart.dart';

class DetailNoiseScreen extends StatelessWidget {
  final SensorsData sensorsData;

  const DetailNoiseScreen({
    super.key,
    required this.sensorsData,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Chart(
            valuesList: sensorsData.noise,
            time: sensorsData.time,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),
          const Text(
            "Media de ruido en la ruta",
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(context, Icons.volume_up,
              "${sensorsData.averageNoise.toStringAsFixed(2)} DB"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String value) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: colorScheme.onPrimary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, color: colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }
}
