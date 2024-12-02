import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:madtrack/models/sensors_data.dart';

class DetailMapScreen extends StatefulWidget {
  final SensorsData sensorsData;

  const DetailMapScreen({super.key, required this.sensorsData});

  @override
  _DetailMapScreenState createState() => _DetailMapScreenState();
}

class _DetailMapScreenState extends State<DetailMapScreen>
    with AutomaticKeepAliveClientMixin<DetailMapScreen> {
  late GoogleMapController _controller;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          SizedBox(
            height: 300.0,
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: widget.sensorsData.latlong.first,
                zoom: 15.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<OneSequenceGestureRecognizer>(
                    () => EagerGestureRecognizer()),
              },
              polylines: _buildPolylines(),
              markers: _buildMarkers(),
              zoomControlsEnabled: false,
            ),
          ),
          const SizedBox(height: 20),
          _buildInfoRow(context, Icons.access_time,
              formatSeconds(widget.sensorsData.time)),
          _buildInfoRow(context, Icons.directions,
              "${(widget.sensorsData.distance / 1000).toStringAsFixed(3)} km"),
          _buildInfoRow(context, Icons.speed,
              "${widget.sensorsData.averageSpeed.toStringAsFixed(2)} km/h"),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String value) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: colorScheme.onPrimary),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 18, color: colorScheme.onPrimary),
          ),
        ],
      ),
    );
  }

  String formatSeconds(int seconds) {
    Duration duration = Duration(seconds: seconds);
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes'$twoDigitSeconds''";
  }

  Set<Polyline> _buildPolylines() {
    final List<LatLng> latLngList = widget.sensorsData.latlong;
    final Set<Polyline> polylines = {};

    if (latLngList.isNotEmpty) {
      final Polyline polyline = Polyline(
        polylineId: const PolylineId('route'),
        color: Colors.blue,
        points: latLngList,
        width: 5,
      );
      polylines.add(polyline);
    }

    return polylines;
  }

  Set<Marker> _buildMarkers() {
    return {
      Marker(
        markerId: const MarkerId('startMarker'),
        position: widget.sensorsData.latlong.first,
        infoWindow: const InfoWindow(title: 'Inicio de la ruta'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
      Marker(
        markerId: const MarkerId('endMarker'),
        position: widget.sensorsData.latlong.last,
        infoWindow: const InfoWindow(title: 'Fin de la ruta'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  @override
  bool get wantKeepAlive => true;
}
