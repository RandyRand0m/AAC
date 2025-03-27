import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'start_bloc.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final String template;
  ThemeSelectionScreen({required this.template});

  @override
  _ThemeSelectionScreenState createState() => _ThemeSelectionScreenState();
}

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String? selectedTheme;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Выбор темы")),
      body: Column(
        children: [
          ListTile(
            title: Text("Светлая"),
            leading: Radio(
              value: "Светлая",
              groupValue: selectedTheme,
              onChanged: (value) {
                setState(() {
                  selectedTheme = value.toString();
                });
              },
            ),
          ),
          ListTile(
            title: Text("Темная"),
            leading: Radio(
              value: "Темная",
              groupValue: selectedTheme,
              onChanged: (value) {
                setState(() {
                  selectedTheme = value.toString();
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: selectedTheme == null ? null : () {
              context.read<ProjectBloc>().add(SelectTheme(selectedTheme!));
            },
            child: Text("Далее"),
          ),
        ],
      ),
    );
  }
}