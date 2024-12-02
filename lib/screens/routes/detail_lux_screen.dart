import 'package:flutter/material.dart';
import 'package:madtrack/models/sensors_data.dart';
import 'package:madtrack/widgets/chart.dart';

class DetailLuxScreen extends StatelessWidget {
  final SensorsData sensorsData;

  const DetailLuxScreen({
    super.key,
    required this.sensorsData,
  });

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    List<double?> valueListDouble =
        sensorsData.lux.map((e) => e?.toDouble()).toList();
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Chart(
            valuesList: valueListDouble,
            time: sensorsData.time,
            colorScheme: colorScheme,
          ),
          const SizedBox(height: 20),
          const Text(
            "Media de luz en la ruta",
            style: TextStyle(fontSize: 30),
          ),
          const SizedBox(height: 10),
          _buildInfoRow(context, Icons.sunny,
              "${sensorsData.averageLux.toStringAsFixed(2)} Nits"),
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
