import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:madtrack/controllers/auth_manager.dart';
import 'package:madtrack/db/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:light/light.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  User? currentUser = AuthManager().getCurrentUser();
  bool getLux = true;
  bool getNoise = true;
  final Light _light = Light();
  final NoiseMeter noiseMeter = NoiseMeter();
  StreamSubscription? _lightSubscription;
  StreamSubscription<NoiseReading>? _noiseSubscription;

  double? _luxValue;
  double? _decibelValue;
  double? _latitude;
  double? _longitude;
  double? _altitude;
  bool _isTracking = false;

  DateTime? _startTime;
  DateTime? _endTime;
  double? _startLatitude;
  double? _startLongitude;
  double? _startAltitude;
  double? _endLatitude;
  double? _endLongitude;
  double? _endAltitude;

  final dbHelper = DatabaseHelper();

  Map<String, dynamic>? _luxStats;
  Map<String, dynamic>? _noiseStats;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    loadPreferences();
  }

  Future<void> requestPermissions() async {
    await Permission.microphone.request();
    await Geolocator.requestPermission();
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      getLux = prefs.getBool('getLux') ?? true;
      getNoise = prefs.getBool('getNoise') ?? true;
    });
  }

  Future<void> savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('getLux', getLux);
    prefs.setBool('getNoise', getNoise);
  }

  Future<void> _sendJsonToWebService() async {
    final data = await dbHelper.getTelemetry();
    if (data.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay datos para enviar")),
      );
      return;
    }

    // Formateamos el JSON de acuerdo al formato requerido
    final postData = {
//      "body": {
        "n": "MadTrack",
        "id": "1",
        "meta": {"ver": "3.0"},
        "cols": [
          {"name": "timestamp", "meta": {"tz": "UTC"}},
          {"name": "noise", "unit": "dB"},
          {"name": "light", "unit": "lux"},
          {"name": "latitude", "unit": "deg"},
          {"name": "longitude", "unit": "deg"},
          {"name": "altitude", "unit": "m"}
        ],
        "rows": data.map((record) {
          return {
            "timestamp": record["timestamp"],
            "noise": record["decibel"],
            "light": record["lux"],
            "latitude": record["latitude"],
            "longitude": record["longitude"],
            "altitude": record["altitude"]
          };
        }).toList(),
//      }
    };

    // Enviamos el JSON a la API RESTful
    final response = await http.post(
      Uri.parse("https://flow.iot.etsisi.upm.es/sutee/telemetries"),
      headers: {"Content-Type": "application/json"},
      body: json.encode(postData),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Datos enviados correctamente")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al enviar datos: ${response.statusCode}")),
      );
    }
  }


  final MaterialStateProperty<Icon?> thumbIcon =
  MaterialStateProperty.resolveWith<Icon?>(
        (Set<MaterialState> states) {
      if (states.contains(MaterialState.selected)) {
        return const Icon(Icons.check);
      }
      return const Icon(Icons.close);
    },
  );

  Future<void> _startTracking() async {
    if (!_isTracking) {
      setState(() {
        _isTracking = true;
        _startTime = DateTime.now();
      });

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _altitude = position.altitude;
        _startLatitude = position.latitude;
        _startLongitude = position.longitude;
        _startAltitude = position.altitude;
      });

      if (getLux) {
        _lightSubscription = _light.lightSensorStream.listen((lux) {
          setState(() {
            _luxValue = lux.toDouble();
          });
          _saveTelemetry();
        });
      }

      if (getNoise) {
        var micPermission = await Permission.microphone.status;
        if (micPermission.isGranted) {
          try {
            _noiseSubscription = noiseMeter!.noise.listen((NoiseReading noiseReading) {
              setState(() {
                _decibelValue = noiseReading.meanDecibel?.toDouble();
              });
              _saveTelemetry();
            });
          } catch (err) {
            print("Error al iniciar el NoiseMeter: $err");
          }
        } else {
          print("Permiso de micrófono no concedido");
          setState(() {
            _decibelValue = null;
          });
        }
      }
    }
  }

  Future<void> _stopTracking() async {
    if (_isTracking) {
      _lightSubscription?.cancel();
      _noiseSubscription?.cancel();

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _isTracking = false;
        _endTime = DateTime.now();
        _endLatitude = position.latitude;
        _endLongitude = position.longitude;
        _endAltitude = position.altitude;
      });

      _luxStats = await dbHelper.calculateStatistics("lux");
      _noiseStats = await dbHelper.calculateStatistics("decibel");
    }
  }

  Future<void> _saveTelemetry() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _altitude = position.altitude;
    });
    await dbHelper.insertTelemetry(_luxValue, _decibelValue, _latitude, _longitude, _altitude);
  }

  Future<void> _exportToCSV() async {
    final data = await dbHelper.getTelemetry();
    List<List<dynamic>> rows = [
      ["timestamp", "lux", "decibel", "latitude", "longitude", "altitude"]
    ];

    for (var record in data) {
      rows.add([
        record["timestamp"],
        record["lux"],
        record["decibel"],
        record["latitude"],
        record["longitude"],
        record["altitude"]
      ]);
    }

    String csvData = const ListToCsvConverter().convert(rows);
    Directory? directory;
    if (Platform.isAndroid) {
      directory = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      directory = await getApplicationDocumentsDirectory();
    }

    if (directory != null) {
      final path = "${directory.path}/telemetry_data.csv";
      final file = File(path);

      try {
        await file.writeAsString(csvData);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Datos exportados a $path"),
        ));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al guardar archivo: $e")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No se pudo acceder al directorio")),
      );
    }
  }

  Future<void> _resetDatabase() async {
    await dbHelper.resetTable();
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Base de datos reiniciada")));
  }

  Color _getLuxColor(double lux) {
    if (lux < 100) {
      return Colors.blue;
    } else if (lux < 500) {
      return Colors.green;
    } else if (lux < 2000) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  Color _getNoiseColor(double decibel) {
    if (decibel < 40) {
      return Colors.blue;
    } else if (decibel < 60) {
      return Colors.green;
    } else if (decibel < 80) {
      return Colors.yellow;
    } else {
      return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Light (Lux)',
                style: TextStyle(fontSize: 18),
              ),
              Switch(
                thumbIcon: thumbIcon,
                value: getLux,
                onChanged: (bool value) {
                  setState(() {
                    getLux = value;
                  });
                  savePreferences();
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Noise (Decibels)',
                style: TextStyle(fontSize: 18),
              ),
              Switch(
                thumbIcon: thumbIcon,
                value: getNoise,
                onChanged: (bool value) {
                  setState(() {
                    getNoise = value;
                  });
                  savePreferences();
                },
              ),
            ],
          ),
          const SizedBox(height: 40),
          Center(
            child: ElevatedButton(
              onPressed: _isTracking ? _stopTracking : _startTracking,
              child: Text(_isTracking ? 'Start tracking' : 'Stop tracking'),
            ),
          ),
          const SizedBox(height: 20),
          if (_isTracking)
            Center(
              child: Column(
                children: [
                  if (_luxValue != null)
                    Text(
                      'Luz: ${_luxValue?.toStringAsFixed(1)} lux',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getLuxColor(_luxValue!),
                      ),
                    ),
                  if (_decibelValue != null)
                    Text(
                      'Ruido: ${_decibelValue?.toStringAsFixed(1)} dB',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: _getNoiseColor(_decibelValue!),
                      ),
                    ),
                  if (_latitude != null && _longitude != null && _altitude != null)
                    Text(
                      'Coordenadas: ${_latitude?.toStringAsFixed(5)}, ${_longitude?.toStringAsFixed(5)} , ${_altitude?.toStringAsFixed(5)}',
                      style: const TextStyle(fontSize: 20),
                    ),
                ],
              ),
            ),
          if (!_isTracking && _startTime != null && _endTime != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Hora Inicio: ${_startTime?.toLocal()}"),
                  Text("Hora Fin: ${_endTime?.toLocal()}"),
                  Text("Coords. Inicio: $_startLatitude, $_startLongitude, $_startAltitude"),
                  Text("Coords. Final: $_endLatitude, $_endLongitude, $_endAltitude"),
                  if (_luxStats != null) ...[
                    Text("Luz - Max: ${_luxStats?['max']}, Min: ${_luxStats?['min']}, "
                        "Media: ${_luxStats?['avg']}, Q1: ${_luxStats?['q1']}, Q3: ${_luxStats?['q3']}"),
                  ],
                  if (_noiseStats != null) ...[
                    Text("Ruido - Max: ${_noiseStats?['max']}, Min: ${_noiseStats?['min']}, "
                        "Media: ${_noiseStats?['avg']}, Q1: ${_noiseStats?['q1']}, Q3: ${_noiseStats?['q3']}"),
                  ],
                  ElevatedButton(
                    onPressed: _exportToCSV,
                    child: const Text("Exportar a CSV"),
                  ),
                  ElevatedButton(
                    onPressed: _sendJsonToWebService,
                    child: const Text("Enviar JSON al Web Service"),
                  ),
                  ElevatedButton(
                    onPressed: _resetDatabase,
                    child: const Text("Resetear Base de Datos"),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _noiseSubscription?.cancel();
    super.dispose();
  }
}
