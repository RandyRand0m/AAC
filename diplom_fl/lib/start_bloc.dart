import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

abstract class ProjectEvent {}

class SelectTemplate extends ProjectEvent {
  final String template;
  SelectTemplate(this.template);
}

class SelectTheme extends ProjectEvent {
  final String theme;
  SelectTheme(this.theme);
}

class EnterProjectName extends ProjectEvent {
  final String name;
  EnterProjectName(this.name);
}

class SaveProject extends ProjectEvent {}

abstract class ProjectState {}

class TemplateSelectionState extends ProjectState {}

class ThemeSelectionState extends ProjectState {
  final String template;
  ThemeSelectionState(this.template);
}

class ProjectNameState extends ProjectState {
  final String template;
  final String theme;
  final String? name;
  ProjectNameState(this.template, this.theme, {this.name});
}

class ProjectSavingState extends ProjectState {}

class ProjectSavedState extends ProjectState {}

class ProjectErrorState extends ProjectState {
  final String error;
  ProjectErrorState(this.error);
}

class ProjectBloc extends Bloc<ProjectEvent, ProjectState> {
  String? selectedTemplate;
  String? selectedTheme;
  String? projectName;

  ProjectBloc() : super(TemplateSelectionState()) {
    on<SelectTemplate>((event, emit) {
      selectedTemplate = event.template;
      emit(ThemeSelectionState(event.template));
    });

    on<SelectTheme>((event, emit) {
      selectedTheme = event.theme;
      emit(ProjectNameState(selectedTemplate!, selectedTheme!));
    });

    on<EnterProjectName>((event, emit) {
      projectName = event.name;
      emit(ProjectNameState(selectedTemplate!, selectedTheme!, name: projectName));
    });

    on<SaveProject>((event, emit) async {
      if (projectName == null || projectName!.isEmpty) {
        emit(ProjectErrorState("Название проекта не может быть пустым"));
        return;
      }

      emit(ProjectSavingState());

      try {
        final response = await http.post(
          Uri.parse('http://localhost:9096/projects/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": projectName,
            "rules": {
              "template": selectedTemplate,
              "theme": selectedTheme,
            }
          }),
        );

        if (response.statusCode == 200) {
          emit(ProjectSavedState());
        } else {
          emit(ProjectErrorState("Ошибка: ${response.body}"));
        }
      } catch (e) {
        emit(ProjectErrorState("Ошибка соединения с сервером"));
      }
    });
  }
}
