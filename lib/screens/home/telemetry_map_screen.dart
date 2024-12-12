import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TelemetryMapScreen extends StatefulWidget {
  const TelemetryMapScreen({super.key});

  @override
  _TelemetryMapScreenState createState() => _TelemetryMapScreenState();
}

class _TelemetryMapScreenState extends State<TelemetryMapScreen> {
  /// Lista de puntos de telemetría organizados por rutas
  final Map<String?, List<LatLng>> _routes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTelemetries();
  }

  /// Método para obtener las telemetrías desde la API y organizarlas por rutas
  Future<void> _fetchTelemetries() async {
    const url = 'https://flow.iot.etsisi.upm.es/sutee/telemetry?device=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final Map<String?, List<LatLng>> routes = {};

          for (var item in data) {
            final latitude = item['latitude'];
            final longitude = item['longitude'];
            final route = item['route']; // Puede ser null

            if (latitude is double && longitude is double) {
              final point = LatLng(latitude, longitude);

              // Organiza los puntos por la clave `route`
              if (!routes.containsKey(route)) {
                routes[route] = [];
              }
              routes[route]?.add(point);
            }
          }

          setState(() {
            _routes.clear();
            _routes.addAll(routes);
            _isLoading = false;
          });
        }
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching telemetries: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Map'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _routes.isNotEmpty
              ? _routes.values.first.first
              : const LatLng(0, 0),
          zoom: 12.0,
        ),
        markers: _generateMarkers(),
        polylines: _generatePolylines(),
      ),
    );
  }

  /// Genera marcadores con colores diferentes para puntos con y sin `route`
  Set<Marker> _generateMarkers() {
    final Set<Marker> markers = {};
    _routes.forEach((route, points) {
      final color = route == null ? BitmapDescriptor.hueRed : BitmapDescriptor.hueGreen;

      for (final point in points) {
        markers.add(
          Marker(
            markerId: MarkerId('${point.latitude}-${point.longitude}'),
            position: point,
            icon: BitmapDescriptor.defaultMarkerWithHue(color),
            infoWindow: InfoWindow(
              title: route ?? 'No Route',
              snippet: 'Lat: ${point.latitude}, Lon: ${point.longitude}',
            ),
          ),
        );
      }
    });
    return markers;
  }

  /// Genera polilíneas para conectar puntos con el mismo `route`
  Set<Polyline> _generatePolylines() {
    final Set<Polyline> polylines = {};
    _routes.forEach((route, points) {
      if (route != null && points.length > 1) {
        polylines.add(
          Polyline(
            polylineId: PolylineId(route),
            points: points,
            color: Colors.blue, // Cambia el color de las líneas si es necesario
            width: 4,
          ),
        );
      }
    });
    return polylines;
  }
}