import 'package:diplom_fl/app_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ProjectEvent {}

class LogoutEvent extends ProjectEvent {}
class LoginEvent extends ProjectEvent {
  final String phone;
  final String code;

  LoginEvent(this.phone, this.code);
}
class CheckAuthEvent extends ProjectEvent {
  final int userId;
  CheckAuthEvent({required this.userId});
}

class LoginInitialState extends ProjectState {}

class AuthenticatedState extends ProjectState {
  final int userId;
  AuthenticatedState({required this.userId});
}

class SelectTemplate extends ProjectEvent {
  final String template;
  SelectTemplate(this.template);
}

class SelectTheme extends ProjectEvent {
  final String theme;
  SelectTheme(this.theme);
}

class SelectNavigation extends ProjectEvent {
  final String navigate;
  SelectNavigation(this.navigate);
}

class EnterProjectName extends ProjectEvent {
  final String name;
  EnterProjectName(this.name);
}

class SaveProject extends ProjectEvent {}

class LoadProjectById extends ProjectEvent {
  final int id;
  LoadProjectById(this.id);
}

abstract class ProjectState {}

class TemplateSelectionState extends ProjectState {
  final int userId;
  TemplateSelectionState(this.userId);
}

class ThemeSelectionState extends ProjectState {
  final String template;
  final int userId;
  ThemeSelectionState(this.template, this.userId);
}

class NavigationSelectionState extends ProjectState {
  final String template;
  final String theme;
  final String? navigate;

  NavigationSelectionState(this.template, this.theme, [this.navigate]);
}

class ProjectNameState extends ProjectState {
  final String template;
  final String theme;
  final String navigate;
  final String? name;
  ProjectNameState(this.template, this.theme, this.navigate, {this.name});
}

class ProjectSavingState extends ProjectState {}

class ProjectSavedState extends ProjectState {
  final int projectId;
  ProjectSavedState(this.projectId);
}

class ProjectErrorState extends ProjectState {
  final String error;
  ProjectErrorState(this.error);
}

class ProjectLoadedState extends ProjectState {
  final int id;
  final String name;
  final Map<String, dynamic> rules;

  ProjectLoadedState({
    required this.id,
    required this.name,
    required this.rules,
  });
}

class AppStarted extends ProjectEvent {}
class CheckingAuthState extends ProjectState {}
class LoadProjectsOverview extends ProjectEvent {
  final int userId;
  LoadProjectsOverview(this.userId);
}

class WidgetSelectedForEdit extends ProjectState {
  final WidgetItem selectedWidget;
  WidgetSelectedForEdit(this.selectedWidget);
}
class SelectWidgetForEdit extends ProjectEvent {
  final WidgetItem widget;

  SelectWidgetForEdit(this.widget);
}
class ProjectsOverviewState extends ProjectState {
  final int userId;
  ProjectsOverviewState(this.userId);
}
class UpdateWidgetEvent extends ProjectEvent {
  final int pageIndex;
  final int widgetIndex;
  final WidgetItem updatedWidget;

  UpdateWidgetEvent({
    required this.pageIndex,
    required this.widgetIndex,
    required this.updatedWidget,
  });
}
class EditWidgetState extends ProjectState {
  final WidgetItem widgetItem;
  final int pageIndex;
  final int widgetIndex;

  EditWidgetState({
    required this.widgetItem,
    required this.pageIndex,
    required this.widgetIndex,
  });
}
class ProjectBloc extends HydratedBloc<ProjectEvent, ProjectState> {
  String? selectedTemplate;
  String? selectedTheme;
  String? selectedNavigation;
  String? projectName;
  int? createdProjectId;
  int? userId;

  ProjectBloc() : super(LoginInitialState()) {
    _checkAuthOnStart();

   
    on<LoginEvent>((event, emit) async {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:9096/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "phone": event.phone,
            "code": event.code,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', data['access_token']);
          await prefs.setInt('user_id', data['user_id']);
          userId = data['user_id'];
          emit(AuthenticatedState(userId: data['user_id']));
        } else {
          emit(ProjectErrorState("Ошибка входа: ${response.body}"));
        }
      } catch (e) {
        emit(ProjectErrorState("Ошибка соединения при входе"));
      }
    });
    on<SelectTemplate>((event, emit) {
      selectedTemplate = event.template;
      emit(ThemeSelectionState(event.template, userId!));
    });
    on<CheckAuthEvent>((event, emit) async {
      debugPrint('>>> [CheckAuthEvent] user_id: ${event.userId}');
      userId = event.userId;
      if (event.userId != null) {
        emit(AuthenticatedState(userId: event.userId));
      } else {
        emit(LoginInitialState());
      }
    });
    on<SelectTheme>((event, emit) {
      selectedTheme = event.theme;
      if (selectedTemplate != null) {
        emit(NavigationSelectionState(selectedTemplate!, selectedTheme!));
      } else {
        emit(ProjectErrorState("Выберите шаблон перед темой"));
      }
    });

    on<SelectNavigation>((event, emit) {
      selectedNavigation = event.navigate;
      emit(ProjectNameState(
        selectedTemplate!, 
        selectedTheme!,
        selectedNavigation!
      ));
    });

    on<EnterProjectName>((event, emit) {
      projectName = event.name;
      emit(ProjectNameState(
        selectedTemplate!,
        selectedTheme!,
        selectedNavigation!,
        name: projectName,
      ));
    });

    on<SaveProject>((event, emit) async {
      if (projectName == null || projectName!.isEmpty) {
        emit(ProjectErrorState("Название проекта не может быть пустым"));
        return;
      }

      emit(ProjectSavingState());

      try {
        final response = await http.post(
          Uri.parse('https://konstaya.online/api/api/projects/'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "name": projectName,
            "rules": {
              "template": selectedTemplate,
              "theme": selectedTheme,
              "navigation": selectedNavigation,
            }
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          createdProjectId = data['id'];
          emit(ProjectSavedState(createdProjectId!));
        } else {
          emit(ProjectErrorState("Ошибка: ${response.body}"));
        }
      } catch (e) {
        emit(ProjectErrorState("Ошибка соединения с сервером"));
      }
    });

    on<LoadProjectById>((event, emit) async {
      try {
        final response = await http.get(
          Uri.parse('http://localhost:9096/projects/${event.id}/'),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          emit(ProjectLoadedState(
            id: data['id'],
            name: data['name'],
            rules: Map<String, dynamic>.from(data['rules']),
          ));
        } else {
          emit(ProjectErrorState("Проект не найден: ${response.body}"));
        }
      } catch (e) {
        emit(ProjectErrorState("Ошибка загрузки проекта"));
      }
    }
    );
    on<AppStarted>((event, emit) async {
      emit(CheckingAuthState());

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      final token = prefs.getString('access_token');

      if (userId != null && token != null && token.isNotEmpty) {
        this.userId = userId; 
        emit(AuthenticatedState(userId: userId));
      } else {
        emit(LoginInitialState());
      }
    });
    
    on<SelectWidgetForEdit>((event, emit) {
      emit(WidgetSelectedForEdit(event.widget));
    });
    on<LogoutEvent>((event, emit) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('user_id');

      selectedTemplate = null;
      selectedTheme = null;
      selectedNavigation = null;
      projectName = null;
      createdProjectId = null;
      userId = null;

      emit(LoginInitialState());
    });

  }

  void _checkAuthOnStart() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId != null) {
      add(CheckAuthEvent(userId: userId));
    }
  }

  @override
  ProjectState? fromJson(Map<String, dynamic> json) {
    try {
      final stateType = json['state'] as String?;

      selectedTemplate = json['selectedTemplate'];
      selectedTheme = json['selectedTheme'];
      selectedNavigation = json['selectedNavigation'];
      projectName = json['projectName'];
      createdProjectId = json['createdProjectId'];
      userId = json['userId'];

      switch (stateType) {
        case 'LoginInitialState':
          return LoginInitialState();
        case 'AuthenticatedState':
          return AuthenticatedState(userId: userId!);
        case 'ThemeSelectionState':
          if (selectedTemplate != null) {
            return ThemeSelectionState(selectedTemplate!, userId!);
          }
          break;
        case 'NavigationSelectionState':
          if (selectedTemplate != null && selectedTheme != null) {
            return NavigationSelectionState(selectedTemplate!, selectedTheme!);
          }
          break;
        case 'ProjectNameState':
          if (selectedTemplate != null && selectedTheme != null && selectedNavigation != null) {
            return ProjectNameState(
              selectedTemplate!,
              selectedTheme!,
              selectedNavigation!,
              name: projectName,
            );
          }
          break;
        case 'ProjectSavedState':
          if (createdProjectId != null) {
            return ProjectSavedState(createdProjectId!);
          }
          break;
        case 'ProjectLoadedState':
          final id = json['projectId'] as int?;
          final name = json['projectNameLoaded'] as String?;
          final rules = json['rules'] != null
              ? Map<String, dynamic>.from(json['rules'])
              : null;
          if (id != null && name != null && rules != null) {
            return ProjectLoadedState(id: id, name: name, rules: rules);
          }
          break;
          
        case 'ProjectsOverviewState':
          final userId = json['userId'] as int?;
          if (userId != null) {
            return ProjectsOverviewState(userId);
          }
          break;
          
        case 'ProjectErrorState':
          final message = json['errorMessage'] as String? ?? "Ошибка";
          return ProjectErrorState(message);
      }

      return null;
    } catch (e) {
      debugPrint("Ошибка при десериализации состояния: $e");
      return null;
    }
  }

  @override
  Map<String, dynamic>? toJson(ProjectState state) {
    final Map<String, dynamic> json = {
      'state': state.runtimeType.toString(),
      'selectedTemplate': selectedTemplate,
      'selectedTheme': selectedTheme,
      'selectedNavigation': selectedNavigation,
      'projectName': projectName,
      'createdProjectId': createdProjectId,
      'userId': userId,
    };

    if (state is LoginInitialState) {
      json['state'] = 'LoginInitialState';
    } else if (state is AuthenticatedState) {
      json['state'] = 'AuthenticatedState';
    } else if (state is ThemeSelectionState) {
      json['state'] = 'ThemeSelectionState';
    } else if (state is NavigationSelectionState) {
      json['state'] = 'NavigationSelectionState';
    } else if (state is ProjectNameState) {
      json['state'] = 'ProjectNameState';
    } else if (state is ProjectSavedState) {
      json['state'] = 'ProjectSavedState';
    } else if (state is ProjectLoadedState) {
      json['state'] = 'ProjectLoadedState';
      json['projectId'] = state.id;
      json['projectNameLoaded'] = state.name;
      json['rules'] = state.rules;
    } else if (state is ProjectsOverviewState) {
      json['state'] = 'ProjectsOverviewState';
      json['userId'] = state.userId;
    } else if (state is ProjectErrorState) {
      json['state'] = 'ProjectErrorState';
      //json['errorMessage'] = state.message;
    } 
    
    else {

      return null;
    }

    return json;
  }
}