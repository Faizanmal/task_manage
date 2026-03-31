import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/task_api_service.dart';
import '../services/draft_storage_service.dart';
import '../widgets/loading_widget.dart';

class TaskFormScreen extends StatefulWidget {
  final Task? task;

  const TaskFormScreen({super.key, this.task});

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  late TextEditingController titleController;
  late TextEditingController descriptionController;
  String selectedStatus = 'TO_DO';
  String selectedRecurring = 'NONE';
  DateTime? selectedDueDate;
  int? selectedBlockedBy;
  List<Task> allTasks = [];
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task?.title ?? '');
    descriptionController = TextEditingController(text: widget.task?.description ?? '');
    selectedStatus = widget.task?.status ?? 'TO_DO';
    selectedRecurring = widget.task?.recurring ?? 'NONE';
    selectedDueDate = widget.task != null ? DateTime.parse(widget.task!.dueDate) : null;
    selectedBlockedBy = widget.task?.blockedBy;
    
    _initialize();
  }

  Future<void> _initialize() async {
    // Load draft if creating new task
    if (widget.task == null) {
      final draft = await DraftStorageService.getDraft();
      if (draft != null) {
        setState(() {
          titleController.text = draft['title'] ?? '';
          descriptionController.text = draft['description'] ?? '';
          selectedStatus = draft['status'] ?? 'TO_DO';
          selectedRecurring = draft['recurring'] ?? 'NONE';
          selectedDueDate = draft['dueDate'] != null 
              ? DateTime.parse(draft['dueDate'])
              : null;
          selectedBlockedBy = draft['blockedBy'];
        });
      }
    }
    
    // Load all tasks for the blocked by dropdown
    _loadAllTasks();
  }

  Future<void> _loadAllTasks() async {
    setState(() => isLoading = true);
    try {
      final tasks = await TaskApiService.getTasks();
      // Filter out the current task from the list
      final filtered = tasks.where((t) {
        return t.id != widget.task?.id;
      }).toList();
      setState(() => allTasks = filtered);
    } catch (e) {
      setState(() => errorMessage = 'Failed to load tasks: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => selectedDueDate = picked);
      // Auto-save draft
      _saveDraft();
    }
  }

  Future<void> _saveDraft() async {
    // Only save draft when creating new task, not when editing
    if (widget.task != null) return;
    
    await DraftStorageService.saveDraft(
      titleController.text,
      descriptionController.text,
      selectedDueDate?.toIso8601String() ?? '',
      selectedStatus,
      selectedBlockedBy,
      selectedRecurring,
    );
  }

  Future<void> _saveTask() async {
    // Validate
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title is required')),
      );
      return;
    }

    if (selectedDueDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Due date is required')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final task = Task(
        id: widget.task?.id ?? 0,
        title: titleController.text,
        description: descriptionController.text,
        dueDate: selectedDueDate!.toIso8601String().split('T')[0],
        status: selectedStatus,
        blockedBy: selectedBlockedBy,
        recurring: selectedRecurring,
        createdAt: widget.task?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      // Simulate 2-second delay as per requirements
      await Future.delayed(const Duration(seconds: 2));

      if (widget.task == null) {
        await TaskApiService.createTask(task);
        // Clear draft on successful creation
        await DraftStorageService.clearDraft();
      } else {
        await TaskApiService.updateTask(widget.task!.id, task);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.task == null ? 'Task created' : 'Task updated')),
        );
      }
    } catch (e) {
      setState(() => errorMessage = 'Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.task == null ? 'Create Task' : 'Edit Task'),
      ),
      body: isLoading
          ? const LoadingWidget()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Field
                  TextField(
                    controller: titleController,
                    onChanged: (_) => _saveDraft(),
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  TextField(
                    controller: descriptionController,
                    onChanged: (_) => _saveDraft(),
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Due Date Field
                  InkWell(
                    onTap: _selectDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: 'Due Date *',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: const Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        selectedDueDate != null
                            ? DateFormat('MMM dd, yyyy').format(selectedDueDate!)
                            : 'Select date',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'TO_DO', child: Text('To-Do')),
                      DropdownMenuItem(value: 'IN_PROGRESS', child: Text('In Progress')),
                      DropdownMenuItem(value: 'DONE', child: Text('Done')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedStatus = value ?? 'TO_DO');
                      _saveDraft();
                    },
                    decoration: InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Recurring Dropdown
                  DropdownButtonFormField<String>(
                    initialValue: selectedRecurring,
                    items: const [
                      DropdownMenuItem(value: 'NONE', child: Text('No Recurrence')),
                      DropdownMenuItem(value: 'DAILY', child: Text('Daily')),
                      DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly')),
                      DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly')),
                    ],
                    onChanged: (value) {
                      setState(() => selectedRecurring = value ?? 'NONE');
                      _saveDraft();
                    },
                    decoration: InputDecoration(
                      labelText: 'Recurrence',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Blocked By Dropdown
                  DropdownButtonFormField<int?>(
                    initialValue: selectedBlockedBy,
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('None'),
                      ),
                      ...allTasks.map((task) {
                        return DropdownMenuItem<int?>(
                          value: task.id,
                          child: Text(task.title),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() => selectedBlockedBy = value);
                      _saveDraft();
                    },
                    decoration: InputDecoration(
                      labelText: 'Blocked By',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: isSaving
                        ? const Column(
                            children: [
                              LoadingWidget(),
                              SizedBox(height: 8),
                              Text('Saving task...', textAlign: TextAlign.center),
                            ],
                          )
                        : ElevatedButton.icon(
                            onPressed: isSaving ? null : _saveTask,
                            icon: const Icon(Icons.save),
                            label: Text(widget.task == null ? 'Create Task' : 'Update Task'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
