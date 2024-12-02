import 'package:flutter/material.dart';

class SaveRoute extends StatefulWidget {
  final Function(String)? onSave;

  const SaveRoute({super.key, this.onSave});

  @override
  _SaveRouteState createState() => _SaveRouteState();
}

class _SaveRouteState extends State<SaveRoute> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Guarda tu ruta!",
                  style: TextStyle(fontSize: 25.0),
                ),
              ),
              TextFormField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: "Nombre",
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Campo obligatorio';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              widget.onSave?.call(_controller.text);
              Navigator.pop(context);
            }
          },
          child: const Text("Guardar"),
        ),
      ],
    );
  }
}
