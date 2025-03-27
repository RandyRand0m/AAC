import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'start_bloc.dart';
import 'template_selection.dart';
import 'theme_selection.dart';
import 'name_selection.dart';

void main() {
  runApp(
    BlocProvider(
      create: (context) => ProjectBloc(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BlocListener<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ThemeSelectionState) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ThemeSelectionScreen(template: state.template),
              ),
            );
          } else if (state is ProjectNameState) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectNameScreen(
                  template: state.template,
                  theme: state.theme,
                ),
              ),
            );
          } else if (state is ProjectSavedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Проект успешно сохранен!")),
            );
          }
        },
        child: TemplateSelectionScreen(),
      ),
    );
  }
}