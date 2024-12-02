import 'package:flutter/material.dart';
import 'package:madtrack/models/auth_result.dart';
import 'package:madtrack/models/data_manager.dart';
import 'package:madtrack/controllers/auth_manager.dart';
import 'package:madtrack/screens/home_screen.dart';
import 'package:madtrack/screens/register_screen.dart';
import 'package:madtrack/widgets/my_app_bar.dart';
import 'package:madtrack/widgets/slide_transition.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
  bool _isObscure = true;
  bool _circleLoading = false;
  final Image _loginImage = Image.asset("assets/login_image.png");

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(
        showIcon: false,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Image(image: _loginImage.image),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce un email';
                    } else if (!_emailRegex.hasMatch(value)) {
                      return 'Introduce un correo electrónico válido';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 10),
                _buildPasswordField(),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _circleLoading = true;
                      });
                      AuthResult result =
                          await AuthManager().signInWithEmailAndPassword(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                      );
                      setState(() {
                        _circleLoading = false;
                      });
                      if (result.success) {
                        // ignore: use_build_context_synchronously
                        Navigator.pushReplacement(
                          context,
                          SlideTransitionClass(
                              page: const HomeScreen(), direction: 'left'),
                        );
                        DataManager().updateData();
                      } else {
                        final snackBar = SnackBar(
                          content: Text(
                              'Error en el inicio de sesión: ${result.errorMessage}'),
                          duration: const Duration(seconds: 2),
                        );
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(snackBar);
                      }
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_circleLoading)
                          Container(
                            padding: const EdgeInsets.only(right: 18.0),
                            child: const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        const Text('Login'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '¿Aún no tienes usuario? ',
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          SlideTransitionClass(
                              page: const RegisterScreen(), direction: 'top'),
                        );
                      },
                      child: const Text('Regístrate'),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Introduce una contraseña';
        } else if (value.length < 6) {
          return 'La contraseña debe tener al menos 6 caracteres';
        }
        return null;
      },
      obscureText: _isObscure,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_isObscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure;
            });
          },
        ),
      ),
    );
  }
}
