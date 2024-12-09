import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';


class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Position? _currentPosition;
  final TextEditingController _reportController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  late StreamSubscription<Position> _positionStream;

  @override
  void initState() {
    super.initState();
    _initializeLocationUpdates();
  }

  @override
  void dispose() {
    _positionStream.cancel(); // Detener la escucha de actualizaciones cuando se destruya la pantalla
    super.dispose();
  }

  // Método para inicializar las actualizaciones automáticas de ubicación
  void _initializeLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled.')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are permanently denied.')),
        );
        return;
      }
    }

    // Escucha el flujo continuo de actualizaciones de ubicación
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Actualizar solo si se mueve más de 10 metros
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  // Método para enviar el reporte
  Future<void> _submitReport() async {
    if (_reportController.text.isNotEmpty && _currentPosition != null) {
      const url = 'https://flow.iot.etsisi.upm.es/sutee/telemetry';
      Map<String, dynamic> reportData = {
        "id_device": 1,
        "route": _routeController.text,
        "latitude": _currentPosition?.latitude,
        "longitude": _currentPosition?.longitude,
        "altitude": _currentPosition?.altitude,
        "dataset": {
          "metadata": _reportController.text,
        }
      };

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
          },
          body: json.encode(reportData),
        );
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report saved successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving report: ${response.statusCode}')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a report and allow geolocation')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot Observations'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _currentPosition == null
                        ? const CircularProgressIndicator()
                        : Text(
                      'Your position:\n'
                          'Lat: ${_currentPosition?.latitude},\n'
                          'Lon: ${_currentPosition?.longitude},\n'
                          'Alt: ${_currentPosition?.altitude}',
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _reportController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Observation about your location',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _routeController,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        labelText: 'Route name (Optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitReport,
                      child: const Text('Save Observation'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
