import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class AppEditor extends StatefulWidget {
  final int projectId;
  const AppEditor({super.key, required this.projectId});

  @override
  State<AppEditor> createState() => _AppEditorState();
}
class ThemeScheme {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  const ThemeScheme({
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });
}

const Map<String, ThemeScheme> availableThemes = {
  'light': ThemeScheme(
    backgroundColor: Colors.white,
    textColor: Colors.black,
    accentColor: Colors.blue,
  ),
  'dark': ThemeScheme(
    backgroundColor: Colors.grey,
    textColor: Colors.white,
    accentColor: Colors.deepPurple,
  ),
  'green': ThemeScheme(
    backgroundColor: Color(0xFFE8F5E9),
    textColor: Colors.green,
    accentColor: Colors.teal,
  ),
  'blue': ThemeScheme(
    backgroundColor: Color(0xFFE3F2FD),
    textColor: Colors.blueAccent,
    accentColor: Colors.indigo,
  ),
};

class WidgetTemplate {
  final String widgetName;
  final int category;
  final Map<String, dynamic> metadata;
  final String sampleCode;

  WidgetTemplate({
    required this.widgetName,
    required this.category,
    required this.metadata,
    required this.sampleCode,
  });

  factory WidgetTemplate.fromJson(Map<String, dynamic> json) {
    return WidgetTemplate(
      widgetName: json['widgetName'],
      category: json['category'],
      metadata: json['metadata'],
      sampleCode: json['sampleCode'],
    );
  }
}

class WidgetItem {
  final String id;
  final String name;
  final String type;
  final Map<String, dynamic> properties;
  final String sampleCode;

  WidgetItem({
    required this.id,
    required this.name,
    required this.type,
    required this.properties,
    required this.sampleCode
  });
  
  factory WidgetItem.fromJson(Map<String, dynamic> json) {
    return WidgetItem(
      id: json['id'] ?? UniqueKey().toString(),
      name: json['name'],
      type: json['type'],
      properties: Map<String, dynamic>.from(json['config'] ?? {}),
      sampleCode: json['code'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "name": name,
      "type": type,
      "code": sampleCode,
      "file_url": "",
      "config": properties,
    };
  }
}

class PageData {
  final String? id;
  final String name;
  List<WidgetItem> widgets;

  PageData({
    required this.id,
    required this.name,
    required this.widgets,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'widgets': widgets.map((w) => w.toJson()).toList(),
  };
  factory PageData.fromJson(Map<String, dynamic> json) {
    return PageData(
      id: json['id'],
      name: json['name'],
      widgets: (json['widgets'] as List<dynamic>)
          .map((w) => WidgetItem.fromJson(w))
          .toList(),
    );
  }
}

class _AppEditorState extends State<AppEditor> {
  List<PageData> pages = [];
  int currentPageIndex = 0;
  List<WidgetTemplate> availableTemplates = [];
  String currentTheme = 'light';
  String currentTemplate = 'light';
  String currentNavigate = 'light';
  String currentFontFamily = 'Montserrat';

  @override
  void initState() {
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

  void _loadProjectData() async {
    final response = await http.get(
      Uri.parse('http://localhost:9096/api/projects/${widget.projectId}/'),
    );

    if (response.statusCode == 200) {
      final decoded = utf8.decode(response.bodyBytes);
      final json = jsonDecode(decoded);
      final rules = json['rules'];
      
      setState(() {
        currentTheme = rules['theme'] ?? 'light';
        currentTemplate = rules['template'] ?? 'light';
        currentNavigate = rules['navigation'] ?? 'bottom';

        // Загружаем страницы
        if (rules['pages'] != null) {
          pages = (rules['pages'] as List).map((pageJson) => PageData.fromJson(pageJson)).toList();
          currentPageIndex = pages.isNotEmpty ? 0 : -1;
        }
      });
      print('Загруженные страницы: ${pages.length}');
    } else {
      print('Ошибка при загрузке проекта: ${response.statusCode}');
    }
  }

  void _addPage() {
    setState(() {
      pages.add(PageData(
        id: UniqueKey().toString(),
        name: "Страница ${pages.length + 1}",
        widgets: [],
      ));
      currentPageIndex = pages.length - 1;
    });
  }

  void _changePage(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  void _addWidgetFromTemplate(WidgetTemplate template) {
    final Map<String, dynamic> defaultProperties = {};
    template.metadata['properties']?.forEach((key, value) {
      defaultProperties[key] = value['default'];
    });

    setState(() {
      pages[currentPageIndex].widgets.add(WidgetItem(
        id: UniqueKey().toString(),
        name: template.widgetName,
        type: template.widgetName.toLowerCase(),
        properties: defaultProperties,
        sampleCode: template.sampleCode,
      ));
    });
  }

  void _removeWidget(int index) {
    setState(() {
      pages[currentPageIndex].widgets.removeAt(index);
    });
  }

  Future<void> _saveWidgets() async {
    final pagesData = pages.map((p) => p.toJson()).toList();
    try {
      print(pagesData);
      final response = await http.put(
        Uri.parse('http://localhost:9096/api/projects/${widget.projectId}/'),
        headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "rules": {
              "theme": currentTheme,
              "template": currentTemplate,
              "navigation": currentNavigate,
              "pages": pages.map((page) => {
                "id": page.id,
                "name": page.name,
                "widgets": page.widgets.map((w) => w.toJson()).toList(),
              }).toList(),
            }
          }),
        );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Виджеты обновлены!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Ошибка: \${response.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка соединения")),
      );
    }
  }

  Widget buildPreviewWidget(WidgetItem widgetItem, int index) {
    final theme = availableThemes[currentTheme] ?? availableThemes['light']!;
    Widget preview;
    switch (widgetItem.type) {
      case 'text':
        final fontSize = (widgetItem.properties['fontSize'] ?? 16).toDouble();
        final fontFamily = widgetItem.properties['fontFamily'] ?? currentFontFamily;

        preview = Text(
          widgetItem.properties['text'] ?? 'Текст',
          style: GoogleFonts.getFont(
            fontFamily,
            textStyle: TextStyle(
              fontSize: fontSize,
              color: theme.textColor,
            ),
          ),
        );
        break;
        case 'card':
          final double elevation =
              (widgetItem.properties['elevation'] ?? 4).toDouble();
          final double padding =
              (widgetItem.properties['padding'] ?? 8).toDouble();
          final String text = widgetItem.properties['text'] ?? 'Контент карточки';

          preview = Card(
            elevation: elevation,
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Text(
                text,
                style: TextStyle(color: theme.textColor),
              ),
            ),
          );
          break;

        case 'button':
          final String text = widgetItem.properties['text'] ?? 'Нажми меня';
          final String bgColorHex =
              widgetItem.properties['backgroundColor'] ?? '#2196F3';
          final String textColorHex =
              widgetItem.properties['textColor'] ?? '#FFFFFF';

          Color parseColor(String hex) {
            hex = hex.replaceAll('#', '');
            if (hex.length == 6) hex = 'FF$hex'; 
            return Color(int.parse(hex, radix: 16));
          }

          preview = ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: parseColor(bgColorHex),
            ),
            onPressed: () {},
            child: Text(
              text,
              style: TextStyle(color: parseColor(textColorHex)),
            ),
          );
          break;
      default:
        preview = Text(
          "Предпросмотр: ${widgetItem.name}",
          style: TextStyle(color: theme.textColor),
        );
    }

    return Container(
      color: theme.backgroundColor,
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
    );
  }
  String? selectedPanel;

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
        title: Text("GYMAPP конструктор",style: TextStyle(color: Colors.black),),
        actions: [
          DropdownButton<int>(
            value: currentPageIndex,
            dropdownColor: Colors.white,
            onChanged: (val) => _changePage(val!),
            items: List.generate(pages.length, (index) {
              return DropdownMenuItem(
                value: index,
                child: Text(pages[index].name),
              );
            }),
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _addPage,
          ),
          IconButton(
            onPressed: _saveWidgets,
            icon: Icon(Icons.save, color: Colors.white),
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
                  Container( // Левое меню
                    width: 200,
                    color: const Color.fromARGB(255, 247, 249, 254),
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Все проекты", style: Theme.of(context).textTheme.titleMedium),
                        SizedBox(height: 12),
                        Text("Моё приложение", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                        SizedBox(height: 12),
                        Text("Контент"),
                        SizedBox(height: 12),
                        Text("Публикация"),
                        Spacer(),
                        Divider(),
                        Text("Помощь", style: TextStyle(color: Colors.grey)),
                        SizedBox(height: 8),
                        Text("Настройки", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),

                Expanded( // Центр — превью
                  flex: 2,
                  child: Center(
                    child: Container(
                      width: screenWidth < 900 ? screenWidth * 0.9 : 300,
                      decoration: BoxDecoration(
                        color: theme.backgroundColor,
                        border: Border.all(color: Colors.grey, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: pages.isNotEmpty ? pages[currentPageIndex].widgets.length : 0,
                        itemBuilder: (context, index) {
                          return buildPreviewWidget(pages[currentPageIndex].widgets[index], index);
                        },
                      ),
                    ),
                  ),
                ),

                if (showRightPanel)
                  Expanded( // Правая панель
                    flex: 2,
                    child: Container(
                      width: 520,
                      color: const Color.fromARGB(255, 247, 249, 254),
                      padding: EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("НАСТРОЙКИ", style: Theme.of(context).textTheme.titleMedium),
                          SizedBox(height: 24),
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
                                  icon: Icon(Icons.arrow_back),
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
                                SizedBox(width: 8),
                                Text("Редактирование: ${_getPanelTitle(selectedPanel!)}", style: Theme.of(context).textTheme.titleMedium),
                              ],
                            ),
                            SizedBox(height: 16),
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
      ),
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

              return GestureDetector(
                onTap: () => setState(() => currentTheme = themeKey),
                child: Container(
                  width: 472,
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
                              color: scheme.textColor,
                            ),
                          ),
                          Spacer(),
                          if (isSelected)
                            Icon(Icons.check_circle, color: Colors.deepPurple),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: scheme.backgroundColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Container(
                              height: 22,
                              decoration: BoxDecoration(
                                color: scheme.accentColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
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

                      // Обновим все текстовые виджеты на текущей странице
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
      return 'Светлая';
    case 'dark':
      return 'Тёмная';
    case 'blue':
      return 'Голубая';
    case 'green':
      return 'Голубая';
    default:
      return key;
  }
}
}