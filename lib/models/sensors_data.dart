import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';

class SensorsData {
  String firebaseId;
  String name;
  List<LatLng> latlong;
  List<double?> noise;
  List<int?> lux;
  double distance; //meters
  int time; //seconds
  double averageSpeed; //km/h
  double averageNoise;
  double averageLux;

  SensorsData({
    String? firebaseId,
    String? name,
    List<LatLng>? latlong,
    List<double?>? noise,
    List<int?>? lux,
    double? distance,
    int? time,
    double? averageSpeed,
    double? averageNoise,
    double? averageLux,
  })  : name = name ?? '',
        firebaseId = firebaseId ?? '',
        latlong = latlong ?? [],
        noise = noise ?? [],
        lux = lux ?? [],
        distance = distance ?? 0.0,
        time = time ?? 0,
        averageSpeed = averageSpeed ?? 0.0,
        averageNoise = averageNoise ?? 0.0,
        averageLux = averageLux ?? 0.0;

  void addLatLng(LatLng newLatLng) {
    latlong.add(newLatLng);
  }

  void addNoise(double? newNoise) {
    noise.add(newNoise);
  }

  void addLux(int? newLux) {
    lux.add(newLux);
  }

  void updateTime(int newTime) {
    time += newTime;
  }

  void calculateData() {
    calculateAverageLux();
    calculateAverageNoise();
    calculateDistance();
    calculateSpeed();
  }

  void calculateSpeed() {
    if (time == 0 || distance == 0.0) {
      averageSpeed = 0.0;
    } else {
      final double distanceInKm = distance / 1000.0;
      averageSpeed = distanceInKm / (time / 3600);
    }
  }

  void calculateAverageLux() {
    if (lux.isEmpty) {
      averageLux = 0.0;
    } else {
      averageLux =
          lux.reduce((sum, luxValue) => sum! + (luxValue ?? 0))! / lux.length;
    }
  }

  void calculateAverageNoise() {
    if (noise.isEmpty) {
      averageNoise = 0.0;
    } else {
      averageNoise =
          noise.reduce((sum, noiseValue) => sum! + (noiseValue ?? 0))! /
              noise.length;
    }
  }

  void calculateDistance() {
    if (latlong.length < 2) {
      distance = 0.0;
    } else {
      for (int i = 0; i < latlong.length - 1; i++) {
        final double pointsDistance =
            _haversineDistance(latlong[i], latlong[i + 1]);
        distance += pointsDistance;
      }
      distance *= 1000;
    }
  }

  double _haversineDistance(LatLng point1, LatLng point2) {
    const radioTierra = 6371.0;

    final latitude1 = point1.latitude * pi / 180.0;
    final longitude1 = point1.longitude * pi / 180.0;
    final latitude2 = point2.latitude * pi / 180.0;
    final longitude2 = point2.longitude * pi / 180.0;

    final dLat = latitude2 - latitude1;
    final dLon = longitude2 - longitude1;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(latitude1) * cos(latitude2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    final pointsDistance = radioTierra * c;

    return pointsDistance;
  }
}
