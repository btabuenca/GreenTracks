import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//import 'package:madtrack/credentials.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _mapController;
  Set<Marker> _bikeStations = <Marker>{};
  final Set<Marker> _bikeStationsVisible = <Marker>{};
  final Set<Marker> _bikeStationsInvisible = <Marker>{};
  final CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(40.3962, -3.6992),
    zoom: 12.0,
  );
  bool _dataLoaded = false;
  late String _accessToken;
  BitmapDescriptor markerIconHigh = BitmapDescriptor.defaultMarker;
  BitmapDescriptor markerIconMedium = BitmapDescriptor.defaultMarker;
  BitmapDescriptor markerIconLow = BitmapDescriptor.defaultMarker;
  BitmapDescriptor markerIconNo = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    addCustomIcons();
    _loginAndGetAccessToken();
    super.initState();
  }

  Future<void> addCustomIcons() async {
    markerIconHigh = await addIcon("assets/bike-marker-high.png");
    markerIconMedium = await addIcon("assets/bike-marker-medium.png");
    markerIconLow = await addIcon("assets/bike-marker-low.png");
    markerIconNo = await addIcon("assets/bike-marker-no.png");
  }

  Future<BitmapDescriptor> addIcon(String asset) async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      asset,
    );
    return icon;
  }

  Future<void> _loginAndGetAccessToken() async {
    //final String email = Credentials().email;
    final String email = 'bernardo.tabuenca@upm.es';
    //final String password = Credentials().password;
    //final String password = 'uDe!Gr84KJsi&sC';
    final String password = '-SkDV-B,7U5/f,c';


    final response = await http.get(
      Uri.parse('https://openapi.emtmadrid.es/v2/mobilitylabs/user/login/'),
      headers: {
        'email': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      final List<dynamic> data = responseData['data'];
      final Map<String, dynamic> dataMap =
          data.isNotEmpty ? data.first as Map<String, dynamic> : {};
      _accessToken = dataMap['accessToken'] ?? '';
      await _fetchDataFromApi();
      setState(() {
        _dataLoaded = true;
      });
    } else {
      print('Error en la solicitud HTTP: ${response.statusCode}');
    }
  }

  Future<void> _fetchDataFromApi() async {
    final response = await http.get(
      Uri.parse('https://openapi.emtmadrid.es/v1/transport/bicimad/stations/'),
      headers: {
        'accessToken': _accessToken,
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      _addMarkersToMap(responseData);
    } else {
      print('Error en la solicitud HTTP: ${response.statusCode}');
    }
  }

  void _addMarkersToMap(dynamic responseData) {
    List listStations = responseData['data'];
    List<dynamic> coordinates;
    double latitude;
    double longitude;
    String address;
    for (var station in listStations) {
      coordinates = station['geometry']['coordinates'];
      address = station['address'];
      longitude = coordinates[0];
      latitude = coordinates[1];
      BitmapDescriptor stationIcon;
      switch (station['light']) {
        case 0:
          stationIcon = markerIconLow;
          break;
        case 1:
          stationIcon = markerIconHigh;
          break;
        case 2:
          stationIcon = markerIconMedium;
          break;
        case 3:
          stationIcon = markerIconNo;
          break;
        default:
          stationIcon = markerIconLow;
      }
      _bikeStationsVisible.add(
        Marker(
          markerId: MarkerId('$latitude-$longitude'),
          position: LatLng(latitude, longitude),
          infoWindow: InfoWindow(
            title: address,
            snippet:
                "Disponibles: ${station['free_bases']}/${station['total_bases']}",
          ),
          icon: stationIcon,
        ),
      );
    }
    _bikeStations = _bikeStationsInvisible;
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return _buildMap();
    }
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: _initialCameraPosition,
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
      myLocationEnabled: true,
      markers: _bikeStations,
      onCameraMove: _onCameraMove,
      zoomControlsEnabled: false,
    );
  }

  void _onCameraMove(CameraPosition position) {
    if (position.zoom > 14) {
      setState(() {
        _bikeStations = _bikeStationsVisible;
      });
    } else {
      setState(() {
        _bikeStations = _bikeStationsInvisible;
      });
    }
  }
}
