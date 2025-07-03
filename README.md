# Flutter Todo List App

A comprehensive todo list application built with Flutter and Dart that helps you manage your tasks efficiently.

## Features

✅ **Add Todos**: Create new todos with title and optional description  
✅ **Edit Todos**: Modify existing todos  
✅ **Mark Complete**: Toggle todo completion status  
✅ **Delete Todos**: Remove todos you no longer need  
✅ **Filter Todos**: View all, pending, or completed todos  
✅ **Statistics**: See total, pending, and completed todo counts  
✅ **Persistence**: Todos are saved locally using SharedPreferences  
✅ **Pull to Refresh**: Refresh the todo list  
✅ **Clear Completed**: Remove all completed todos at once  

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── models/
│   └── todo.dart                      # Todo data model
├── services/
│   └── todo_service.dart              # Todo business logic
├── screens/
│   └── todo_list_screen.dart          # Main todo list screen
└── widgets/
    ├── todo_item.dart                 # Individual todo item widget
    └── add_edit_todo_dialog.dart      # Add/edit todo dialog
```

## Dependencies

- `flutter`: Flutter SDK
- `shared_preferences`: Local data persistence
- `cupertino_icons`: iOS-style icons

## Getting Started

### Prerequisites
- Flutter SDK (3.8.1 or higher)
- Dart SDK
- Android Studio or VS Code with Flutter extension

### Installation

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd my_flutter_app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

### Building for Different Platforms

**Android:**
```bash
flutter build apk
```

**iOS:**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

**Linux:**
```bash
flutter build linux
```

**Windows:**
```bash
flutter build windows
```

**macOS:**
```bash
flutter build macos
```

## How to Use

1. **Add a Todo**: Tap the floating action button (+) and fill in the title and optional description
2. **Mark Complete**: Tap the checkbox next to any todo to mark it as complete
3. **Edit Todo**: Tap the edit icon to modify a todo
4. **Delete Todo**: Tap the delete icon to remove a todo
5. **Filter Todos**: Use the filter menu in the app bar to view all, pending, or completed todos
6. **Clear Completed**: Use the clear all icon to remove all completed todos
7. **Refresh**: Pull down on the list to refresh

## Testing

Run the tests:
```bash
flutter test
```

## Architecture

This app follows a clean architecture pattern:

- **Models**: Define the data structure (Todo)
- **Services**: Handle business logic and data persistence (TodoService)
- **Widgets**: Reusable UI components (TodoItem, AddEditTodoDialog)
- **Screens**: Main app screens (TodoListScreen)

The app uses:
- **StatefulWidget** for state management
- **SharedPreferences** for local data persistence
- **Material Design** for UI components
- **Form validation** for user input

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request
