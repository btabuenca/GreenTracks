import 'package:flutter/material.dart';
import 'package:geolocator_platform_interface/src/models/position.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TelemetryMapScreen extends StatefulWidget {
  final Position? position;

  const TelemetryMapScreen({super.key, this.position});

  @override
  _TelemetryMapScreenState createState() => _TelemetryMapScreenState();
}

class _TelemetryMapScreenState extends State<TelemetryMapScreen> {
  final Map<String?, List<Map<String, dynamic>>> _rawRoutes = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTelemetries();
  }

  Future<void> _fetchTelemetries() async {
    const url = 'https://flow.iot.etsisi.upm.es/sutee/telemetry?device=1';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          final Map<String?, List<Map<String, dynamic>>> routes = {};

          for (var item in data) {
            final lat = item['latitude'];
            final lon = item['longitude'];
            final route = item['route'];
            if (lat is double && lon is double) {
              if (!routes.containsKey(route)) {
                routes[route] = [];
              }
              routes[route]!.add(item);
            }
          }

          // Ordenar por timestamp_server dentro de cada ruta
          routes.forEach((route, points) {
            points.sort((a, b) {
              final ta = DateTime.tryParse(a['timestamp_server'] ?? '') ?? DateTime(0);
              final tb = DateTime.tryParse(b['timestamp_server'] ?? '') ?? DateTime(0);
              return ta.compareTo(tb);
            });
          });

          setState(() {
            _rawRoutes.clear();
            _rawRoutes.addAll(routes);
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
    final initialPosition = widget.position != null
        ? LatLng(widget.position!.latitude, widget.position!.longitude)
        : _rawRoutes.isNotEmpty && _rawRoutes.values.first.isNotEmpty
        ? LatLng(
      _rawRoutes.values.first.first['latitude'],
      _rawRoutes.values.first.first['longitude'],
    )
        : const LatLng(0, 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telemetry Map'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 14.0,
        ),
        markers: _generateMarkers(),
        polylines: _generatePolylines(),
      ),
    );
  }

  Set<Marker> _generateMarkers() {
    final Set<Marker> markers = {};

    _rawRoutes.forEach((route, points) {
      for (int i = 0; i < points.length; i++) {
        final item = points[i];
        final point = LatLng(item['latitude'], item['longitude']);
        final isFirst = i == 0;

        final icon = (route == null || route.toString().trim().isEmpty)
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : isFirst
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue)
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan);

        final metadata = item['dataset']?['metadata'];

        final showInfoWindow = isFirst && route != null && route.toString().trim().isNotEmpty;

        markers.add(
          Marker(
            markerId: MarkerId('$route-${point.latitude}-${point.longitude}'),
            position: point,
            icon: icon,
            infoWindow: showInfoWindow
                ? InfoWindow(
              title: 'Inicio de ruta: $route',
              snippet: metadata != null ? metadata.toString() : '',
            )
                : InfoWindow.noText,
          ),
        );
      }
    });

    if (widget.position != null) {
      final userLatLng = LatLng(widget.position!.latitude, widget.position!.longitude);
      markers.add(
        Marker(
          markerId: const MarkerId('user_position'),
          position: userLatLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(
            title: 'Tu posición reportada',
            snippet: 'Este es el punto que acabas de enviar',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _generatePolylines() {
    final Set<Polyline> polylines = {};

    _rawRoutes.forEach((route, points) {
      if (route != null &&
          route.toString().trim().isNotEmpty &&
          points.length > 1) {
        final latLngs = points
            .map<LatLng>((item) => LatLng(item['latitude'], item['longitude']))
            .toList();

        polylines.add(
          Polyline(
            polylineId: PolylineId(route),
            points: latLngs,
            color: Colors.blue,
            width: 4,
          ),
        );
      }
    });

    return polylines;
  }
}
