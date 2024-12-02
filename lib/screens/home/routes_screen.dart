import 'package:flutter/material.dart';
import 'package:madtrack/controllers/database_controller.dart';
import 'package:madtrack/models/data_manager.dart';
import 'package:madtrack/models/sensors_data.dart';
import 'package:madtrack/screens/routes/detail_routes_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final DataManager dataManager = DataManager();
  late List<SensorsData> dataList;

  @override
  void initState() {
    super.initState();
    dataList = dataManager.dataList;
    dataManager.onDataChange = _updateDataList;
  }

  void _updateDataList() {
    setState(() {
      dataList = dataManager.dataList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return _listItems(colorScheme);
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
                          dataManager.deleteData(index);
                          DatabaseController().deleteData(data.firebaseId);
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
