Map<String, dynamic> getDefaultPagesByTemplate(String template) {
  switch (template) {
    case 'fitnes':
      return {
        "pages": [
          {
            "name": "Главная",
            "widgets": [
              {
                "name": "Card",
                "type": "card",
                "code": "",
                "file_url": "",
                "config": {
                  "elevation": 4,
                  "padding": 8,
                  "text": "Контент карточки"
                }
              }
            ]
          },
        ]
      };
    default:
      return {
        "pages": []
      };
  }
}