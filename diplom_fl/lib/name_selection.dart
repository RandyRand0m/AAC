import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectNameScreen extends StatefulWidget {
  final String template;
  final String theme;

  ProjectNameScreen({required this.template, required this.theme});

  @override
  _ProjectNameScreenState createState() => _ProjectNameScreenState();
}

class _ProjectNameScreenState extends State<ProjectNameScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isButtonActive = false;
  bool _isLoading = false;

  void _onNameChanged() {
    setState(() {
      _isButtonActive = _nameController.text.isNotEmpty;
    });
  }

  Future<void> saveProject() async {
    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://localhost:9096/projects/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": _nameController.text,
        "rules": {
          "template": widget.template,
          "theme": widget.theme,
        }
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Проект сохранён!")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: ${response.body}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Введите название проекта")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(labelText: "Название проекта"),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isButtonActive && !_isLoading ? saveProject : null,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text("Сохранить"),
            ),
          ],
        ),
      ),
    );
  }
}
