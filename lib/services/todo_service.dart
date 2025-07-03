import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';

class TodoService {
  static const String _todosKey = 'todos';

  // Get all todos from local storage
  Future<List<Todo>> getAllTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = prefs.getString(_todosKey);
      
      if (todosJson == null) return [];
      
      final List<dynamic> todosList = json.decode(todosJson);
      return todosList.map((json) => Todo.fromMap(json)).toList();
    } catch (e) {
      print('Error loading todos: $e');
      return [];
    }
  }

  // Save todos to local storage
  Future<void> saveTodos(List<Todo> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final todosJson = json.encode(todos.map((todo) => todo.toMap()).toList());
      await prefs.setString(_todosKey, todosJson);
    } catch (e) {
      print('Error saving todos: $e');
    }
  }

  // Add a new todo
  Future<void> addTodo(Todo todo) async {
    final todos = await getAllTodos();
    todos.add(todo);
    await saveTodos(todos);
  }

  // Update an existing todo
  Future<void> updateTodo(Todo updatedTodo) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == updatedTodo.id);
    
    if (index != -1) {
      todos[index] = updatedTodo;
      await saveTodos(todos);
    }
  }

  // Delete a todo
  Future<void> deleteTodo(String id) async {
    final todos = await getAllTodos();
    todos.removeWhere((todo) => todo.id == id);
    await saveTodos(todos);
  }

  // Toggle todo completion
  Future<void> toggleTodoCompletion(String id) async {
    final todos = await getAllTodos();
    final index = todos.indexWhere((todo) => todo.id == id);
    
    if (index != -1) {
      todos[index].toggleCompletion();
      await saveTodos(todos);
    }
  }

  // Get completed todos
  Future<List<Todo>> getCompletedTodos() async {
    final todos = await getAllTodos();
    return todos.where((todo) => todo.isCompleted).toList();
  }

  // Get pending todos
  Future<List<Todo>> getPendingTodos() async {
    final todos = await getAllTodos();
    return todos.where((todo) => !todo.isCompleted).toList();
  }

  // Clear all completed todos
  Future<void> clearCompletedTodos() async {
    final todos = await getAllTodos();
    final pendingTodos = todos.where((todo) => !todo.isCompleted).toList();
    await saveTodos(pendingTodos);
  }
}
