import 'package:flutter/material.dart';
import 'package:madtrack/widgets/weather.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pronóstico del Tiempo'),
      ),
      body: Center(
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: WeatherForecastWidget(),
        ),
      ),
    );
  }
}
