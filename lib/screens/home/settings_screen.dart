import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _switchValue = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  // Cargar las preferencias guardadas
  Future<void> _loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedToken = prefs.getString('tokenOpenWeatherMaps');
    if (savedToken == null || savedToken.isEmpty) {
      String defaultToken = await _loadDefaultToken();
      await prefs.setString('tokenOpenWeatherMaps', defaultToken);
      savedToken = defaultToken;
    }
    setState(() {
      _switchValue = prefs.getBool('switchValue') ?? false;
      _textController.text = savedToken!;
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
      // Handle the error if the file cannot be read
      print('Error reading config file: $e');
    }
    return '';
  }

  // Guardar las preferencias
  Future<void> _savePreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('switchValue', _switchValue);
    await prefs.setString('tokenOpenWeatherMaps', _textController.text);
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
            SwitchListTile(
              title: const Text('Opción habilitada'),
              value: _switchValue,
              onChanged: (bool value) {
                setState(() {
                  _switchValue = value;
                });
                _savePreferences();
              },
            ),
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
          ],
        ),
      ),
    );
  }
}