import 'package:flutter/material.dart';
import 'package:madtrack/screens/home/tracking_screen.dart';
import 'package:madtrack/screens/home/routes_screen.dart';
import 'package:madtrack/screens/home/welcome_sreen.dart';
import 'package:madtrack/screens/home/report_screen.dart';
import 'package:madtrack/screens/home/settings_screen.dart';
import 'package:madtrack/screens/home/weather_screen.dart';
import 'package:madtrack/screens/public_transport_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRailVisible = true; // Controla la visibilidad del NavigationRail

  final List<Widget> _pages = [
    const WelcomeScreen(),
    const RoutesScreen(),
    const ReportScreen(),
    const TrackingScreen(),
    const WeatherScreen(),
    const PublicTransportScreen(), // Nueva pantalla
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GreenTracks!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(_isRailVisible ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _isRailVisible = !_isRailVisible; // Alterna la visibilidad
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (_isRailVisible) // Muestra el NavigationRail solo si _isRailVisible es true
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.home),
                  selectedIcon: Icon(Icons.home_filled),
                  label: Text('Home'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.route),
                  selectedIcon: Icon(Icons.route_outlined),
                  label: Text('Routes'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.location_city),
                  selectedIcon: Icon(Icons.location_city_outlined),
                  label: Text('Spots'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.multitrack_audio),
                  selectedIcon: Icon(Icons.multitrack_audio_outlined),
                  label: Text('Tracker'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.cloud),
                  selectedIcon: Icon(Icons.cloud_outlined),
                  label: Text('Clima'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.directions_bus),
                  selectedIcon: Icon(Icons.directions_bus_filled),
                  label: Text('Transport'),
                ),
              ],
            ),
          if (_isRailVisible)
            const VerticalDivider(thickness: 1, width: 1), // Divider opcional
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: IndexedStack(
                index: _selectedIndex,
                children: _pages,
              ),
            ),
          ),
        ],
      ),
    );
  }
}