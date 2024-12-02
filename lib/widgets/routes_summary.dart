import 'package:flutter/material.dart';
import 'package:madtrack/models/data_manager.dart';
import 'package:madtrack/models/sensors_data.dart';

class RoutesSummary extends StatefulWidget {
  const RoutesSummary({super.key});

  @override
  State<RoutesSummary> createState() => _RoutesSummaryState();
}

class _RoutesSummaryState extends State<RoutesSummary> {
  final DataManager dataManager = DataManager();
  late List<SensorsData> dataList;
  double? distance;
  double? averageSpeed;
  double? noiseLevel;
  double? ambientLight;

  @override
  void initState() {
    super.initState();
    dataList = dataManager.dataList;
    dataManager.onValuesChange = _updateDataList;
    updateValues();
  }

  void _updateDataList() {
    setState(() {
      dataList = dataManager.dataList;
      updateValues();
    });
  }

  void updateValues() {
    distance = _getDistance();
    averageSpeed = _getAverageSpeed();
    noiseLevel = _getNoiseLevel();
    ambientLight = _getAmbientLight();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'La media de tus rutas',
          style: TextStyle(
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 20.0),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildGridItem(
              Icons.directions_bike,
              'Distancia',
              distance != null
                  ? '${(distance! / 1000).toStringAsFixed(3)} km'
                  : 'Sin datos',
            ),
            _buildGridItem(
              Icons.speed,
              'Velocidad',
              averageSpeed != null
                  ? '${averageSpeed!.toStringAsFixed(2)} km/h'
                  : 'Sin datos',
            ),
            _buildGridItem(
              Icons.volume_up,
              'Ruido',
              noiseLevel != null
                  ? '${noiseLevel!.toStringAsFixed(2)} db'
                  : 'Sin datos',
            ),
            _buildGridItem(
              Icons.sunny,
              'Luz ambiental',
              ambientLight != null
                  ? '${ambientLight!.toInt()} nits'
                  : 'Sin datos',
            ),
          ],
        ),
      ],
    );
  }

  double? _getDistance() {
    if (dataList.isNotEmpty) {
      double totalDistance = 0.0;
      for (var data in dataList) {
        totalDistance += data.distance;
      }
      return totalDistance / dataList.length;
    }
    return null;
  }

  double? _getAverageSpeed() {
    if (dataList.isNotEmpty) {
      double totalSpeed = 0.0;
      for (var data in dataList) {
        totalSpeed += data.averageSpeed;
      }
      return totalSpeed / dataList.length;
    }
    return null;
  }

  double? _getNoiseLevel() {
    if (dataList.isNotEmpty) {
      double totalNoise = 0.0;
      int counter = 0;
      for (var data in dataList) {
        totalNoise += data.averageNoise;
        if (data.averageNoise != 0) counter++;
      }
      return totalNoise / counter;
    }
    return null;
  }

  double? _getAmbientLight() {
    if (dataList.isNotEmpty) {
      double totalLux = 0.0;
      int counter = 0;
      for (var data in dataList) {
        totalLux += data.averageLux;
        if (data.averageLux != 0) counter++;
      }
      return totalLux / counter;
    }
    return null;
  }

  Widget _buildGridItem(IconData iconData, String title, String label) {
    return Card(
      elevation: 10.0,
      surfaceTintColor: Colors.white,
      margin: const EdgeInsets.all(6.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 48.0,
          ),
          const SizedBox(height: 10.0),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18.0,
            ),
          ),
        ],
      ),
    );
  }
}
