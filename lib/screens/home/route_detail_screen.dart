import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class RouteDetailScreen extends StatefulWidget {
  final String routeName;

  const RouteDetailScreen({required this.routeName, super.key});

  @override
  _RouteDetailScreenState createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  List<Map<String, dynamic>> _routeRawPoints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRouteDetails();
  }

  Future<void> _fetchRouteDetails() async {
    final url = 'https://flow.iot.etsisi.upm.es/sutee/route2?device=1&route=${widget.routeName}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data is List) {
          setState(() {
            _routeRawPoints = List<Map<String, dynamic>>.from(data);
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

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('dd/MM/yyyy HH:mm').format(dateTime);
    } catch (_) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<LatLng> _latLngPoints = _routeRawPoints
        .map((point) => LatLng(point['latitude'], point['longitude']))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Route: ${widget.routeName}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _latLngPoints.isEmpty
          ? const Center(child: Text('No points available for this route.'))
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _latLngPoints.first,
          zoom: 16.0,
        ),
        polylines: {
          Polyline(
            polylineId: const PolylineId('route'),
            points: _latLngPoints,
            color: Colors.blue,
            width: 5,
          ),
        },
        markers: _routeRawPoints
            .asMap()
            .map((index, point) {
          final latLng = LatLng(point['latitude'], point['longitude']);
          final rawTitle = point['col_10'];
          final title = rawTitle != null ? rawTitle.toString().trim() : '';
          final timestamp = point['timestamp_z'];
          final metadata = point['dataset']?['metadata']?.toString().trim();

          final snippetLines = [
            _formatTimestamp(timestamp),
            if (metadata != null && metadata.isNotEmpty) metadata,
          ];

          return MapEntry(
            index.toString(),
            Marker(
              markerId: MarkerId('point_$index'),
              position: latLng,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                index == 0
                    ? BitmapDescriptor.hueBlue
                    : BitmapDescriptor.hueCyan,
              ),
              infoWindow: InfoWindow(
                title: title.isNotEmpty ? title : 'Point ${index + 1}',
                snippet: snippetLines.join('\n'),
              ),
            ),
          );
        })
            .values
            .toSet(),
      ),
    );
  }
}
