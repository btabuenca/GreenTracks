import 'package:flutter/material.dart';
import 'package:madtrack/models/auth_result.dart';
import 'package:madtrack/models/data_manager.dart';
import 'package:madtrack/controllers/auth_manager.dart';
import 'package:madtrack/screens/home_screen.dart';
import 'package:madtrack/widgets/my_app_bar.dart';
import 'package:madtrack/widgets/slide_transition.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailRegex = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
  bool _isObscure = true;
  bool _isObscure2 = true;
  bool _circleLoading = false;
  final Image _registerImage = Image.asset("assets/register_image.png");

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
                Image(image: _registerImage.image),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _usernameController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce un nombre de usuario';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    labelText: 'Nombre de usuario',
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
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
                const SizedBox(height: 10),
                _buildPasswordField2(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _circleLoading = true;
                      });
                      AuthResult result =
                          await AuthManager().registerWithEmailAndPassword(
                        _emailController.text.trim(),
                        _passwordController.text.trim(),
                        _usernameController.text.trim(),
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
                              'Error en el registro : ${result.errorMessage}'),
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
                        const Text('Registro'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField2() {
    return TextFormField(
      controller: _confirmPasswordController,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor, confirma tu contraseña';
        } else if (value != _passwordController.text) {
          return 'Las contraseñas no coinciden';
        }
        return null;
      },
      obscureText: _isObscure2,
      decoration: InputDecoration(
        labelText: 'Confirmar Contraseña',
        prefixIcon: const Icon(Icons.password),
        suffixIcon: IconButton(
          icon: Icon(_isObscure2 ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _isObscure2 = !_isObscure2;
            });
          },
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
