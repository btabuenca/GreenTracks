import 'package:flutter/material.dart';
import 'package:madtrack/screens/weather/weather.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather forescast'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: WeatherForecastWidget(),
          ),
        ),
      ),
    );
  }
}
