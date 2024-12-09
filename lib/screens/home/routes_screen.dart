import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  Position? _currentPosition;
  late GoogleMapController _mapController;
  Set<Marker> _markers = {};
  bool _mapInitialized = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Actualiza los marcadores cada vez que se muestra la pantalla
    _fetchReports();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = position;
    });

    if (_mapInitialized) {
      _mapController.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    }
  }

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

              if (timestamp is String &&
                  latitude is double &&
                  longitude is double) {
                String infoTitle = 'No Title';
                String infoSnippet = 'No Description';
                if (dataset != null && dataset is Map<String, dynamic>) {
                  infoTitle = dataset['metadata']?.toString() ?? infoTitle;
                }
                newMarkers.add(
                  Marker(
                    markerId: MarkerId('$timestamp-$latitude-$longitude'),
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
        }
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching reports: $error')),
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    setState(() {
      _mapInitialized = true;
    });
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
        title: const Text('Routes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchReports, // Botón para actualizar los marcadores manualmente
          ),
        ],
      ),
      body: GoogleMap(
        onMapCreated: _onMapCreated,
        initialCameraPosition: CameraPosition(
          target: _currentPosition != null
              ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
              : const LatLng(40.3897278, -3.6280647),
          zoom: 16.0,
        ),
        markers: _markers,
      ),
    );
  }
}
