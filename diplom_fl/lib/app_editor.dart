import 'dart:convert';
import 'package:diplom_fl/widgets/club_card_widget.dart';
import 'package:diplom_fl/gac_models%20(2).dart';
import 'package:diplom_fl/start_bloc.dart';
import 'package:diplom_fl/widget_editor.dart';
import 'package:diplom_fl/widgets/club_info_widget.dart';
import 'package:diplom_fl/widgets/custom_button_widget.dart';
import 'package:diplom_fl/widgets/nearest_record_widget.dart';
import 'package:diplom_fl/widgets/record.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'widgets/bottom_nav_bar.dart';
import 'widgets/drawer_nav_bar.dart';

class AppEditor extends StatefulWidget {
  final int userId;
  final int projectId;
  const AppEditor({super.key, required this.projectId, required this.userId});

  @override
  State<AppEditor> createState() => _AppEditorState();
}
class ThemeScheme {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color surfaceColor;
  final Color errorColor;
  final Color buttonColor;
  final Color borderColor;
  final Color iconColor;

  const ThemeScheme({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.surfaceColor,
    required this.errorColor,
    required this.buttonColor,
    required this.borderColor,
    required this.iconColor,
  });
}

Map<String, ThemeScheme> availableThemes = {
  'light': ThemeScheme(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    accentColor: Colors.blue,
    primaryColor: Colors.blue,
    secondaryColor: Colors.lightBlueAccent,
    surfaceColor: Color(0xFFF5F5F5),
    errorColor: Colors.red,
    buttonColor: Colors.blueAccent,
    borderColor: Colors.grey,
    iconColor: Colors.black,
  ),
  'dark': ThemeScheme(
    backgroundColor: Color(0xFF121212),
    textColor: Colors.white,
    accentColor: Colors.deepPurpleAccent,
    primaryColor: Colors.deepPurple,
    secondaryColor: Colors.purple,
    surfaceColor: Color(0xFF1E1E1E),
    errorColor: Colors.redAccent,
    buttonColor: Colors.deepPurple,
    borderColor: Color(0xFF333333),
    iconColor: Colors.white70,
  ),
  'green': ThemeScheme(
    backgroundColor: Color(0xFFE8F5E9),
    textColor: Colors.green[900]!,
    accentColor: Colors.teal,
    primaryColor: Colors.green,
    secondaryColor: Colors.lightGreen,
    surfaceColor: Color(0xFFC8E6C9),
    errorColor: Colors.red[400]!,
    buttonColor: Colors.teal[700]!,
    borderColor: Colors.green[200]!,
    iconColor: Colors.green[800]!,
  ),
  'blue': ThemeScheme(
    backgroundColor: Color(0xFFE3F2FD),
    textColor: Colors.blue[900]!,
    accentColor: Colors.indigo,
    primaryColor: Colors.lightBlue,
    secondaryColor: Colors.indigoAccent,
    surfaceColor: Color(0xFFBBDEFB),
    errorColor: Colors.redAccent,
    buttonColor: Colors.indigo[700]!,
    borderColor: Colors.blue[200]!,
    iconColor: Colors.indigo,
  ),
  'dellGenoa': ThemeScheme(
    backgroundColor: Color(0xFF0076CE),
    textColor: Colors.white,
    accentColor: Color(0xFF39C2D7),
    primaryColor: Color(0xFF0076CE),
    secondaryColor: Color(0xFF003366),
    surfaceColor: Color(0xFF004B87),
    errorColor: Colors.redAccent,
    buttonColor: Color(0xFF006BB6),
    borderColor: Colors.white38,
    iconColor: Colors.white,
  ),
};
class WidgetTemplate {
  final String widgetName;
  final int category;
  final Map<String, dynamic> metadata;

  WidgetTemplate({
    required this.widgetName,
    required this.category,
    required this.metadata,
  });

  factory WidgetTemplate.fromJson(Map<String, dynamic> json) {
    return WidgetTemplate(
      widgetName: json['widgetName'],
      category: json['category'],
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {'properties': {}}),
    );
  }
}

class WidgetItem {
  final String id;
  final int categoryId;
  final String type;
  final Map<String, dynamic> metadata;
  Map<String, dynamic> properties;
  
  WidgetItem({
    required this.id,
    required this.categoryId,
    required this.type,
    required this.metadata,
    required this.properties,
  });
  
  Map<String, Map<String, dynamic>> get propertiesSchema {
    final rawProps = metadata['properties'];
    final props = rawProps is Map ? Map<String, dynamic>.from(rawProps) : {};
    
    return Map.fromEntries(
      props.entries.where(
        (entry) => entry.value is Map && entry.value.containsKey('type'),
      ).map(
        (entry) => MapEntry(entry.key, Map<String, dynamic>.from(entry.value)),
      ),
    );
  }

  factory WidgetItem.fromJson(Map<String, dynamic> json) {
    final metadata = Map<String, dynamic>.from(json['metadata'] ?? {});
    final propertiesRaw = metadata['properties'] ?? {};
    
    final propertiesMap = propertiesRaw is Map 
        ? Map<String, dynamic>.from(propertiesRaw) 
        : <String, dynamic>{};

    final fixedProperties = <String, dynamic>{};
    propertiesMap.forEach((key, value) {
      if (value is Map && value.containsKey('default')) {
        fixedProperties[key] = value['default'];
      } else if (value is Map) {
        // Для вложенных объектов сохраняем всю структуру
        fixedProperties[key] = value;
      } else {
        fixedProperties[key] = value;
      }
    });

    return WidgetItem(
      id: json['id']?.toString() ?? UniqueKey().toString(),
      categoryId: json['category_id'] ?? 0,
      type: metadata['type'] ?? 'unknown',
      metadata: metadata,
      properties: fixedProperties,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "category_id": categoryId,
      "metadata": {
        "type": type,
        "properties": propertiesSchema.map((key, schema) {
          return MapEntry(key, {
            "type": schema['type'],
            "default": properties[key],
            "label": schema['label'] ?? key,
          });
        }),
      },
    };
  }
}

class PageData {
  final String? id;
  final String title;
  List<WidgetItem> widgets;

  PageData({
    required this.id,
    required this.title,
    required this.widgets,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'widgetsList': widgets.map((w) => w.toJson()).toList(),
  };

  factory PageData.fromJson(Map<String, dynamic> json) {
    return PageData(
      id: json['id']?.toString(),
      title: json['title'] ?? 'Новая страница',
      widgets: (json['widgetsList'] as List<dynamic>?)
          ?.where((w) => w is Map<String, dynamic>)
          ?.map((w) => WidgetItem.fromJson(w as Map<String, dynamic>))
          ?.toList() ?? [],
    );
  }
}

class _AppEditorState extends State<AppEditor> {
  String projectName = '';
  late int userId;
  List<PageData> pages = [];
  int currentPageIndex = 0;
  List<WidgetTemplate> availableTemplates = [];
  String currentTheme = 'light';
  String currentTemplate = 'light';
  String currentNavigate = 'light';
  String currentFontFamily = 'Montserrat';
  String? selectedPanel;
  bool isLoading = true;

  @override
  void initState() {
    userId = widget.userId;
    super.initState();
    _fetchAvailableWidgets();
    _loadProjectData();
  }

  Future<void> _fetchAvailableWidgets() async {
    try {
      final String fileContents = await services.rootBundle.loadString('widgets.json');
      final List<dynamic> data = jsonDecode(fileContents);

      setState(() {
        availableTemplates = data.map((json) => WidgetTemplate.fromJson(json)).toList();
      });
    } catch (e) {
      print("Ошибка при загрузке виджетов: $e");
    }
  }

  Future<void> _loadProjectData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:9096/api/projects/${widget.projectId}/'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        
        setState(() {
          currentTheme = json['colorScheme']?.toString() ?? 'light';
          currentFontFamily = json['fontFamily']?.toString() ?? 'Montserrat';
          currentNavigate = (json['navBarType'] == 1) ? 'Бургер-навигация' : 'Нижнее меню';
          projectName = json['name'] ?? 'Без названия';

          if (json['pages'] != null && json['pages'] is List) {
            pages = (json['pages'] as List).map((pageJson) {
              if (pageJson is Map<String, dynamic>) {
                return PageData.fromJson(pageJson);
              }
              return PageData(id: null, title: 'Новая страница', widgets: []);
            }).toList();
            currentPageIndex = pages.isNotEmpty ? 0 : -1;
          }
          isLoading = false; // Данные загружены
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Ошибка при загрузке проекта: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error parsing JSON: $e');
    }
  }

  // void _addPage() {
  //   setState(() {
  //     pages.add(PageData(
  //       id: UniqueKey().toString(),
  //       name: "Страница ${pages.length + 1}",
  //       widgets: [],
  //     ));
  //     currentPageIndex = pages.length - 1;
  //   });
  // }

  void _changePage(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  void _addWidgetFromTemplate(WidgetTemplate template) {
    final Map<String, dynamic> defaultProperties = {};
    
    // Инициализируем свойства из метаданных
    if (template.metadata['properties'] is Map) {
      template.metadata['properties'].forEach((key, value) {
        if (value is Map && value.containsKey('default')) {
          defaultProperties[key] = value['default'];
        } else if (value is Map) {
          // Для вложенных объектов
          defaultProperties[key] = value;
        }
      });
    }

    setState(() {
      pages[currentPageIndex].widgets.add(WidgetItem(
        id: UniqueKey().toString(),
        categoryId: template.category,
        type: template.widgetName.toLowerCase(),
        metadata: template.metadata,
        properties: defaultProperties,
      ));
    });
  }

  void _removeWidget(int index) {
    setState(() {
      pages[currentPageIndex].widgets.removeAt(index);
    });
  }

  Future<void> _saveWidgets() async {
    try {
      // Prepare pages data according to the API schema
      final pagesData = pages.map((page) {
        return {
          "id": int.tryParse(page.id ?? '0') ?? 0,
          "title": page.title,
          "widgetsList": page.widgets.map((widget) {
            // Prepare widget properties according to the schema
            final properties = widget.propertiesSchema.map((key, schema) {
              return MapEntry(key, {
                "type": schema['type'],
                "default": widget.properties[key],
                "label": schema['label'] ?? key,
              });
            });
            
            return {
              "id": int.tryParse(widget.id) ?? 0,
              "category_id": widget.categoryId,
              "metadata": {
                "type": widget.type,
                "properties": properties,
              },
            };
          }).toList(),
        };
      }).toList();

      final response = await http.put(
        Uri.parse('http://localhost:9096/api/projects/${widget.projectId}/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": projectName, 
          "theme": currentTheme,
          "fontFamily": currentFontFamily,
          "navBarType": currentNavigate == 'Нижнее меню' ? 0 : 1,
          "pages": pagesData,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Данные сохранены!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка: ${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка соединения: $e")),
      );
    }
  }

  Widget buildNavigationWrapper(Widget content) {
    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final theme = availableThemes[currentTheme] ?? availableThemes['light']!;
    
    return Theme(
      data: ThemeData(
        brightness: currentTheme == 'dark' ? Brightness.dark : Brightness.light,
        primaryColor: theme.accentColor,
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: currentTheme == 'dark' ? Brightness.dark : Brightness.light,
          backgroundColor: theme.backgroundColor,
          cardColor: theme.backgroundColor,
        ),
        scaffoldBackgroundColor: theme.backgroundColor,
        textTheme: TextTheme(
          bodyLarge: TextStyle(color: theme.textColor),
          bodyMedium: TextStyle(color: theme.textColor),
        ),
        iconTheme: IconThemeData(color: theme.textColor),
      ),
      child: Builder(
        builder: (context) {
          switch (currentNavigate) {
            case 'Нижнее меню':
              return Scaffold(
                body: content,
                bottomNavigationBar: BottomNavBar(
                  currentPageIndex, 
                  context, 
                  isPreview: true, 
                  themeScheme: theme,
                  onItemSelected: (index) {
                    _changePage(index); 
                  },
                ),
              );
                        
            case 'Бургер-навигация':
              return Scaffold(
                appBar: AppBar(title: Text('Превью')),
                drawer: DrawerNavBar(
                  currentPageIndex, 
                  context, 
                  isPreview: true,
                  onItemSelected: (index) {
                    _changePage(index);
                  },
                  themeScheme: theme,
                ),
                body: content,
              );
              
            default:
              return content;
          }
        },
      ),
    );
  }

  Widget buildPreviewWidget(WidgetItem widgetItem, int index) {
    final theme = availableThemes[currentTheme] ?? availableThemes['light']!;
    
    return Theme(
    data: ThemeData(
      brightness: currentTheme == 'dark' ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: theme.backgroundColor,
      primaryColor: theme.primaryColor,
      cardColor: theme.surfaceColor,
      canvasColor: theme.backgroundColor,
      // errorColor: theme.errorColor,
      iconTheme: IconThemeData(color: theme.iconColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.buttonColor,
          foregroundColor: theme.textColor,
        ),
      ),
      textTheme: GoogleFonts.getTextTheme(
        currentFontFamily,
        Theme.of(context).textTheme.apply(
          bodyColor: theme.textColor,
          displayColor: theme.textColor,
        ),
      ),
      colorScheme: ColorScheme(
        brightness: currentTheme == 'dark' ? Brightness.dark : Brightness.light,
        primary: theme.primaryColor,
        onPrimary: theme.textColor,
        secondary: theme.secondaryColor,
        onSecondary: theme.textColor,
        background: theme.backgroundColor,
        onBackground: theme.textColor,
        surface: theme.surfaceColor,
        onSurface: theme.textColor,
        error: theme.errorColor,
        onError: Colors.white,
      ),
    ),
      child: Builder(
        builder: (context) {
          Widget preview;
          
          switch (widgetItem.type) {
            case 'text':
              final fontSize = (widgetItem.properties['fontSize'] ?? 16).toDouble();
              final fontFamily = widgetItem.properties['fontFamily'] ?? currentFontFamily;

              preview = Text(
                widgetItem.properties['text'] ?? 'Текст',
                style: GoogleFonts.getFont(
                  fontFamily,
                  textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: fontSize,
                  ),
                ),
              );
              break;
            case 'card':
              final double elevation = (widgetItem.properties['elevation'] ?? 4).toDouble();
              final double padding = (widgetItem.properties['padding'] ?? 8).toDouble();
              final String text = widgetItem.properties['text'] ?? 'Контент карточки';

              preview = Card(
                elevation: elevation,
                color: widgetItem.properties['backgroundColor'] != null 
                    ? Color(int.parse(widgetItem.properties['backgroundColor'].replaceFirst('#', '0xff')))
                    : Theme.of(context).cardColor,
                child: Padding(
                  padding: EdgeInsets.all(padding),
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              );
              break;
            case 'club_card':
              preview = ClubCardWidget(
                title: widgetItem.properties['title'] ?? 'Моя клубная карта',
                subtitle: widgetItem.properties['subtitle'] ?? '0001',
                backgroundColor: widgetItem.properties['backgroundColor'] != null 
                  ? Color(int.parse(widgetItem.properties['backgroundColor'].replaceFirst('#', '0xff')))
                  : null, 
                titleFontSize: widgetItem.properties['titleFontSize'] ?? 12,
                subtitleFontSize: widgetItem.properties['subtitleFontSize'] ?? 12,
              );
              break;
            case 'button':
              final String text = widgetItem.properties['text'] ?? 'Нажми меня';
              final String bgColorHex = widgetItem.properties['backgroundColor'] ?? '#2196F3';
              final String textColorHex = widgetItem.properties['textColor'] ?? '#FFFFFF';

              preview = ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(int.parse(bgColorHex.replaceFirst('#', '0xff'))),
                ),
                onPressed: () {},
                child: Text(
                  text,
                  style: TextStyle(color: Color(int.parse(textColorHex.replaceFirst('#', '0xff')))),
                ),
              );
              break;
                case 'nearest_record':
                preview = NearestRecordWidget(
                  title: widgetItem.properties['title'] ?? 'Ближайшая запись',
                  description: widgetItem.properties['description'] ?? 'Описание',
                  date: widgetItem.properties['date'] ?? 'Сегодня',
                  time: widgetItem.properties['time'] ?? '18:00',
                  trainerName: widgetItem.properties['trainerName'] ?? 'Иванов Иван',
                  trainerSpecialty: widgetItem.properties['trainerSpecialty'] ?? 'Инструктор',
                  trainerImageUrl: widgetItem.properties['trainerImageUrl'] ?? '',
                  titleFontSize: (widgetItem.properties['titleFontSize'] ?? 16).toDouble(),
                  descriptionFontSize: (widgetItem.properties['descriptionFontSize'] ?? 14).toDouble(),
                );
                break;
            case 'record_button':
              preview = RecordWidget(
                title: widgetItem.properties['title'] ?? 'Записаться',
                subtitle: widgetItem.properties['subtitle'] ?? 'Подай заявку на персональный тренинг',
                bgColorHex: widgetItem.properties['backgroundColor'],
                titleFontSize: (widgetItem.properties['titleFontSize'] ?? 16).toDouble(),
                subtitleFontSize: (widgetItem.properties['subtitleFontSize'] ?? 14).toDouble(),
              );
              break;
            case 'club_info':
              preview = ClubInfoWidget(
                title: widgetItem.properties['title'] ?? 'Клуб',
                clubNames: [
                  widgetItem.properties['club1'] ?? 'Клуб 1',
                  widgetItem.properties['club2'] ?? 'Клуб 2',
                  widgetItem.properties['club3'] ?? 'Клуб 3',
                ],
                address: widgetItem.properties['address'] ?? 'ул. Примерная, 1',
                phone: widgetItem.properties['phone'] ?? '+7 (123) 456-78-90',
                titleFontSize: (widgetItem.properties['titleFontSize'] ?? 16).toDouble(),
                clubInfoTitleFontSize: (widgetItem.properties['clubInfoTitleFontSize'] ?? 14).toDouble(),
                clubInfoTextFontSize: (widgetItem.properties['clubInfoTextFontSize'] ?? 12).toDouble(),
              );
              break;
            case 'custom_button':
              preview = CustomButtonWidget(
                title: widgetItem.properties['title'] ?? 'Кнопка',
                subtitle: widgetItem.properties['subtitle'] ?? 'Описание',
                titleFontSize: (widgetItem.properties['titleFontSize'] ?? 16).toDouble(),
                subtitleFontSize: (widgetItem.properties['subtitleFontSize'] ?? 14).toDouble(),
              );
              break;
            case 'double_button':
              preview = DoubleButtonWidget(
                title1: widgetItem.properties['title1'] ?? 'Кнопка 1',
                subtitle1: widgetItem.properties['subtitle1'] ?? 'Описание 1',
                title2: widgetItem.properties['title2'] ?? 'Кнопка 2',
                subtitle2: widgetItem.properties['subtitle2'] ?? 'Описание 2',
                title1FontSize: (widgetItem.properties['title1FontSize'] ?? 16).toDouble(),
                subtitle1FontSize: (widgetItem.properties['subtitle1FontSize'] ?? 14).toDouble(),
                title2FontSize: (widgetItem.properties['title2FontSize'] ?? 16).toDouble(),
                subtitle2FontSize: (widgetItem.properties['subtitle2FontSize'] ?? 14).toDouble(),
              );
              break;
            default:
              preview = Text(
                "Предпросмотр: ${widgetItem.type}",
                style: Theme.of(context).textTheme.bodyMedium,
              );
          }

          return GestureDetector(
            onTap: () {
              showDialog(
                barrierColor: Colors.transparent,
                context: context,
                builder: (context) => Dialog(
                  insetPadding: EdgeInsets.only(left: MediaQuery.of(context).size.width * 9 / 16),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: WidgetEditor(
                    widget: widgetItem,
                    onSave: (updatedProperties) {
                      setState(() {
                        widgetItem.properties = updatedProperties;
                      });
                    },
                  ),
                ),
              );
            },
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Dismissible(
                key: ValueKey(widgetItem.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) => _removeWidget(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: preview,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _onSelectPanel(String panel) {
    setState(() {
      selectedPanel = panel;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = availableThemes[currentTheme] ?? availableThemes['light']!;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        iconTheme: IconThemeData(color: Colors.black),
        title: Image.asset(
          'assets/logo.png',
          height: 40,),
        actions: [
          // DropdownButton<int>(
          //   value: currentPageIndex,
          //   dropdownColor: Colors.white,
          //   onChanged: (val) => _changePage(val!),
          //   items: List.generate(pages.length, (index) {
          //     return DropdownMenuItem(
          //       value: index,
          //       child: Text(pages[index].name),
          //     );
          //   }),
          // ),
          // IconButton(
          //   icon: Icon(Icons.add),
          //   onPressed: _addPage,
          // ),
          IconButton(
            onPressed: _saveWidgets,
            icon: Icon(Icons.save, color: const Color.fromRGBO(222,188,255, 1),),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;

          final showRightPanel = screenWidth >= 1200;
          final showLeftMenu = screenWidth >= 800;

          return Container(
            color: const Color.fromARGB(255, 233, 233, 233),
            child: Row(
              children: [
                if (showLeftMenu)
                  Container(
                    width: 200,
                    color: const Color.fromARGB(255, 247, 249, 254),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.of(context).pushNamed(
                              '/projects',
                              arguments: widget.userId,
                            );
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
                          onTap: () {
                          
                          },
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
                          onTap: () {
                            
                          },
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

                Expanded(
                  flex: 2,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 350, 
                        minWidth: 350,
                        maxHeight: 600,
                        minHeight: 600,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.backgroundColor,
                          border: Border.all(color: Colors.grey, width: 2),
                          borderRadius: BorderRadius.circular(0),
                        ),
                        child: Scaffold(
                          backgroundColor: theme.backgroundColor,
                          drawer: currentNavigate == 'Бургер-навигация'
                            ? Builder(
                                builder: (context) => GestureDetector(
                                  onTap: () {}, // 
                                  child: Drawer(
                                    width: MediaQuery.of(context).size.width * 0.7, // 
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(12),
                                          bottomRight: Radius.circular(12),
                                        ),
                                      ),
                                      child: DrawerNavBar(
                                        currentPageIndex,
                                        context,
                                        isPreview: true,
                                        onItemSelected: (index) {
                                          _changePage(index);
                                          setState(() {
                                            currentPageIndex = index;
                                            currentNavigate = 'Бургер-навигация';
                                          });
                                          Navigator.of(context).pop();
                                        },
                                        themeScheme: theme,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : null,
                          bottomNavigationBar: currentNavigate == 'Нижнее меню'
                            ? Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    bottomLeft: Radius.circular(12),
                                    bottomRight: Radius.circular(12),
                                  ),
                                  child: BottomNavBar(
                                    currentPageIndex,
                                    context, 
                                    isPreview: true, 
                                    themeScheme: theme,
                                    onItemSelected: (index) {
                                      _changePage(index);
                                    },
                                  ),
                                ),
                              )
                            : null,
                          body: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Builder(
                              builder: (context) => Column(
                                children: [
                                  if (currentNavigate == 'Бургер-навигация')
                                    Align(
                                      alignment: Alignment.topLeft,
                                      child: GestureDetector(
                                        onTap: () => Scaffold.of(context).openDrawer(),
                                        behavior: HitTestBehavior.opaque,
                                        child: Container(
                                          padding: EdgeInsets.all(16),
                                          child: Icon(Icons.menu),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: pages.isNotEmpty
                                          ? pages[currentPageIndex].widgets.length
                                          : 0,
                                      itemBuilder: (context, index) {
                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: buildPreviewWidget(
                                            pages[currentPageIndex].widgets[index], index),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (showRightPanel)
                  Expanded(
                    flex: 2,
                    child: Container(
                      width: 520,
                      color: const Color.fromARGB(255, 247, 249, 254),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("НАСТРОЙКИ", style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 24),
                          if (selectedPanel == null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildFeatureCard("СТИЛИСТИКА", "Шрифты, цвета и другие элементы дизайна", Icons.design_services, () => _onSelectPanel("styling")),
                                _buildFeatureCard("СТРУКТУРА", "Иерархия экранов, разделов и подразделов", Icons.account_tree, () => _onSelectPanel("structure")),
                                _buildFeatureCard("МАКЕТЫ", "Готовые шаблоны и стили", Icons.star, () => _onSelectPanel("templates")),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () {
                                    setState(() {
                                      if (selectedPanel == 'styling' && stylingSubpanel != null) {
                                        stylingSubpanel = null;
                                      } else {
                                        selectedPanel = null;
                                      }
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Редактирование: ${_getPanelTitle(selectedPanel!)}",
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Expanded(child: _buildPanelContent()),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      )
    );    
  }

Widget _buildFeatureCard(String title, String subtitle, IconData icon, VoidCallback onTap) {
  return Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 36, color: Colors.grey),
              SizedBox(height: 12),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    ),
  );
}

String? stylingSubpanel;
Widget _buildPanelContent() {
  final state = context.watch<ProjectBloc>().state;

  if (state is WidgetSelectedForEdit && selectedPanel == 'edit') {
    return WidgetEditor(
      widget: state.selectedWidget,
      onSave: (updatedProperties) {
        setState(() {
          state.selectedWidget.properties = updatedProperties;
          selectedPanel = null;
          stylingSubpanel = null;
          context.read<ProjectBloc>().add(LogoutEvent());
        });
      },
    );
  }
  switch (selectedPanel) {
    case "styling":
      if (stylingSubpanel == null) {
        // меню стилизации
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Стилизация", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 12),
            ListTile(
              title: Text("Цветовая палитра"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => setState(() => stylingSubpanel = 'theme'),
            ),
            ListTile(
              title: Text("Шрифты"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => setState(() => stylingSubpanel = 'fonts'),
            ),
            ListTile(
              title: Text("Стиль кнопок"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () => setState(() => stylingSubpanel = 'buttons'),
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildStylingSubpanelContent(stylingSubpanel!),
              ),
            ],
          );
      }
    case "structure":
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("", style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: availableTemplates.length,
              itemBuilder: (context, index) {
                final template = availableTemplates[index];
                return ListTile(
                  title: Text(template.widgetName),
                  onTap: () => _addWidgetFromTemplate(template),
                );
              },
            ),
          ),
        ],
      );
    case "templates":
      return Center(child: Text("Выбор шаблонов"));
    
    default:
      return Center(child: Text("Выберите раздел для редактирования"));
  }
}

Widget _buildStylingSubpanelContent(String panel) {
  final state = context.watch<ProjectBloc>().state;
  if (state is WidgetSelectedForEdit) {
    final widgetItem = state.selectedWidget;
    final TextEditingController textController = TextEditingController(
      text: widgetItem.properties['text'] ?? ''
    );

    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  "Редактирование виджета: ${widgetItem.type}", 
                  style: TextStyle(fontWeight: FontWeight.bold)
                ),
                SizedBox(height: 10),
                TextField(
                  controller: textController,
                  decoration: InputDecoration(labelText: 'Текст'),
                  onChanged: (value) {
                    widgetItem.properties['text'] = value;
                  },
                ),
                SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      selectedPanel = null;
                      stylingSubpanel = null; 
                    });
                  },
                  child: Text("Сохранить"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  switch (panel) {
    case 'theme':
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Цветовая палитра", style: Theme.of(context).textTheme.titleMedium),
          SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: availableThemes.entries.map((entry) {
              final themeKey = entry.key;
              final scheme = entry.value;
              final isSelected = currentTheme == themeKey;

              final colors = [
                scheme.backgroundColor,
                scheme.textColor,
                scheme.accentColor,
                scheme.primaryColor,
                scheme.secondaryColor,
                scheme.surfaceColor,
              ];

              return GestureDetector(
                onTap: () => setState(() => currentTheme = themeKey),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    color: Colors.white,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _getThemeDisplayName(themeKey),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle, color: Colors.deepPurple),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        height: 28,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.hardEdge, 
                        child: Row(
                          children: List.generate(colors.length, (index) {
                            final color = colors[index];
                            return Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.horizontal(
                                    left: index == 0 ? Radius.circular(16) : Radius.zero,
                                    right: index == colors.length - 1 ? Radius.circular(16) : Radius.zero,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

    case 'fonts':
      final List<String> fonts = [
        'Roboto',
        'IBM Plex Mono',
        'Inter',
        'Montserrat',
        'Unbounded',
      ];

      final demoText =
          'Это текст, который необходим для демонстрации. В этом тексте можно обсудить различные темы, например, искусство, науку или технологии.';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("ШРИФТЫ", style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: fonts.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final fontName = fonts[index];
                  final isSelected = currentFontFamily == fontName;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        currentFontFamily = fontName;

                        for (var widget in pages[currentPageIndex].widgets) {
                          if (widget.type == 'text') {
                            widget.properties['fontFamily'] = fontName;
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Colors.deepPurple : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                fontName,
                                style: GoogleFonts.getFont(
                                  fontName,
                                  textStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Icon(Icons.check, color: Colors.deepPurple),
                                ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            demoText,
                            style: GoogleFonts.getFont(
                              fontName,
                              textStyle: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedPanel = null;
                        stylingSubpanel = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color.fromRGBO(41, 130, 103, 1)),
                    child: Text("Сохранить",style: TextStyle(color: Colors.white),),
                    
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        currentFontFamily = 'Montserrat';

                        for (var widget in pages[currentPageIndex].widgets) {
                          if (widget.type == 'text') {
                            widget.properties['fontFamily'] = 'Montserrat';
                          }
                        }
                      });
                    },
                    child: Text("Отменить"),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'palette':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Цветовая палитра", style: Theme.of(context).textTheme.titleMedium),
            ListTile(
              title: Text("Основной цвет"),
              trailing: CircleAvatar(backgroundColor: Colors.blue),
              onTap: () {},
            ),
          ],
        );

      case 'buttons':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Стиль кнопок", style: Theme.of(context).textTheme.titleMedium),
            ListTile(title: Text("Закруглённые")),
            ListTile(title: Text("С обводкой")),
            ListTile(title: Text("Плоские")),
          ],
        );
    
      default:
        return Center(child: Text("Нет содержимого"));
    }
  }

  String _getPanelTitle(String panel) {
    switch (panel) {
      case "styling":
        return "Стили";
      case "structure":
        return "Структура";
      case "templates":
        return "Макеты";
      default:
        return "Редактор";
    }
  }

  String _getThemeDisplayName(String key) {
    switch (key) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'green':
        return 'Green';
      case 'blue':
        return 'Blue';
      case 'dellGenoa':
        return 'Dell Genoa';
      default:
        return key;
    }
  }
}