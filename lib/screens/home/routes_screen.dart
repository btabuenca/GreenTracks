import 'package:flutter/material.dart';
import 'package:madtrack/models/sensors_data.dart';
import 'package:madtrack/screens/routes/detail_routes_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late List<SensorsData> dataList;

  @override
  void initState() {
    super.initState();
    // Inicializa la lista con datos hardcodeados
    dataList = [
      SensorsData(
        name: "Ruta 1",
        distance: 5000, // 5 km
        averageSpeed: 15.5,
        averageNoise: 70.3,
        averageLux: 300,
      ),
      SensorsData(
        name: "Ruta 2",
        distance: 10000, // 10 km
        averageSpeed: 20.0,
        averageNoise: 65.0,
        averageLux: 250,
      ),
      SensorsData(
        name: "Ruta 3",
        distance: 7500, // 7.5 km
        averageSpeed: 18.2,
        averageNoise: 72.5,
        averageLux: 280,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Resumen de Rutas"),
      ),
      body: _listItems(colorScheme),
    );
  }

  Widget _listItems(ColorScheme colorScheme) {
    return dataList.isEmpty
        ? _buildEmptyListMessage()
        : ListView.builder(
      itemCount: dataList.length,
      itemBuilder: (BuildContext context, int index) {
        SensorsData data = dataList[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailRoutesScreen(sensorsData: data),
              ),
            );
          },
          child: Card(
            elevation: 5,
            margin: const EdgeInsets.all(10),
            surfaceTintColor: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 35.0,
                      backgroundColor: colorScheme.primary,
                      child: Icon(
                        Icons.directions_bike,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    title: Text(
                      data.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      children: [
                        _buildIconWithText(Icons.directions_bike,
                            "${(data.distance / 1000).toStringAsFixed(3)} km"),
                        _buildIconWithText(Icons.speed,
                            "${data.averageSpeed.toStringAsFixed(2)} km/h"),
                        _buildIconWithText(Icons.volume_up,
                            "${data.averageNoise.toStringAsFixed(2)} db"),
                        _buildIconWithText(Icons.sunny,
                            "${data.averageLux.toInt()} nits"),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    setState(() {
                      dataList.removeAt(index);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyListMessage() {
    return const Center(
      child: Text(
        "Aún no hay rutas guardadas",
        style: TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildIconWithText(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
