import 'package:flutter/material.dart';
import '../models/todo.dart';
import '../services/todo_service.dart';
import '../widgets/todo_item.dart';
import '../widgets/add_edit_todo_dialog.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  final TodoService _todoService = TodoService();
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  TodoFilter _currentFilter = TodoFilter.all;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final todos = await _todoService.getAllTodos();
      setState(() {
        _todos = todos;
        _applyFilter();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Failed to load todos');
    }
  }

  void _applyFilter() {
    switch (_currentFilter) {
      case TodoFilter.all:
        _filteredTodos = _todos;
        break;
      case TodoFilter.pending:
        _filteredTodos = _todos.where((todo) => !todo.isCompleted).toList();
        break;
      case TodoFilter.completed:
        _filteredTodos = _todos.where((todo) => todo.isCompleted).toList();
        break;
    }
  }

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => AddEditTodoDialog(
        onSave: (title, description) => _addTodo(title, description),
      ),
    );
  }

  void _showEditTodoDialog(Todo todo) {
    showDialog(
      context: context,
      builder: (context) => AddEditTodoDialog(
        todo: todo,
        onSave: (title, description) => _updateTodo(todo, title, description),
      ),
    );
  }

  Future<void> _addTodo(String title, String description) async {
    final todo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
    );

    try {
      await _todoService.addTodo(todo);
      await _loadTodos();
      _showSuccessSnackBar('Todo added successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to add todo');
    }
  }

  Future<void> _updateTodo(Todo todo, String title, String description) async {
    final updatedTodo = todo.copyWith(
      title: title,
      description: description,
    );

    try {
      await _todoService.updateTodo(updatedTodo);
      await _loadTodos();
      _showSuccessSnackBar('Todo updated successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to update todo');
    }
  }

  Future<void> _toggleTodoCompletion(Todo todo) async {
    try {
      await _todoService.toggleTodoCompletion(todo.id);
      await _loadTodos();
    } catch (e) {
      _showErrorSnackBar('Failed to update todo');
    }
  }

  Future<void> _deleteTodo(Todo todo) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Todo'),
        content: Text('Are you sure you want to delete \"${todo.title}\"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _todoService.deleteTodo(todo.id);
        await _loadTodos();
        _showSuccessSnackBar('Todo deleted successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to delete todo');
      }
    }
  }

  Future<void> _clearCompletedTodos() async {
    if (_todos.where((todo) => todo.isCompleted).isEmpty) {
      _showErrorSnackBar('No completed todos to clear');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Completed Todos'),
        content: const Text('Are you sure you want to clear all completed todos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await _todoService.clearCompletedTodos();
        await _loadTodos();
        _showSuccessSnackBar('Completed todos cleared');
      } catch (e) {
        _showErrorSnackBar('Failed to clear completed todos');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo List'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          PopupMenuButton<TodoFilter>(
            onSelected: (filter) {
              setState(() {
                _currentFilter = filter;
                _applyFilter();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: TodoFilter.all,
                child: Text('All'),
              ),
              const PopupMenuItem(
                value: TodoFilter.pending,
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: TodoFilter.completed,
                child: Text('Completed'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: _clearCompletedTodos,
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear Completed',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredTodos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.task_alt,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _getEmptyMessage(),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildStatsBar(),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadTodos,
                        child: ListView.builder(
                          itemCount: _filteredTodos.length,
                          itemBuilder: (context, index) {
                            final todo = _filteredTodos[index];
                            return TodoItem(
                              todo: todo,
                              onToggle: () => _toggleTodoCompletion(todo),
                              onEdit: () => _showEditTodoDialog(todo),
                              onDelete: () => _deleteTodo(todo),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        tooltip: 'Add Todo',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalTodos = _todos.length;
    final completedTodos = _todos.where((todo) => todo.isCompleted).length;
    final pendingTodos = totalTodos - completedTodos;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total', totalTodos, Colors.blue),
          _buildStatItem('Pending', pendingTodos, Colors.orange),
          _buildStatItem('Completed', completedTodos, Colors.green),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case TodoFilter.all:
        return 'No todos yet. Add one to get started!';
      case TodoFilter.pending:
        return 'No pending todos. Great job!';
      case TodoFilter.completed:
        return 'No completed todos yet.';
    }
  }
}

enum TodoFilter { all, pending, completed }
