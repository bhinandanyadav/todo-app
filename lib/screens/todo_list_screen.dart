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

class _TodoListScreenState extends State<TodoListScreen>
    with TickerProviderStateMixin {
  final TodoService _todoService = TodoService();
  List<Todo> _todos = [];
  List<Todo> _filteredTodos = [];
  TodoFilter _currentFilter = TodoFilter.all;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _loadTodos();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
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

      // Start animations after data is loaded
      _fadeController.forward();
      _slideController.forward();
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
    final updatedTodo = todo.copyWith(title: title, description: description);

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[600]),
            const SizedBox(width: 8),
            const Text('Delete Todo'),
          ],
        ),
        content: Text('Are you sure you want to delete "${todo.title}"?'),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.clear_all, color: Colors.blue[600]),
            const SizedBox(width: 8),
            const Text('Clear Completed'),
          ],
        ),
        content: const Text(
          'Are you sure you want to clear all completed todos?',
        ),
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
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              if (!_isLoading) _buildStatsBar(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.task_alt, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Tasks',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Stay organized and productive',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          _buildFilterButton(),
          const SizedBox(width: 8),
          _buildClearButton(),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<TodoFilter>(
        onSelected: (filter) {
          setState(() {
            _currentFilter = filter;
            _applyFilter();
          });
        },
        itemBuilder: (context) => [
          _buildFilterMenuItem(TodoFilter.all, 'All', Icons.list),
          _buildFilterMenuItem(TodoFilter.pending, 'Pending', Icons.pending),
          _buildFilterMenuItem(
            TodoFilter.completed,
            'Completed',
            Icons.check_circle,
          ),
        ],
        icon: const Icon(Icons.filter_list),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  PopupMenuItem<TodoFilter> _buildFilterMenuItem(
    TodoFilter filter,
    String label,
    IconData icon,
  ) {
    return PopupMenuItem(
      value: filter,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: _currentFilter == filter
                ? Theme.of(context).colorScheme.primary
                : Colors.grey[600],
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: _currentFilter == filter
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[600],
              fontWeight: _currentFilter == filter
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _clearCompletedTodos,
        icon: const Icon(Icons.clear_all),
        tooltip: 'Clear Completed',
      ),
    );
  }

  Widget _buildStatsBar() {
    final totalTodos = _todos.length;
    final completedTodos = _todos.where((todo) => todo.isCompleted).length;
    final pendingTodos = totalTodos - completedTodos;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', totalTodos, Colors.blue[600]!),
              _buildStatItem('Pending', pendingTodos, Colors.orange[600]!),
              _buildStatItem('Completed', completedTodos, Colors.green[600]!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            count.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_filteredTodos.isEmpty) {
      return _buildEmptyState();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: RefreshIndicator(
          onRefresh: _loadTodos,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
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
    );
  }

  Widget _buildEmptyState() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Icon(_getEmptyIcon(), size: 64, color: Colors.grey[400]),
              ),
              const SizedBox(height: 24),
              Text(
                _getEmptyTitle(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getEmptyMessage(),
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _showAddTodoDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Your First Todo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: _showAddTodoDialog,
        tooltip: 'Add Todo',
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  IconData _getEmptyIcon() {
    switch (_currentFilter) {
      case TodoFilter.all:
        return Icons.task_alt;
      case TodoFilter.pending:
        return Icons.check_circle;
      case TodoFilter.completed:
        return Icons.pending;
    }
  }

  String _getEmptyTitle() {
    switch (_currentFilter) {
      case TodoFilter.all:
        return 'No Tasks Yet';
      case TodoFilter.pending:
        return 'All Caught Up!';
      case TodoFilter.completed:
        return 'No Completed Tasks';
    }
  }

  String _getEmptyMessage() {
    switch (_currentFilter) {
      case TodoFilter.all:
        return 'Start by adding your first task to stay organized and productive.';
      case TodoFilter.pending:
        return 'Great job! You\'ve completed all your tasks.';
      case TodoFilter.completed:
        return 'Complete some tasks to see them here.';
    }
  }
}

enum TodoFilter { all, pending, completed }
