import 'package:flutter/material.dart';
import 'dart:async';
import '../models/task.dart';
import '../services/task_api_service.dart';
import 'task_form_screen.dart';
import '../widgets/task_card.dart';
import '../widgets/loading_widget.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  bool isLoading = false;
  String searchQuery = '';
  String selectedStatus = 'ALL';
  String? errorMessage;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => isLoading = true);
    try {
      final loadedTasks = await TaskApiService.getTasks(
        search: searchQuery.isNotEmpty ? searchQuery : null,
        status: selectedStatus != 'ALL' ? selectedStatus : null,
      );
      setState(() {
        tasks = loadedTasks;
        filteredTasks = loadedTasks;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load tasks: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
    });
    
    // Cancel previous debounce timer
    _debounceTimer?.cancel();
    
    // Debounce the search - wait 300ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _loadTasks();
    });
  }

  void _onStatusFilterChanged(String? status) {
    setState(() {
      selectedStatus = status ?? 'ALL';
    });
    _loadTasks();
  }

  void _navigateToFormScreen([Task? task]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    );
    
    if (result == true) {
      _loadTasks();
    }
  }

  Future<void> _deleteTask(Task task) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await TaskApiService.deleteTask(task.id);
                _loadTasks();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Task deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting task: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTaskOrder() async {
    try {
      final taskIds = filteredTasks.map((task) => task.id).toList();
      await TaskApiService.reorderTasks(taskIds);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task order: $e')),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(Task task, String newStatus) async {
    try {
      final updatedTask = task.copyWith(status: newStatus);
      final result = await TaskApiService.updateTask(task.id, updatedTask);
      
      // Update the list with the new task
      final index = filteredTasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        setState(() {
          filteredTasks[index] = result;
          tasks[tasks.indexWhere((t) => t.id == task.id)] = result;
        });
      }
      
      // Reload to get any newly generated recurring tasks
      if (task.isRecurring && newStatus == 'DONE') {
        await Future.delayed(const Duration(milliseconds: 500));
        _loadTasks();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 'DONE' && task.isRecurring
                  ? 'Task completed! Next recurring task generated.'
                  : 'Task status updated',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating task: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flodo Tasks'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Status Filter Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedStatus,
                  items: const [
                    DropdownMenuItem(value: 'ALL', child: Text('All Status')),
                    DropdownMenuItem(value: 'TO_DO', child: Text('To-Do')),
                    DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                    DropdownMenuItem(value: 'DONE', child: Text('Done')),
                  ],
                  onChanged: _onStatusFilterChanged,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Tasks List
          Expanded(
            child: errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadTasks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : isLoading
                    ? const LoadingWidget()
                    : filteredTasks.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.inbox_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tasks found',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ],
                            ),
                          )
                        : ReorderableListView(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final Task item = filteredTasks.removeAt(oldIndex);
                                filteredTasks.insert(newIndex, item);
                              });
                              
                              // Save the new order to backend
                              _saveTaskOrder();
                            },
                            children: filteredTasks.map((task) {
                              return Padding(
                                key: ValueKey(task.id),
                                padding: const EdgeInsets.only(bottom: 12),
                                child: ReorderableDragStartListener(
                                  index: filteredTasks.indexOf(task),
                                  child: TaskCard(
                                    task: task,
                                    searchQuery: searchQuery,
                                    onEdit: () => _navigateToFormScreen(task),
                                    onDelete: () => _deleteTask(task),
                                    onTap: () => _navigateToFormScreen(task),
                                    onStatusChanged: (newStatus) => _updateTaskStatus(task, newStatus),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToFormScreen(),
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}
