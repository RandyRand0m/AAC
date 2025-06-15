Map<String, dynamic> getDefaultPagesByTemplate(String template) {
  switch (template) {
    case 'Фитнес-Клуб':
      return {
        "pages": [
          {
            "title": "Главная",
            "page_id": 0,
            "required_categories": [0, 2, 3, 4, 5, 6],
            "widgetsList": [
              {
                "category_id": 0,
                "metadata": {
                  "type": "club_card",
                  "properties": {
                    "title": {
                    "type": "string",
                    "default": "Моя клубная карта",
                    "label": "Заголовок"
                  },
                  "subtitle": {
                    "type": "string",
                    "default": "0001",
                    "label": "Подзаголовок"
                  },
                  "titleFontSize": {
                    "type": "number",
                    "default": 16,
                    "label": "Размер шрифта заголовка"
                  },
                  "subtitleFontSize": {
                    "type": "number",
                    "default": 14,
                    "label": "Размер шрифта подзаголовка"
                  },
                    
                  }
                }
              },
              
              {
                "category_id": 2,
                "metadata": {
                  "type": "record_button",
                  "properties": {
                    "title": {
                    "type": "string",
                    "default": "Записаться",
                    "label": "Заголовок"
                  },
                  "titleFontSize": {
                    "type": "number",
                    "default": 16,
                    "label": "Размер шрифта заголовка"
                  },
                  "subtitle": {
                    "type": "string",
                    "default": "Подай заявку на персональный тренинг",
                    "label": "Подзаголовок"
                  },
                  "subtitleFontSize": {
                    "type": "number",
                    "default": 12,
                    "label": "Размер шрифта подзаголовка"
                  },
                  }
                }
              },
              {
                "category_id": 3,
                "metadata": {
                  "type": "club_info",
                  "properties": {
                    "title": {
                      "type": "string",
                      "default": "Клуб",
                      "label": "Заголовок"
                    },
                    "titleFontSize": {
                      "type": "number",
                      "default": 16,
                      "label": "Размер шрифта заголовка"
                    },
                    "clubInfoTitleFontSize": {
                      "type": "number",
                      "default": 14,
                      "label": "Размер шрифта заголовка информации"
                    },
                    "clubInfoTextFontSize": {
                      "type": "number",
                      "default": 12,
                      "label": "Размер шрифта текста информации"
                    },
                  }
                }
              },
              {
                "category_id": 4,
                "metadata": {
                  "type": "custom_button",
                  "properties": {
                    "title": {
                      "type": "string",
                      "default": "Наши тренеры",
                      "label": "Заголовок"
                    },
                    "titleFontSize": {
                      "type": "number",
                      "default": 16,
                      "label": "Размер шрифта заголовка"
                    },
                    "subtitle": {
                      "type": "string",
                      "default": "Профессионалы своего дела",
                      "label": "Подзаголовок"
                    },
                    "subtitleFontSize": {
                      "type": "number",
                      "default": 14,
                      "label": "Размер шрифта подзаголовка"
                    }                  
                  }
                }
              },
              {
                "category_id": 5,
                "metadata": {
                  "type": "double_button",
                  "properties": {
                    "title1": {
                    "type": "string",
                    "default": "Тренеры",
                    "label": "Заголовок 1"
                  },
                  "title1FontSize": {
                    "type": "number",
                    "default": 16,
                    "label": "Размер шрифта заголовка 1"
                  },
                  "subtitle1": {
                    "type": "string",
                    "default": "Наши специалисты",
                    "label": "Подзаголовок 1"
                  },
                  "subtitle1FontSize": {
                    "type": "number",
                    "default": 14,
                    "label": "Размер шрифта подзаголовка 1"
                  },
                  "title2": {
                    "type": "string",
                    "default": "Абонементы",
                    "label": "Заголовок 2"
                  },
                  "title2FontSize": {
                    "type": "number",
                    "default": 16,
                    "label": "Размер шрифта заголовка 2"
                  },
                  "subtitle2": {
                    "type": "string",
                    "default": "Выберите программу",
                    "label": "Подзаголовок 2"
                  },
                  "subtitle2FontSize": {
                    "type": "number",
                    "default": 14,
                    "label": "Размер шрифта подзаголовка 2"
                  }
                  }
                }
              },
              {
                "category_id": 6,
                "metadata": {
                  "type": "text",
                  "properties": {
                    "text": {
                      "type": "string",
                      "default": "Пример текста",
                      "label": "Текст"
                    },
                    "fontSize": {
                      "type": "number",
                      "default": 16,
                      "label": "Размер шрифта"
                    },
                    "fontFamily": {
                      "type": "string",
                      "default": "Roboto",
                      "label": "Шрифт"
                    }
                  }
                }
              }
            ]
          },
          {
            "title": "Расписание",
            "page_id": 1,
            "required_categories": [1, 2, 6],
            "widgetsList": [
              {
                "category_id": 1,
                "metadata": {
                  "type": "nearest_record",
                  "properties": {
                    "title": {
                    "type": "string",
                    "default": "Ближайшая запись",
                    "label": "Заголовок"
                  },
                  "titleFontSize": {
                    "type": "number",
                    "default": 16,
                    "label": "Размер шрифта заголовка"
                  },
                  "description": {
                    "type": "string",
                    "default": "Описание",
                    "label": "Описание"
                  },
                  "descriptionFontSize": {
                    "type": "number",
                    "default": 14,
                    "label": "Размер шрифта описания"
                  },
                  }
                }
              },
              {
                "category_id": 2,
                "metadata": {
                  "type": "record_button",
                  "properties": {
                    
                  }
                }
              },
              {
                "category_id": 6,
                "metadata": {
                  "type": "text",
                  "properties": {
                    
                  }
                }
              }
            ]
          },
          {
            "title": "Тренажеры",
            "page_id": 2,
            "required_categories": [3, 4, 5],
            "widgetsList": [
              {
                "category_id": 3,
                "metadata": {
                  "type": "club_info",
                  "properties": {
                    
                  }
                }
              },
              {
                "category_id": 4,
                "metadata": {
                  "type": "custom_button",
                  "properties": {
                    
                  }
                }
              },
              {
                "category_id": 5,
                "metadata": {
                  "type": "double_button",
                  "properties": {
                    
                  }
                }
              }
            ]
          },
          {
            "title": "Магазин",
            "page_id": 3,
            "required_categories": [4, 5, 6],
            "widgetsList": [
              {
                "category_id": 4,
                "metadata": {
                  "type": "custom_button",
                  "properties": {
                    
                  }
                }
              },
              {
                "category_id": 5,
                "metadata": {
                  "type": "double_button",
                  "properties": {
                    
                  }
                }
              },
              {
                "category_id": 6,
                "metadata": {
                  "type": "text",
                  "properties": {
                    
                  }
                }
              }
            ]
          },
          {
            "title": "Профиль",
            "page_id": 4,
            "required_categories": [6],
            "widgetsList": [
              {
                "category_id": 6,
                "metadata": {
                  "type": "text",
                  "properties": {
                    
                  }
                }
              }
            ]
          }
        ]
      };
    default:
      return {
        "pages": []
      };
  }
}