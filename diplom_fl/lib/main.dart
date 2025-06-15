import 'dart:async';
import 'dart:io';
import 'package:diplom_fl/app_editor.dart';
import 'package:diplom_fl/app_theme.dart';
import 'package:diplom_fl/navigation_selection.dart';
import 'package:diplom_fl/overview.dart';
import 'package:diplom_fl/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'start_bloc.dart';
import 'template_selection.dart';
import 'theme_selection.dart';
import 'name_selection.dart';
import 'login.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory.web, 
  );

  HydratedBloc.storage = storage;

  runApp(
    BlocProvider(
      create: (_) => ProjectBloc(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _checkAuthFromPrefs();
  }

  void _checkAuthFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final token = prefs.getString('access_token');
    debugPrint('Prefs user_id: $userId');
    debugPrint('Prefs token: $token');
    if (userId != null && token != null && token.isNotEmpty) {
      context.read<ProjectBloc>().add(CheckAuthEvent(userId: userId));
    } else {
      context.read<ProjectBloc>().emit(LoginInitialState());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: BlocConsumer<ProjectBloc, ProjectState>(
        listener: (context, state) {
          if (state is ThemeSelectionState) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ThemeSelectionScreen(template: state.template, userId: state.userId,),
              ),
            );
          } else if (state is ProjectNameState) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectNameScreen(
                  template: state.template,
                  theme: state.theme,
                  navigate: state.navigate,
                  userId: context.read<ProjectBloc>().userId!,
                ),
              ),
            );
          } else if (state is ProjectSavedState) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Проект успешно сохранен!")),
            );
          } else if (state is ProjectLoadedState) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppEditor(projectId: state.id,userId: context.read<ProjectBloc>().userId!,),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is LoginInitialState || state is ProjectErrorState) {
            return LoginScreen();
          } else if (state is AuthenticatedState) {
            return ProjectsOverviewScreen(userId: state.userId);
          } else if (state is TemplateSelectionState) {
            return TemplateSelectionScreen(userId: state.userId);
          } else if (state is ThemeSelectionState) {
            return ThemeSelectionScreen(
              template: state.template,
              userId: context.read<ProjectBloc>().userId!,
            );
          } else if (state is NavigationSelectionState) {
            return NavigationSelectionScreen(
              template: state.template,
              theme: state.theme,
              userId: context.read<ProjectBloc>().userId!,
            );
          } else if (state is ProjectNameState) {
            return ProjectNameScreen(
              template: state.template,
              theme: state.theme,
              navigate: state.navigate,
              userId: context.read<ProjectBloc>().userId!,
            );
          } else {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
      onGenerateRoute: (settings) {
        if (settings.name == '/projects') {
          final args = settings.arguments;
          if (args is int) {
            return MaterialPageRoute(
              builder: (_) => ProjectsOverviewScreen(userId: args),
            );
          } else {
            return _errorRoute("userId не передан или неверного типа");
          }
        }

        if (settings.name == '/editor') {
          final args = settings.arguments;
          if (args is int) {
            return MaterialPageRoute(
              builder: (_) => AppEditor(projectId: args, userId: context.read<ProjectBloc>().userId!,),
            );
          } else {
            return _errorRoute("ID проекта не передан или неверного типа");
          }
        }

        if (settings.name == '/create') {
          return MaterialPageRoute(
            builder: (_) => TemplateSelectionScreen( userId: context.read<ProjectBloc>().userId!),
          );
        }
        if (settings.name == '/settings') {
          return MaterialPageRoute(
            builder: (_) => SettingsScreen(),
          );
        }
        if (settings.name == '/login') {
          return MaterialPageRoute(
            builder: (_) => LoginScreen(),
          );
        }

        return _errorRoute("Маршрут '${settings.name}' не найден");
      },
    );
  }

  MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Ошибка")),
        body: Center(child: Text(message)),
      ),
    );
  }
}
