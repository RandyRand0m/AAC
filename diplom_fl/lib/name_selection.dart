import 'package:diplom_fl/app_editor.dart';
import 'package:diplom_fl/templates.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectNameScreen extends StatefulWidget {
  final String template;
  final String theme;
  final String navigate;
  final int userId;
  const ProjectNameScreen({super.key, required this.template, required this.theme, required this.navigate, required this.userId});

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

  final defaultPages = getDefaultPagesByTemplate(widget.template);

  try {
    final response = await http.post(
      Uri.parse('http://localhost:9096/api/projects/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": _nameController.text,
        "user_id": widget.userId,
        "rules": {
          "template": widget.template,
          "theme": widget.theme,
          "navigation": widget.navigate,
          ...defaultPages, // pages
        },
      }),
    );

    if (response.statusCode == 200|| response.statusCode == 201) {
      final data = jsonDecode(response.body);
      final int projectId = data['id']; 

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Проект сохранён!")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppEditor(projectId: projectId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка при сохранении: ${response.body}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Ошибка соединения с сервером")),
    );
  }

    setState(() {
      _isLoading = false;
    });
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
