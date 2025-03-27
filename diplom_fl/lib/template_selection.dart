import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'start_bloc.dart';

class TemplateSelectionScreen extends StatefulWidget {
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
    {"title": "Фитнес-Клуб", "image": "assets/fitnes.png"},
    {"title": "Фитнес-Студия", "image": "assets/fitnes.png"},
    {"title": "Йога Центр", "image": "assets/fitnes.png"},
    {"title": "Тренажёрный Зал", "image": "assets/fitnes.png"},
    {"title": "Здоровый Образ", "image": "assets/fitnes.png"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Выбор шаблона")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Начнем! Выберите шаблон для вашего приложения!",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text("Выберите шаблон", style: TextStyle(fontSize: 16)),
            SizedBox(height: 20),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 600 ? 5 : 2; // Адаптация под экран
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount, // Кол-во колонок зависит от ширины экрана
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.9, // Пропорции карточек
                    ),
                    itemCount: templates.length,
                    itemBuilder: (context, index) {
                      final item = templates[index];
                      return _buildTemplateCard(item["title"]!, item["image"]!);
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
                child: Text("Далее"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(String title, String imagePath) {
    bool isSelected = selectedTemplate == title;
    return GestureDetector(
      onTap: () => _selectTemplate(title),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.pink : Colors.transparent,
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
              child: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
