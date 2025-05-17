import 'package:diplom_fl/theme_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'start_bloc.dart';
import 'app_theme.dart';

class TemplateSelectionScreen extends StatefulWidget {
  const TemplateSelectionScreen({super.key});

  @override
  _TemplateSelectionScreenState createState() => _TemplateSelectionScreenState();
}

class _TemplateSelectionScreenState extends State<TemplateSelectionScreen> {
  String? selectedTemplate;

  void _selectTemplate(String template) {
    setState(() {
      selectedTemplate = template;
    });
  }

  final List<Map<String, String>> templates = [
    {"title": "fitnes", "image": "assets/fitnes.png",},
    {"title": "Фитнес-Студия", "image": "assets/fitnes.png"},
    // {"title": "Йога Центр", "image": "assets/fitnes.png"},
    // {"title": "Тренажёрный Зал", "image": "assets/fitnes.png"},
    // {"title": "Здоровый Образ", "image": "assets/fitnes.png"},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 170.0,),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Text(
                        "",
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildProgressBar(),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Начнем! Выберите шаблон для вашего приложения!",
                              style: theme.textTheme.titleLarge,
                            ),
                            SizedBox(height: 10),
                            Text("Выберите шаблон", style: theme.textTheme.bodyLarge),
                            SizedBox(height: 20),
                            Expanded(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  int crossAxisCount = constraints.maxWidth > 600 ? 5 : 2;
                                  return GridView.builder(
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: crossAxisCount,
                                      crossAxisSpacing: 10,
                                      mainAxisSpacing: 10,
                                      childAspectRatio: 0.9,
                                    ),
                                    itemCount: templates.length,
                                    itemBuilder: (context, index) {
                                      final item = templates[index];
                                      return _buildTemplateCard(item["title"]!, item["image"]!, theme);
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: selectedTemplate == null
                                    ? null
                                    : () {
                                        context.read<ProjectBloc>().add(SelectTemplate(selectedTemplate!));
                                      },
                                child: Text("Далее", style: TextStyle(color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTemplateCard(String title, String imagePath, ThemeData theme) {
    bool isSelected = selectedTemplate == title;
    return GestureDetector(
      onTap: () => _selectTemplate(title),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.primaryColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.asset(imagePath, fit: BoxFit.cover),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(title, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
    Widget _buildProgressBar() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      decoration: BoxDecoration(
        
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStep("1", "ВЫБРАТЬ ШАБЛОН", isActive: true, onTap: () => _goToStep(1)),
          _buildStep("2", "ВЫБРАТЬ ТЕМУ", onTap: () => _goToStep(2)),
          _buildStep("3", "ВЫБРАТЬ НАВИГАЦИЮ", onTap: () => _goToStep(3)),
          _buildStep("4", "НАЗВАТЬ ПРОЕКТ", onTap: () => _goToStep(4)),
          _buildStep("5", "СОЗДАТЬ", onTap: () => _goToStep(5)),
        ],
      ),
    );
  }

  Widget _buildStep(String stepNumber,
    String title, {
    bool isCompleted = false,
    bool isActive = false,
    required VoidCallback onTap, 
    }
  ) 
  {
    final theme = AppTheme.buildTheme();
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: isCompleted ? theme.primaryColor : (isActive ? theme.primaryColor : const Color.fromARGB(255, 197, 197, 197)),
          child: Text(stepNumber, style: TextStyle(color: Colors.white)),
        ),
        SizedBox(width: 5),
        Text(
          title,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
  void _goToStep(int step) {
    switch (step) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => TemplateSelectionScreen()), // Переход на Step1Screen
        );
        break;
    }
  }
}
