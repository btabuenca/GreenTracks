import 'package:flutter/material.dart';
import 'package:weather/weather.dart';

class WeatherForecastWidget extends StatefulWidget {
  const WeatherForecastWidget({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WeatherForecastWidgetState createState() => _WeatherForecastWidgetState();
}

class _WeatherForecastWidgetState extends State<WeatherForecastWidget> {
  WeatherFactory wf = WeatherFactory("0eb379923e477dd1f26a6abdff420d2a",
      language: Language.SPANISH);
  late Weather _currentWeather;
  List<Weather> _forecastData = [];
  bool _dataLoaded = false;

  @override
  void initState() {
    _fetchWeatherData();
    super.initState();
  }

  Future<void> _fetchWeatherData() async {
    _currentWeather = await wf.currentWeatherByCityName('Madrid');
    _forecastData = await wf.fiveDayForecastByCityName('Madrid');
    setState(() {
      _dataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_dataLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      return _buildWeather();
    }
  }

  Widget _buildWeather() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Now',
          style: TextStyle(
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 20),
        _weatherCard(),
        const SizedBox(height: 40),
        const Text(
          'Next 5 days',
          style: TextStyle(
            fontSize: 28,
          ),
        ),
        const SizedBox(height: 20),
        _fiveDaysCard(),
      ],
    );
  }

  Widget _fiveDaysCard() {
    return SizedBox(
      height: 192,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _forecastData.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 3.0,
            surfaceTintColor: Colors.white,
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 15.0, horizontal: 40.0),
              child: Column(
                children: [
                  Text(
                    '${_getWeekDay(_forecastData[index].date!.weekday)}: ${_forecastData[index].date!.hour.toString()}:00',
                    style: const TextStyle(fontSize: 18),
                  ),
                  Image.network(
                    'https://openweathermap.org/img/wn/${_currentWeather.weatherIcon}@4x.png',
                    width: 80,
                    height: 80,
                  ),
                  Text(
                    '${_forecastData[index].weatherDescription?.toUpperCase()}',
                  ),
                  Text(
                      '${_forecastData[index].temperature?.celsius?.toStringAsPrecision(2)}°C'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getWeekDay(int weekday) {
    String dayLetter = "NaN";
    switch (weekday) {
      case 1:
        dayLetter = "Lunes";
        break;
      case 2:
        dayLetter = "Martes";
        break;
      case 3:
        dayLetter = "Miércoles";
        break;
      case 4:
        dayLetter = "Jueves";
        break;
      case 5:
        dayLetter = "Viernes";
        break;
      case 6:
        dayLetter = "Sábado";
        break;
      case 7:
        dayLetter = "Domingo";
        break;
    }
    return dayLetter;
  }

  Widget _weatherCard() {
    return Card(
      elevation: 10.0,
      surfaceTintColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_currentWeather.areaName}',
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${_currentWeather.weatherDescription?.toUpperCase()}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_currentWeather.temperature?.celsius?.toStringAsPrecision(2)}°C',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.network(
                      'https://openweathermap.org/img/wn/${_currentWeather.weatherIcon}@4x.png',
                      width: 120,
                      height: 120,
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sensación térmica: ${_currentWeather.tempFeelsLike?.celsius?.toStringAsPrecision(2)}°C',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Min: ${_currentWeather.tempMin?.celsius?.toStringAsPrecision(2)}°C',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Max: ${_currentWeather.tempMax?.celsius?.toStringAsPrecision(2)}°C',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Viento: ${_currentWeather.windSpeed?.round()}km/h',
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      'Humedad: ${_currentWeather.humidity?.round()}%',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
