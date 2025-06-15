import 'package:diplom_fl/name_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'start_bloc.dart';
import 'app_theme.dart';

class NavigationSelectionScreen extends StatefulWidget {
  final String template;
  final String theme;
  final int userId;

  const NavigationSelectionScreen({super.key, required this.template, required this.theme, required this.userId,});

  @override
  _NavigationSelectionScreenState createState() => _NavigationSelectionScreenState();
}

final List<Map<String, String>> navigates = [
    {"title": "Бургер-навигация", "image": "assets/fitnes.png","name": "Бургер-навигация"},
    {"title": "Нижнее меню", "image": "assets/fitnes.png","name": "Нижнее меню"},
];

class _NavigationSelectionScreenState extends State<NavigationSelectionScreen> {
  String? selectedNavigation;

  @override
  void initState() {
    super.initState();
    final state = context.read<ProjectBloc>().state;
    if (state is NavigationSelectionState) {
      selectedNavigation = state.navigate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocListener<ProjectBloc, ProjectState>(
    listener: (context, state) {
      if (state is ProjectNameState) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectNameScreen(
              template: state.template,
              theme: state.theme,
              navigate: state.navigate,
              userId: widget.userId,
            ),
          ),
        );
      }
    },
    child: Scaffold(
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
                  _buildProgressBar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Выберите навигацию!",
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
                                  itemCount: navigates.length,
                                  itemBuilder: (context, index) {
                                    final item = navigates[index];
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedNavigation = item["title"];
                                        });
                                      },
                                      child: _buildNavigationCard(item["title"]!, item["image"]!, theme),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: selectedNavigation == null
                              ? null
                              : () {
                                  context.read<ProjectBloc>().add(SelectNavigation(selectedNavigation!));
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProjectNameScreen(
                                        template: widget.template,
                                        theme: widget.theme,
                                        navigate: selectedNavigation!,
                                        userId: widget.userId,
                                      ),
                                    ),
                                  );
                                },
                              child: Text("Далее", style: TextStyle(color: Colors.white)),
                            ),
                          )
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
    )
  );
}

  Widget _buildNavigationCard(String title, String imagePath, ThemeData theme) {
    bool isSelected = selectedNavigation == title;
    return Container(
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
          _buildStep("2", "ВЫБРАТЬ ТЕМУ", isCompleted: true),
          _buildStep("3", "ВЫБРАТЬ НАВИГАЦИЮ", isActive: true),
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
}