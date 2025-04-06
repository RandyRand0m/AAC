import 'package:flutter/material.dart';

class AppEditor extends StatefulWidget {
  const AppEditor({super.key});

  @override
  State<AppEditor> createState() => _AppEditorState();
}

class WidgetItem {
  final String id;
  final String name;

  WidgetItem({required this.id, required this.name});
}

class _AppEditorState extends State<AppEditor> {
  List<WidgetItem> widgets = [];

  void _addWidget() {
    setState(() {
      widgets.add(WidgetItem(id: UniqueKey().toString(), name: 'Текст'));
    });
  }

  void _removeWidget(String id) {
    setState(() {
      widgets.removeWhere((widget) => widget.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Редактор приложения"),
      ),
      body: Row(
        children: [
          
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.grey[200],
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Дерево виджетов", style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: widgets.length,
                      itemBuilder: (context, index) {
                        final widgetItem = widgets[index];
                        return ListTile(
                          title: Text(widgetItem.name),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _removeWidget(widgetItem.id),
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addWidget,
                    icon: Icon(Icons.add),
                    label: Text("Добавить виджет"),
                  )
                ],
              ),
            ),
          ),

         
          Expanded(
            flex: 4,
            child: Container(
              color: Colors.white,
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text("Превью Android-приложения", style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[100],
                      ),
                      padding: EdgeInsets.all(16),
                      child: ListView.builder(
                        itemCount: widgets.length,
                        itemBuilder: (context, index) {
                          final widgetItem = widgets[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              leading: Icon(Icons.widgets),
                              title: Text("Превью: ${widgetItem.name}"),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
