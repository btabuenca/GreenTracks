import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  Position? _currentPosition;
  final TextEditingController _reportController = TextEditingController();
  final TextEditingController _routeController = TextEditingController();
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  bool _mapInitialized = false; // Para asegurarnos de que el mapa se centra solo una vez

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _fetchReports();
  }

  // Método para obtener la ubicación actual
  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        return;
      }
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });

    // Centrar el mapa en la posición actual al obtenerla
    if (_mapInitialized) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

// Método para obtener reportes desde la API y añadir marcadores
  Future<void> _fetchReports() async {
    const url = 'https://flow.iot.etsisi.upm.es/sutee/telemetry?device=1';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          Set<Marker> newMarkers = {};

          for (var report in data) {
            if (report is Map<String, dynamic>) {
              final timestamp = report['timestamp_server'];
              final latitude = report['latitude'];
              final longitude = report['longitude'];
              final dataset = report['dataset'];

              // Validar y manejar datos
              if (timestamp is String &&
                  latitude is double &&
                  longitude is double) {
                String infoTitle = 'Sin título';
                String infoSnippet = 'Sin descripción';

                if (dataset != null && dataset is Map<String, dynamic>) {
                  infoTitle = dataset['metadata']?.toString() ?? infoTitle;
                }

                newMarkers.add(
                  Marker(
                    markerId: MarkerId(timestamp + latitude.toString() + longitude.toString()),
                    position: LatLng(latitude, longitude),
                    infoWindow: InfoWindow(
                      title: infoTitle,
                      snippet: infoSnippet,
                    ),
                  ),
                );
              }
            }
          }

          setState(() {
            _markers = newMarkers;
          });
        } else {
          throw Exception('La respuesta no contiene una lista válida.');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar reportes: ${response.statusCode}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }



  // Método para enviar un nuevo reporte
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

      String jsonBody = json.encode(reportData);

      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {
            "Content-Type": "application/json",
          },
          body: jsonBody,
        );

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reporte enviado correctamente')),
          );
          _fetchReports(); // Actualizar los marcadores después de enviar un reporte
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al enviar el reporte: ${response.statusCode}')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese un reporte y permita la geolocalización')),
      );
    }
  }

  // Configuración del controlador del mapa
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _mapInitialized = true;
    });

    // Centrar el mapa en la ubicación actual si ya está disponible
    if (_currentPosition != null) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spot observations'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _currentPosition != null
                    ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                    : const LatLng(40.3897278, -3.6280647), // Ubicación predeterminada si la ubicación actual no está disponible
                zoom: 16.0,
              ),
              markers: _markers,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _currentPosition == null
                    ? const CircularProgressIndicator()
                    : Text(
                    'Your position Lat: ${_currentPosition?.latitude}, Lon: ${_currentPosition?.longitude}, Alt: ${_currentPosition?.altitude}'),
                const SizedBox(height: 20),
                TextField(
                  controller: _reportController,
                  maxLines: 2,
                  textAlignVertical: TextAlignVertical.top, // Alineación en la parte superior
                  decoration: const InputDecoration(
                    labelText: 'Introduce an observation on your current location',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _routeController,
                  maxLines: 1,
                  textAlignVertical: TextAlignVertical.top, // Alineación en la parte superior
                  decoration: const InputDecoration(
                    labelText: 'Route name (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitReport,
                  child: const Text('Save Spot'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}