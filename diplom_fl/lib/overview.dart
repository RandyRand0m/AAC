import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProjectsOverviewScreen extends StatefulWidget {
  final int userId;
  const ProjectsOverviewScreen({required this.userId, Key? key}) : super(key: key);

  @override
  State<ProjectsOverviewScreen> createState() => _ProjectsOverviewScreenState();
}

class _ProjectsOverviewScreenState extends State<ProjectsOverviewScreen> {
  late int userId;
  List<dynamic> projects = [];
  bool isLoading = true;
  String? error;
  
  @override
  void initState() {
    super.initState();
    userId = widget.userId;  // берем из конструктора
    fetchProjects();
  }
  // @override
  // void didChangeDependencies() {
  //   super.didChangeDependencies();
  //   final args = ModalRoute.of(context)?.settings.arguments;
  //   if (args is int) {
  //     userId = args;
  //     fetchProjects();
  //   } else {
  //     setState(() {
  //       error = "Ошибка: не удалось получить userId";
  //       isLoading = false;
  //     });
  //   }
  // }

  Future<void> fetchProjects() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:9096/api/api/projects/user/$userId'),
      );

      if (response.statusCode == 200) {
        print('projects: $projects');
        setState(() {
          projects = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Ошибка загрузки: ${response.statusCode}";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = "Ошибка: $e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showLeftMenu = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Text("GYMAPP проекты", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Row(
        children: [
          if (showLeftMenu)
            Container(
              width: 200,
              color: const Color.fromARGB(255, 247, 249, 254),
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Все проекты", style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 12),
                  Text("Моё приложение"),
                  SizedBox(height: 12),
                  Text("Контент"),
                  SizedBox(height: 12),
                  Text("Публикация"),
                  Spacer(),
                  Divider(),
                  Text("Помощь", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  Text("Настройки", style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // Правая часть: карточки проектов
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
                      : projects.isEmpty
                          ? Center(child: Text("Нет доступных проектов"))
                          : GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: screenWidth > 1200 ? 3 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 4 / 3,
                              ),
                              itemCount: projects.length,
                              itemBuilder: (context, index) {
                                final project = projects[index];
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 4,
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/editor',
                                        arguments: int.parse(project['id'].toString()), // или передавайте весь объект
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(project['name'] ?? "Без названия", style: Theme.of(context).textTheme.titleMedium),
                                          SizedBox(height: 8),
                                          Text("Шаблон: ${project['template'] ?? "Не указан"}", style: TextStyle(color: Colors.grey[700])),
                                          Spacer(),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.pushNamed(
                                                  context,
                                                  '/editor',
                                                  arguments: int.parse(project['id'].toString()),
                                                );
                                              },
                                              icon: Icon(Icons.edit),
                                              label: Text("Открыть"),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }
}
