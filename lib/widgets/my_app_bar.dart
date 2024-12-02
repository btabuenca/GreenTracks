import 'package:flutter/material.dart';
import 'package:madtrack/screens/login_screen.dart';
import 'package:madtrack/widgets/slide_transition.dart';
import 'package:madtrack/main.dart';
import 'package:madtrack/controllers/auth_manager.dart';

class MyAppBar extends StatefulWidget implements PreferredSizeWidget {
  final bool showIcon;

  // ignore: use_super_parameters
  const MyAppBar({Key? key, required this.showIcon}) : super(key: key);

  @override
  // ignore: library_private_types_in_public_api
  _MyAppBarState createState() => _MyAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(58.0);
}

class _MyAppBarState extends State<MyAppBar> {
  late bool isDarkMode;
  DateTime? _lastPressedTime;
  @override
  void initState() {
    if (MyApp.of(context).getThemeMode().name == "light") {
      isDarkMode = false;
    } else {
      isDarkMode = true;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      title: const Row(
        children: [
          Text(
            'MadTrack',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Icon(
            Icons.gps_fixed,
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: isDarkMode
              ? const Icon(Icons.dark_mode)
              : const Icon(Icons.light_mode),
          onPressed: () {
            _toggleTheme(context);
          },
        ),
        if (widget.showIcon)
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              if (_lastPressedTime == null ||
                  DateTime.now().difference(_lastPressedTime!) >
                      const Duration(seconds: 2)) {
                _lastPressedTime = DateTime.now();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pulsa dos veces para cerrar sesión'),
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                AuthManager().signOut();
                Navigator.of(context).pushReplacement(
                  SlideTransitionClass(
                    page: const LoginScreen(),
                    direction: 'right',
                  ),
                );
              }
            },
          ),
      ],
    );
  }

  void _toggleTheme(BuildContext context) {
    var currentThemeMode = MyApp.of(context).getThemeMode();
    MyApp.of(context).changeTheme(
      currentThemeMode.name == "light" ? ThemeMode.dark : ThemeMode.light,
    );

    setState(() {
      isDarkMode = !isDarkMode;
    });
  }
}
