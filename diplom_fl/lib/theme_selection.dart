import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'navigation_selection.dart';
import 'start_bloc.dart';
import 'app_theme.dart';

class ThemeSelectionScreen extends StatefulWidget {
  final String template;
  final int userId;
  const ThemeSelectionScreen({super.key, required this.template, required this.userId});

  @override
  _ThemeSelectionScreenState createState() => _ThemeSelectionScreenState();
}

final List<Map<String, String>> themes = [
  {"title": "Светлая", "image": "assets/fitnes.png"},
  {"title": "Темная", "image": "assets/fitnes.png"},
  
];

class _ThemeSelectionScreenState extends State<ThemeSelectionScreen> {
  String? selectedTheme;

  void _selectTheme(String theme) {
    setState(() {
      selectedTheme = theme;
    });
  }

  @override
  Widget build(BuildContext context) {
  final theme = Theme.of(context);

  return Scaffold(
    backgroundColor: theme.scaffoldBackgroundColor,
    body: BlocListener<ProjectBloc, ProjectState>(
      listener: (context, state) {
        if (state is NavigationSelectionState) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NavigationSelectionScreen(
                template: state.template,
                theme: state.theme,
                userId: widget.userId,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(left: 170.0, right: 170.0),
        child: Column(
          children: [
            // AppBar
            Container(
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: Image.asset(
                      'assets/GYMAPP.png',
                      height: 40,),
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
                              "Выберите тему для вашего приложения!",
                              style: theme.textTheme.titleLarge,
                            ),
                            SizedBox(height: 10),
                            Text("Выберите тему", style: theme.textTheme.bodyLarge),
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
                                    itemCount: themes.length,
                                    itemBuilder: (context, index) {
                                      final item = themes[index];
                                      return _buildThemeOption(item["title"]!, item["image"]!, theme);
                                    },
                                  );
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Center(
                              child: ElevatedButton(
                                onPressed: selectedTheme == null
                                ? null
                                : () {
                                    context.read<ProjectBloc>().add(SelectTheme(selectedTheme!));
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => NavigationSelectionScreen(
                                          template: widget.template,
                                          theme: selectedTheme!,
                                          userId: widget.userId,
                                        ),
                                      ),
                                    );
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
    ),
  );
}

  Widget _buildThemeOption(String title, String imagePath, ThemeData theme) {
    bool isSelected = selectedTheme == title;
    return GestureDetector(
      onTap: () => _selectTheme(title),
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
          _buildStep("1", "ВЫБРАТЬ ШАБЛОН", isCompleted: true),
          _buildStep("2", "ВЫБРАТЬ ТЕМУ", isActive: true),
          _buildStep("3", "ВЫБРАТЬ НАВИГАЦИЮ"),
          _buildStep("4", "НАЗВАТЬ ПРОЕКТ"),
          _buildStep("5", "СОЗДАТЬ"),
        ],
      ),
    );
  }

  Widget _buildStep(String stepNumber, String title, {bool isCompleted = false, bool isActive = false}) {
    final theme = AppTheme.buildTheme();
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: isCompleted ? theme.primaryColor : (isActive ? theme.primaryColor: const Color.fromARGB(255, 197, 197, 197)),
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
}