import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:madtrack/lang/l10n.dart';
import 'telemetry_map_screen.dart';

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
  List<String> _routes = [];
  bool _isLoadingRoutes = true;

  bool _locationEnabled = true;
  bool _locationTimeout = false;
  Timer? _gpsTimer;
  int _remainingSeconds = 10;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startLocationCountdown();
    _initializeLocationUpdates();
    _fetchRoutes();
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _countdownTimer?.cancel();
    if (_locationEnabled) _positionStream.cancel();
    super.dispose();
  }

  void _startLocationCountdown() {
    _remainingSeconds = 10;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds == 0) {
        timer.cancel();
        _gpsTimer?.cancel();
        _stopLocationUpdates();

        if (mounted) {
          setState(() {
            _locationEnabled = false;
            _locationTimeout = _currentPosition == null;
          });

          if (_currentPosition == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No se encuentra señal GPS. Considera que esta aplicación ha sido diseñada para utilizarse outdoors."),
              ),
            );
          }
        }
      }
    });

    _gpsTimer = Timer(const Duration(seconds: 10), () {
      _stopLocationUpdates();
    });
  }

  void _initializeLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('location_service_disabled'))),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.translate('location_permission_denied'))),
        );
        return;
      }
    }

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

  void _stopLocationUpdates() {
    try {
      _positionStream.cancel();
    } catch (_) {}
  }

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
            SnackBar(content: Text(AppLocalizations.of(context)!.translate('report_saved_ok'))),
          );
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TelemetryMapScreen(
                position: _currentPosition,
              ),
            ),
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
        SnackBar(content: Text(AppLocalizations.of(context)!.translate('report_enable_geoloc'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('report_spot_observation')),
      ),
      body: Column(
        children: [
          SwitchListTile(
            title: Text(_locationEnabled && _remainingSeconds > 0
                ? "Buscando coordenadas... quedan $_remainingSeconds segundos."
                : "Activa el switch para actualizar la posición GPS"),
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
                _locationTimeout = false;
              });
              if (value) {
                _startLocationCountdown();
                _initializeLocationUpdates();
              } else {
                _countdownTimer?.cancel();
                _gpsTimer?.cancel();
                _stopLocationUpdates();
                _currentPosition = null;
              }
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _reportController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        label: Text(AppLocalizations.of(context)!.translate('report_label_observation_position')),
                        border: const OutlineInputBorder(),
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
                      fieldViewBuilder: (context, _, focusNode, onFieldSubmitted) {
                        return TextField(
                          controller: _routeController, // ✅ Aquí está la corrección
                          focusNode: focusNode,
                          decoration: InputDecoration(
                            label: Text(AppLocalizations.of(context)!.translate('report_label_route_name')),
                            border: const OutlineInputBorder(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _currentPosition == null
                        ? const CircularProgressIndicator()
                        : Text(
                      'Your current position:\n'
                          'Lat: ${_currentPosition?.latitude},\n'
                          'Lon: ${_currentPosition?.longitude},\n'
                          'Alt: ${_currentPosition?.altitude}',
                      textAlign: TextAlign.left,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: (_currentPosition != null) ? _submitReport : null,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.pin_drop),
                          const SizedBox(width: 8),
                          Text(AppLocalizations.of(context)!.translate('report_elevated_save_observation')),
                        ],
                      ),
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