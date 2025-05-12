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
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';


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

  DateTime? _lastSampleTime;
  int _samplingIntervalSeconds = 1;


  final dbHelper = DatabaseHelper();

  Map<String, dynamic>? _luxStats;
  Map<String, dynamic>? _noiseStats;
  int? _totalDistanceMeters;


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
      _samplingIntervalSeconds = prefs.getInt('samplingInterval') ?? 1;
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
      Uri.parse("https://flow.iot.etsisi.upm.es/sutee/telemetries2"),
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
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _isTracking = false;
        _endTime = DateTime.now();
        _endLatitude = position.latitude;
        _endLongitude = position.longitude;
        _endAltitude = position.altitude;
      });

      _luxStats = await dbHelper.calculateStatistics("lux");
      _noiseStats = await dbHelper.calculateStatistics("decibel");

      final data = await dbHelper.getTelemetry();
      double totalDistance = 0.0;
      final Distance distance = Distance();

      for (int i = 1; i < data.length; i++) {
        final prev = LatLng(data[i - 1]['latitude'], data[i - 1]['longitude']);
        final curr = LatLng(data[i]['latitude'], data[i]['longitude']);
        totalDistance += distance.as(LengthUnit.Meter, prev, curr);
      }

      setState(() {
        _totalDistanceMeters = totalDistance.round();
      });
    }
  }


  Future<void> _saveTelemetry() async {
    final now = DateTime.now();
    if (_lastSampleTime != null &&
        now.difference(_lastSampleTime!).inSeconds < _samplingIntervalSeconds) {
      return; // aún no ha pasado el intervalo
    }
    _lastSampleTime = now;

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _altitude = position.altitude;
    });

    await dbHelper.insertTelemetry(
      _luxValue,
      _decibelValue,
      _latitude,
      _longitude,
      _altitude,
    );
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

    try {
      final directory = await getTemporaryDirectory(); // ⚠️ Carpeta temporal para compartir
      final path = "${directory.path}/telemetry_data.csv";
      final file = File(path);
      await file.writeAsString(csvData);

      // Comparte el archivo CSV
      await Share.shareXFiles(
        [XFile(file.path)],
        text: "Adjunto CSV de telemetría generado desde MadTrack.",
        subject: "GreenTrackS dataset",
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al generar/compartir archivo: $e")),
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
              child: Text(_isTracking ? 'Stop tracking' : 'Start tracking'),
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
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Resumen", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          if (_startTime != null)
                            ListTile(
                              leading: const Icon(Icons.play_arrow),
                              title: const Text("Hora de inicio"),
                              subtitle: Text(DateFormat('yyyy/MM/dd HH:mm:ss').format(_startTime!.toLocal())),
                            ),
                          if (_startTime != null && _endTime != null)
                            ListTile(
                              leading: const Icon(Icons.timer),
                              title: const Text("Duración"),
                              subtitle: Text(_formatDuration(_endTime!.difference(_startTime!))),
                            ),
                          if (_totalDistanceMeters != null)
                            ListTile(
                              leading: const Icon(Icons.directions_walk),
                              title: const Text("Distancia total recorrida"),
                              subtitle: Text("$_totalDistanceMeters metros"),
                            ),
                          ListTile(
                            leading: const Icon(Icons.flag),
                            title: const Text("Coordenadas de inicio"),
                            subtitle: Text(
                              "Latitud: ${_startLatitude?.toStringAsFixed(3)}\n"
                                  "Longitud: ${_startLongitude?.toStringAsFixed(3)}\n"
                                  "Altitud: ${_startAltitude?.toStringAsFixed(3)} m",
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.outlined_flag),
                            title: const Text("Coordenadas finales"),
                            subtitle: Text(
                              "Latitud: ${_endLatitude?.toStringAsFixed(3)}\n"
                                  "Longitud: ${_endLongitude?.toStringAsFixed(3)}\n"
                                  "Altitud: ${_endAltitude?.toStringAsFixed(3)} m",
                            ),
                          ),
                          if (_luxStats != null)
                            ListTile(
                              leading: const Icon(Icons.light_mode),
                              title: const Text("Estadísticas de luz (lux)"),
                              subtitle: Text(
                                "Máx: ${(_luxStats?['max'] as num?)?.toStringAsFixed(3)}\n"
                                    "Min: ${(_luxStats?['min'] as num?)?.toStringAsFixed(3)}\n"
                                    "Media: ${(_luxStats?['avg'] as num?)?.toStringAsFixed(3)}\n"
                                    "Q1: ${(_luxStats?['q1'] as num?)?.toStringAsFixed(3)}\n"
                                    "Q3: ${(_luxStats?['q3'] as num?)?.toStringAsFixed(3)}",
                              ),
                            ),
                          if (_noiseStats != null)
                            ListTile(
                              leading: const Icon(Icons.volume_up),
                              title: const Text("Estadísticas de ruido (dB)"),
                              subtitle: Text(
                                "Máx: ${(_noiseStats?['max'] as num?)?.toStringAsFixed(3)}\n"
                                    "Min: ${(_noiseStats?['min'] as num?)?.toStringAsFixed(3)}\n"
                                    "Media: ${(_noiseStats?['avg'] as num?)?.toStringAsFixed(3)}\n"
                                    "Q1: ${(_noiseStats?['q1'] as num?)?.toStringAsFixed(3)}\n"
                                    "Q3: ${(_noiseStats?['q3'] as num?)?.toStringAsFixed(3)}",
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return "$minutes min ${seconds.toString().padLeft(2, '0')} sec";
  }

  @override
  void dispose() {
    _lightSubscription?.cancel();
    _noiseSubscription?.cancel();
    super.dispose();
  }
}