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
  print(jsonEncode(defaultPages));

  try {
    final response = await http.post(
      Uri.parse('http://localhost:9096/api/projects/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "name": _nameController.text,
        "user_id": widget.userId,
        "theme": widget.theme,
        "template": widget.template,
        "navBarType": widget.navigate == 'Нижнее меню' ? 0 : 1,
        "pages": defaultPages["pages"],
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
          builder: (context) => AppEditor(projectId: projectId, userId: widget.userId,),
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 170.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/GYMAPP.png',
                        height: 40,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Введите название проекта",
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Придумайте уникальное имя для вашего проекта",
                        style: theme.textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 30),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: "Название проекта",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton(
                          onPressed: _isButtonActive && !_isLoading ? saveProject : null,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text("Сохранить"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}