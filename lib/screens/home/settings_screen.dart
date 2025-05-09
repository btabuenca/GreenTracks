import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _cadenceController = TextEditingController();
  int _samplingIntervalSeconds = 1;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('tokenOpenWeatherMaps');
    if (savedToken == null || savedToken.isEmpty) {
      String defaultToken = await _loadDefaultToken();
      await prefs.setString('tokenOpenWeatherMaps', defaultToken);
      savedToken = defaultToken;
    }
    setState(() {
      _selectedLanguage = prefs.getString('languageCode') ?? 'en';
      _samplingIntervalSeconds = prefs.getInt('samplingInterval') ?? 1;
      _textController.text = savedToken!;
      _cadenceController.text = _samplingIntervalSeconds.toString();
    });
  }

  Future<String> _loadDefaultToken() async {
    try {
      final data = await rootBundle.loadString('assets/credentials.txt');
      final lines = data.split('\n');
      for (var line in lines) {
        if (line.startsWith('tokenOpenWeatherMaps=')) {
          return line.split('=')[1].trim();
        }
      }
    } catch (e) {
      print('Error reading config file: $e');
    }
    return '';
  }

  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tokenOpenWeatherMaps', _textController.text);
    await prefs.setInt('samplingInterval', _samplingIntervalSeconds);
  }

  void _changeLanguage(String languageCode) {
    MyApp.of(context).changeLanguage(languageCode);
    setState(() {
      _selectedLanguage = languageCode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: 'Token OpenWeatherMaps',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _savePreferences();
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _cadenceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Sample frequency (seconds)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                final seconds = int.tryParse(value);
                if (seconds != null && seconds > 0) {
                  _samplingIntervalSeconds = seconds;
                  _savePreferences();
                }
              },
            ),
            const SizedBox(height: 20),
            DropdownButton<String>(
              value: _selectedLanguage,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'es', child: Text('Español')),
                DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                DropdownMenuItem(value: 'el', child: Text('Ελληνικά')),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  _changeLanguage(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}