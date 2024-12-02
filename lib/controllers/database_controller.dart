import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:madtrack/models/sensors_data.dart';

class DatabaseController {
  late DatabaseReference _database;
  DatabaseController() {
    _database = FirebaseDatabase.instance
        .ref("Users/${FirebaseAuth.instance.currentUser?.uid}/SensorData");
  }

  Future<void> addData(SensorsData sensorsData) async {
    await _database.push().set({
      'name': sensorsData.name,
      'distance': sensorsData.distance,
      'time': sensorsData.time,
      'averageSpeed': sensorsData.averageSpeed,
      'averageNoise': sensorsData.averageNoise,
      'averageLux': sensorsData.averageLux,
      'latlong': sensorsData.latlong
          .map((latLng) =>
              {'latitude': latLng.latitude, 'longitude': latLng.longitude})
          .toList(),
      'noise': sensorsData.noise,
      'lux': sensorsData.lux,
    });
  }

  Future<void> updateData(String path, Map<String, dynamic> data) async {
    try {
      await _database.child(path).update(data);
      print("Data updated successfully");
    } catch (error) {
      print("Error updating data: $error");
    }
  }

  Future<void> deleteData(String path) async {
    try {
      await _database.child(path).remove();
      print("Data deleted successfully");
    } catch (error) {
      print("Error deleting data: $error");
    }
  }

  Future<List<SensorsData>> getData() async {
    final DataSnapshot snapshot = await _database.get();
    final List<SensorsData> result = [];

    if (snapshot.value != null) {
      final Map? data = snapshot.value as Map<dynamic, dynamic>?;
      data?.forEach((key, value) {
        final List<double?>? noiseList =
            value['noise'] != null && (value['noise'] as List).isNotEmpty
                ? (value['noise'] as List<dynamic>).cast<double?>()
                : null;

        final List<int?>? luxList =
            value['lux'] != null && (value['lux'] as List).isNotEmpty
                ? (value['lux'] as List<dynamic>).cast<int?>()
                : null;
        result.add(SensorsData(
          firebaseId: key as String?,
          name: value['name'] as String?,
          latlong: (value['latlong'] as List<dynamic>)
              .map((latLng) => LatLng(
                    (latLng['latitude'] as double),
                    (latLng['longitude'] as double),
                  ))
              .toList(),
          noise: noiseList,
          lux: luxList,
          distance: parseDouble(value['distance']),
          time: (value['time'] as int?) ?? 0,
          averageSpeed: parseDouble(value['averageSpeed']),
          averageNoise: parseDouble(value['averageNoise']),
          averageLux: parseDouble(value['averageLux']),
        ));
      });
    }

    return result;
  }

  double? parseDouble(dynamic value) {
    if (value is int) {
      return value.toDouble();
    } else if (value is double) {
      return value;
    } else {
      return double.tryParse(value?.toString() ?? '0.0');
    }
  }
}
