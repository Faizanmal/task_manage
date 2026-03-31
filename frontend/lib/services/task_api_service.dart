import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/task.dart';

class TaskApiService {
  static final String baseUrl = const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://192.168.1.10:8000/api');


  // Get all tasks with optional search and filter
  static Future<List<Task>> getTasks({
    String? search,
    String? status,
  }) async {
    try {
      String url = '$baseUrl/tasks/';
      List<String> params = [];
      
      if (search != null && search.isNotEmpty) {
        params.add('search=${Uri.encodeComponent(search)}');
      }
      
      if (status != null && status.isNotEmpty && status != 'ALL') {
        params.add('status=$status');
      }
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> results = jsonData['results'] ?? jsonData;
        return results.map((json) => Task.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load tasks: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Get a single task by ID
  static Future<Task> getTask(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/tasks/$id/'));

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load task: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create a new task
  static Future<Task> createTask(Task task) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 201) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to create task: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Update an existing task
  static Future<Task> updateTask(int id, Task task) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/tasks/$id/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(task.toJson()),
      );

      if (response.statusCode == 200) {
        return Task.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update task: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a task
  static Future<void> deleteTask(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/tasks/$id/'),
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to delete task: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Reorder tasks
  static Future<void> reorderTasks(List<int> taskIds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/tasks/reorder/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'task_ids': taskIds}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to reorder tasks: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}
