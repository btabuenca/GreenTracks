import 'package:flutter/material.dart';
import 'package:madtrack/controllers/auth_manager.dart';
import 'package:madtrack/screens/login_screen.dart';
import 'package:madtrack/widgets/slide_transition.dart';

class LogoutDialog extends StatelessWidget {
  const LogoutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("¿Quieres cerrar sesión?"),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, false);
          },
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () {
            AuthManager().signOut();
            Navigator.of(context).pushReplacement(
              SlideTransitionClass(
                page: const LoginScreen(),
                direction: 'right',
              ),
            );
          },
          child: const Text("Aceptar"),
        ),
      ],
    );
  }
}
