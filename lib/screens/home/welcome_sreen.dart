import 'package:flutter/material.dart';
import 'package:madtrack/widgets/routes_summary.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:madtrack/controllers/database_controller.dart';
import 'package:madtrack/controllers/sensors_controller.dart';
import 'package:madtrack/models/data_manager.dart';
import 'package:madtrack/models/sensors_data.dart';
import 'package:madtrack/screens/home/map_screen.dart';
import 'package:madtrack/widgets/save_route.dart';
import 'package:madtrack/widgets/weather.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool isTracking = false;
  SensorController sensorController = SensorController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Text(
            'SUTEE MadTrack!',
            style: TextStyle(
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 16.0),
          Container(
            color: const Color(0xFFE0E0E0),
            child: const SizedBox(
              height: 380.0,
              child: MapScreen(),
            ),
          ),
          const SizedBox(height: 16.0),
          const Row(
            children: [
              Text(
                '¿Quieres comenzar una nueva ruta?',
                style: TextStyle(
                  fontSize: 18.0,
                ),
              ),
              SizedBox(width: 5),
              Tooltip(
                margin: EdgeInsets.symmetric(vertical: 2, horizontal: 20),
                preferBelow: false,
                showDuration: Duration(seconds: 3),
                message:
                    'Haz zoom en el mapa para ver las estaciones disponibles',
                triggerMode: TooltipTriggerMode.tap,
                child: Icon(Icons.help, size: 25.0),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          FilledButton(
            onPressed: () async {
              bool microphoneGranted = await Permission.microphone.isGranted;
              bool locationGranted = await Permission.location.isGranted;

              if (!microphoneGranted || !locationGranted) {
                await _requestPermissions();
              } else {
                _toggleTracking();
              }
            },
            style: FilledButton.styleFrom(
              elevation: 5.0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isTracking ? Icons.stop : Icons.directions_bike,
                ),
                const SizedBox(width: 8.0),
                Text(
                  isTracking ? 'Detener' : 'Comenzar',
                ),
              ],
            ),
          ),
          const SizedBox(height: 60.0),
          const WeatherForecastWidget(),
          const SizedBox(height: 60.0),
          const RoutesSummary(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.microphone,
      Permission.location,
    ].request();
    if (statuses[Permission.microphone] != PermissionStatus.granted ||
        statuses[Permission.location] != PermissionStatus.granted) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Los permisos de micrófono y ubicación son necesarios para comenzar el seguimiento.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                openAppSettings();
              },
              child: const Text(
                'Abrir configuración',
              ),
            ),
          ],
        ),
      ));
    } else {
      _toggleTracking();
    }
  }

  void _toggleTracking() {
    setState(() {
      isTracking = !isTracking;
    });
    if (isTracking) {
      sensorController.startTracking();
    } else {
      SensorsData sensorsData = sensorController.stopTracking();
      sensorsData.calculateData();
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return SaveRoute(
            onSave: (name) async {
              sensorsData.name = name;
              await DatabaseController().addData(sensorsData);
              DataManager().updateData();
            },
          );
        },
      );
    }
  }
}
