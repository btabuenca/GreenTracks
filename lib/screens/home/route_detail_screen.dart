import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RouteDetailScreen extends StatefulWidget {
  final String routeName;

  const RouteDetailScreen({required this.routeName, super.key});

  @override
  _RouteDetailScreenState createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRouteDetails();
  }

  Future<void> _fetchRouteDetails() async {
    final url = 'https://flow.iot.etsisi.upm.es/sutee/route?device=1&route=${widget.routeName}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            _routePoints = data.map<LatLng>((point) {
              return LatLng(point['latitude'], point['longitude']);
            }).toList();
            _isLoading = false;
          });
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to fetch route details: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching route details: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Route: ${widget.routeName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _routePoints.isEmpty
          ? const Center(child: Text('No points available for this route.'))
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _routePoints.isNotEmpty
              ? _routePoints.first
              : const LatLng(0, 0),
          zoom: 16.0,
        ),
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: _routePoints,
            color: Colors.blue,
            width: 5,
          ),
        },
        markers: _routePoints
            .asMap()
            .map((index, point) => MapEntry(
          index.toString(),
          Marker(
            markerId: MarkerId('point_$index'),
            position: point,
            infoWindow: InfoWindow(
              title: 'Point ${index + 1}',
            ),
          ),
        ))
            .values
            .toSet(),
      ),
    );
  }
}
