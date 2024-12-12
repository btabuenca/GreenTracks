import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'telemetry_map_screen.dart'; // Importa la pantalla de mapa

/// A screen where users can report their observations about their current location.
class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  _ReportScreenState createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  /// Stores the user's current location.
  Position? _currentPosition;

  /// Controller for managing text input for the report.
  final TextEditingController _reportController = TextEditingController();

  /// Controller for managing text input for the route.
  final TextEditingController _routeController = TextEditingController();

  /// Stream subscription for listening to location updates.
  late StreamSubscription<Position> _positionStream;

  /// List of route names for autocomplete functionality.
  List<String> _routes = [];

  /// Indicates if the routes are being loaded.
  bool _isLoadingRoutes = true;

  @override
  void initState() {
    super.initState();
    _initializeLocationUpdates();
    _fetchRoutes(); // Fetch routes when the widget is initialized.
  }

  @override
  void dispose() {
    _positionStream.cancel(); // Cancel location updates when the widget is disposed.
    super.dispose();
  }

  /// Initializes location updates.
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

    // Listen to the continuous stream of location updates.
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      setState(() {
        _currentPosition = position;
      });
    });
  }

  /// Fetches route data from an API.
  Future<void> _fetchRoutes() async {
    const url = 'https://flow.iot.etsisi.upm.es/sutee/routes?device=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            _routes = data.map<String>((item) => item['route'].toString()).toList();
            _isLoadingRoutes = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch routes: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _isLoadingRoutes = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching routes: $error')),
      );
    }
  }

  /// Sends the user's report to an API.
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
    return GestureDetector(
      onHorizontalDragEnd: (details) {
        // Navega a la pantalla de mapa al hacer swipe
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const TelemetryMapScreen(),
          ),
        );
      },
      child: Scaffold(
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
                      _isLoadingRoutes
                          ? const CircularProgressIndicator()
                          : Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) {
                            return const Iterable<String>.empty();
                          }
                          return _routes.where((route) => route
                              .toLowerCase()
                              .contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (String selectedRoute) {
                          _routeController.text = selectedRoute;
                        },
                        fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(
                              labelText: 'Route name (Optional)',
                              border: OutlineInputBorder(),
                            ),
                          );
                        },
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
      ),
    );
  }
}
