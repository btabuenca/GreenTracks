import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:madtrack/models/sensors_data.dart';
import 'package:noise_meter/noise_meter.dart';
import 'package:light/light.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SensorController {
  late SensorsData sensorData;
  late Timer timer;
  late double _trackingTime;
  bool _getNoise = true;
  bool _getLux = true;

  Location? location;
  LocationData? _currentLocation;
  StreamSubscription<LocationData>? _locationSubscription;

  NoiseMeter? noiseMeter;
  StreamSubscription<NoiseReading>? _noiseSubscription;
  double? _currentNoiseLevel;

  final Light _light = Light();
  StreamSubscription<int>? _lightSubscription;
  int? _currentLuxValue;

  Future<void> startTracking() async {
    sensorData = SensorsData();
    location = Location();
    noiseMeter = NoiseMeter();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _trackingTime = prefs.getDouble('trackingTime') ?? 2;
    _getNoise = prefs.getBool('getNoise') ?? true;
    _getLux = prefs.getBool('getLux') ?? true;
    _startLocationTracking();
    _startNoiseTracking();
    _startLightTracking();

    timer =
        Timer.periodic(Duration(seconds: _trackingTime.toInt()), (timer) async {
      sensorData.addLatLng(
          LatLng(_currentLocation!.latitude!, _currentLocation!.longitude!));
      double noiseToAdd =
          _currentNoiseLevel ?? 0.0; //Problems while tracking noise
      if (noiseToAdd.isInfinite || noiseToAdd.isNaN) {
        noiseToAdd = 50.0;
      }
      if (_getNoise) sensorData.addNoise(noiseToAdd);
      if (_getLux) sensorData.addLux(_currentLuxValue);
      sensorData.updateTime(_trackingTime.toInt());
    });
  }

  SensorsData stopTracking() {
    _locationSubscription?.cancel();
    _noiseSubscription?.cancel();
    _lightSubscription?.cancel();
    timer.cancel();
    return sensorData;
  }

  void _startLocationTracking() {
    _locationSubscription =
        location!.onLocationChanged.listen((LocationData locationData) {
      _currentLocation = locationData;
    }, onError: (error) {
      print('Error al obtener la ubicación: $error');
    });
  }

  void _startNoiseTracking() {
    _noiseSubscription = noiseMeter!.noise.listen((NoiseReading noiseReading) {
      _currentNoiseLevel = noiseReading.meanDecibel;
    }, onError: (error) {
      print('Error al obtener el nivel de ruido: $error');
    });
  }

  void _startLightTracking() {
    _lightSubscription = _light.lightSensorStream.listen((int luxValue) {
      _currentLuxValue = luxValue;
    }, onError: (error) {
      print('Error al obtener el valor de lux: $error');
    });
  }
}
