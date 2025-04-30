import 'package:flutter/material.dart';
import 'package:madtrack/screens/home/tracking_screen.dart';
import 'package:madtrack/screens/home/routes_screen.dart';
import 'package:madtrack/screens/home/welcome_sreen.dart';
import 'package:madtrack/screens/home/report_screen.dart';
import 'package:madtrack/screens/home/settings_screen.dart';
import 'package:madtrack/screens/weather/weather_screen.dart';
import 'package:madtrack/screens/transport/public_transport_screen.dart';
import 'package:madtrack/screens/webview_screen.dart';
import 'package:madtrack/screens/home/routes_list_screen.dart';
import 'package:madtrack/lang/l10n.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isRailVisible = true;

  final List<Widget> _pages = [
    const WelcomeScreen(),
    const RoutesScreen(),
    const ReportScreen(),
    const TrackingScreen(),
    const WeatherScreen(),
    const PublicTransportScreen(),
    const WebViewScreen(),
    const RoutesListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('app_title')),
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
                _isRailVisible = !_isRailVisible;
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (_isRailVisible)
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              labelType: NavigationRailLabelType.selected,
              destinations: [
                NavigationRailDestination(
                  icon: const Icon(Icons.home),
                  selectedIcon: const Icon(Icons.home_filled),
                  label: Text(AppLocalizations.of(context)!.translate('menu_home')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.route),
                  selectedIcon: const Icon(Icons.route_outlined),
                  label: Text(AppLocalizations.of(context)!.translate('menu_route')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.pin_drop),
                  selectedIcon: const Icon(Icons.pin_drop_outlined),
                  label: Text(AppLocalizations.of(context)!.translate('menu_spot')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.multitrack_audio),
                  selectedIcon: const Icon(Icons.multitrack_audio_outlined),
                  label: Text(AppLocalizations.of(context)!.translate('menu_track')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.cloud),
                  selectedIcon: const Icon(Icons.cloud_outlined),
                  label: Text(AppLocalizations.of(context)!.translate('menu_clima')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.directions_bus),
                  selectedIcon: const Icon(Icons.directions_bus_filled),
                  label: Text(AppLocalizations.of(context)!.translate('menu_trasport')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.school),
                  selectedIcon: const Icon(Icons.school_outlined),
                  label: Text(AppLocalizations.of(context)!.translate('menu_learn')),
                ),
                NavigationRailDestination(
                  icon: const Icon(Icons.list),
                  selectedIcon: const Icon(Icons.list_alt),
                  label: Text(AppLocalizations.of(context)!.translate('menu_tracks')),
                ),
              ],
            ),
          if (_isRailVisible)
            const VerticalDivider(thickness: 1, width: 1),
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