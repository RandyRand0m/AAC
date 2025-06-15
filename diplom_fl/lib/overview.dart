import 'package:diplom_fl/start_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:html' as html;

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
    userId = widget.userId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProjectBloc>().add(CheckAuthEvent(userId: userId));
    });
    fetchProjects();
  }

  Future<void> fetchProjects() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:9096/api/api/projects/user/$userId'),
      );

      if (response.statusCode == 200) {
        print('projects: $projects');
        setState(() {
          projects = jsonDecode(utf8.decode(response.bodyBytes));
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

  Future<void> _sendProjectToBuildBackend(int projectId) async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:9096/api/projects/$projectId/'),
      );

      if (response.statusCode == 200) {
        final projectData = jsonDecode(utf8.decode(response.bodyBytes));
        final jsonStr = jsonEncode(projectData);
        final bytes = utf8.encode(jsonStr);
        final blob = html.Blob([bytes]);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "config.json")
          ..click();

        html.Url.revokeObjectUrl(url);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка получения проекта: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showLeftMenu = screenWidth >= 800;

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/logo.png',
          height: 40,
        ),
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: Row(
        children: [
          if (showLeftMenu)
            Container(
              width: 200,
              color: const Color(0xFFF7F9FE),
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed('/projects', arguments: userId);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.view_quilt, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          " Все проекты",
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed('/editor', arguments: userId);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.phone_iphone, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          " Мое приложение",
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.image, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          " Контент",
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  InkWell(
                    onTap: () {},
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.public, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          " Публикация",
                          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  Divider(),
                  Text("Помощь", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushNamed('/settings');
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.settings, color: Colors.grey),
                        SizedBox(height: 4),
                        Text(
                          " Настройки",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // карточки проектов
          Expanded(
            child: Container(
              color: const Color.fromARGB(255, 255, 255, 255),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(child: Text(error!, style: TextStyle(color: Colors.red)))
                        : Container(
                          color: const Color.fromARGB(255, 255, 255, 255),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: screenWidth > 1200 ? 3 : 2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 1.7,
                            ),
                            itemCount: projects.length + 1, 
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return Card(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 0,
                                  color: Colors.blue[50],
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/create');
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(Icons.add_circle_outline, size: 48, color: Color(0xFFC080FF)),
                                          SizedBox(height: 16),
                                          Text("Создать новое приложение", style: Theme.of(context).textTheme.titleMedium),
                                          Spacer(),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: ElevatedButton.icon(
                                              onPressed: () {
                                                Navigator.pushNamed(context, '/create');
                                              },
                                              icon: Icon(Icons.add, color: Color.fromARGB(255, 255, 255, 255)),
                                              label: Text("Создать", style: TextStyle(color: Color.fromARGB(255, 255, 255, 255), fontFamily:"Manrope", fontSize: 14)),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFFC080FF),
                                                foregroundColor: Colors.black87,
                                                elevation: 0,
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                              final project = projects[index - 1]; 
                              return SizedBox(
                                width: 320,
                                height: 100,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                  color: Colors.grey[100],
                                  child: InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        '/editor',
                                        arguments: {
                                          'projectId': int.parse(project['id'].toString()),
                                          'userId': widget.userId,
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project['name'] ?? "Название проекта",
                                            style: GoogleFonts.manrope(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            "Последнее изменение ${project['updated_at'] ?? '—'}",
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Spacer(),
                                          LayoutBuilder(
                                            builder: (context, constraints) {
                                              final isSmallScreen = constraints.maxWidth < 300;
                                              return Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Flexible(
                                                    child: ElevatedButton.icon(
                                                      onPressed: () {
                                                        Navigator.pushNamed(
                                                          context,
                                                          '/editor',
                                                          arguments: int.parse(project['id'].toString()),
                                                        );
                                                      },
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Color(0xFFC080FF),
                                                        foregroundColor: Colors.black87,
                                                        elevation: 0,
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: isSmallScreen ? 8 : 10,
                                                          vertical: 8,
                                                        ),
                                                      ),
                                                      icon: Icon(Icons.edit, size: 16),
                                                      label: isSmallScreen 
                                                          ? SizedBox() 
                                                          : Text(
                                                              "Редактировать",
                                                              style: TextStyle(
                                                                color: Color.fromARGB(255, 255, 255, 255),
                                                                fontFamily: "Manrope",
                                                                fontSize: isSmallScreen ? 12 : 14,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                  Flexible(
                                                    child: OutlinedButton(
                                                      onPressed: () {
                                                        _sendProjectToBuildBackend(int.parse(project['id'].toString()));
                                                      },
                                                      style: OutlinedButton.styleFrom(
                                                        side: BorderSide(color: Color(0xFFC080FF)),
                                                        foregroundColor: Color(0xFFD4B5F9),
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: isSmallScreen ? 8 : 10,
                                                          vertical: 8,
                                                        ),
                                                      ),
                                                      child: isSmallScreen
                                                          ? Icon(Icons.download, size: 16, color: Color(0xFFC080FF))
                                                          : Text(
                                                              "Собрать приложение",
                                                              style: TextStyle(
                                                                color: Color(0xFFC080FF),
                                                                fontSize: isSmallScreen ? 12 : 14,
                                                              ),
                                                            ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        }