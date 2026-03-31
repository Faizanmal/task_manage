import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  final String searchQuery;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;
  final Function(String newStatus)? onStatusChanged;

  const TaskCard({
    super.key,
    required this.task,
    this.searchQuery = '',
    required this.onEdit,
    required this.onDelete,
    this.onTap,
    this.onStatusChanged,
  });

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late Task displayTask;
  bool isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    displayTask = widget.task;
  }

  Future<void> _updateStatus(String newStatus) async {
    if (isUpdatingStatus) return;
    
    setState(() {
      isUpdatingStatus = true;
      displayTask = displayTask.copyWith(status: newStatus);
    });

    try {
      if (widget.onStatusChanged != null) {
        widget.onStatusChanged!(newStatus);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        displayTask = widget.task;
      });
    } finally {
      setState(() {
        isUpdatingStatus = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildTaskCard(context);
  }

  Widget _buildTaskCard(BuildContext context) {
    final isBlocked = displayTask.isBlocked;
    final dueDate = DateTime.parse(displayTask.dueDate);
    final isOverdue = dueDate.isBefore(DateTime.now()) && displayTask.status != 'DONE';

    return Card(
      elevation: isBlocked ? 1 : 2,
      color: isBlocked ? Colors.grey[100] : Colors.white,
      child: InkWell(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isOverdue ? Border.all(color: Colors.red, width: 2) : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: _buildHighlightedTextSpans(displayTask.title, widget.searchQuery),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isBlocked ? Colors.grey[600] : Colors.black,
                                decoration: isBlocked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          // Status Badge with Indicator
                          GestureDetector(
                            onTap: isBlocked || isUpdatingStatus ? null : () => _showStatusMenu(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(displayTask.status).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _getStatusColor(displayTask.status),
                                  width: 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (displayTask.status == 'DONE')
                                    Icon(
                                      Icons.check_circle,
                                      size: 14,
                                      color: _getStatusColor(displayTask.status),
                                    )
                                  else if (displayTask.status == 'IN_PROGRESS')
                                    Icon(
                                      Icons.timelapse,
                                      size: 14,
                                      color: _getStatusColor(displayTask.status),
                                    )
                                  else
                                    Icon(
                                      Icons.circle_outlined,
                                      size: 14,
                                      color: _getStatusColor(displayTask.status),
                                    ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _getStatusLabel(displayTask.status),
                                    style: TextStyle(
                                      color: _getStatusColor(displayTask.status),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (!isBlocked && !isUpdatingStatus)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: Icon(
                                        Icons.arrow_drop_down,
                                        size: 14,
                                        color: _getStatusColor(displayTask.status),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Blocked indicator
                    if (isBlocked)
                      Tooltip(
                        message: 'Blocked by: ${displayTask.blockedByDetails?['title']}',
                        child: Icon(
                          Icons.lock_outline,
                          color: Colors.red[300],
                          size: 20,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Description
                if (displayTask.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      displayTask.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isBlocked ? Colors.grey[600] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                // Due Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isOverdue ? Colors.red : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy').format(dueDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                        fontWeight: isOverdue ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (isOverdue)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Overdue',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),

                // Blocked by info
                if (displayTask.blockedByDetails != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, size: 16, color: Colors.red[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Blocked by: ${displayTask.blockedByDetails!['title']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Recurring indicator
                if (displayTask.isRecurring)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.purple[200]!),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.repeat, size: 16, color: Colors.purple[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Recurring: ${displayTask.recurringLabel}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Actions
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isUpdatingStatus)
                        const Padding(
                          padding: EdgeInsets.only(right: 8),
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      else
                        TextButton.icon(
                          onPressed: isBlocked ? null : () => _showStatusMenu(context),
                          icon: const Icon(Icons.check_box_outline_blank),
                          label: const Text('Mark Done'),
                          style: TextButton.styleFrom(
                            foregroundColor: isBlocked ? Colors.grey : Colors.green,
                          ),
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: isBlocked ? null : widget.onEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: isBlocked ? Colors.grey : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: widget.onDelete,
                        icon: const Icon(Icons.delete),
                        label: const Text('Delete'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'TO_DO':
        return Colors.orange;
      case 'IN_PROGRESS':
        return Colors.blue;
      case 'DONE':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'TO_DO':
        return 'To-Do';
      case 'IN_PROGRESS':
        return 'In Progress';
      case 'DONE':
        return 'Done';
      default:
        return status;
    }
  }

  // Helper function to create highlighted text spans
  List<TextSpan> _buildHighlightedTextSpans(String text, String query) {
    if (query.isEmpty) {
      return [TextSpan(text: text)];
    }

    final List<TextSpan> spans = [];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    
    int start = 0;
    int index = lowerText.indexOf(lowerQuery, start);

    while (index != -1) {
      if (index > start) {
        spans.add(TextSpan(text: text.substring(start, index)));
      }
      
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: const TextStyle(
          backgroundColor: Colors.yellow,
          fontWeight: FontWeight.bold,
        ),
      ));
      
      start = index + query.length;
      index = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start)));
    }

    return spans.isEmpty ? [TextSpan(text: text)] : spans;
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.circle_outlined, color: _getStatusColor('TO_DO')),
              title: const Text('To-Do'),
              onTap: () {
                Navigator.pop(ctx);
                if (displayTask.status != 'TO_DO') {
                  _updateStatus('TO_DO');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.timelapse, color: _getStatusColor('IN_PROGRESS')),
              title: const Text('In Progress'),
              onTap: () {
                Navigator.pop(ctx);
                if (displayTask.status != 'IN_PROGRESS') {
                  _updateStatus('IN_PROGRESS');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.check_circle, color: _getStatusColor('DONE')),
              title: const Text('Done'),
              subtitle: displayTask.isRecurring
                  ? const Text('Will auto-generate next cycle')
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                if (displayTask.status != 'DONE') {
                  _updateStatus('DONE');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(TaskCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.task != widget.task) {
      displayTask = widget.task;
    }
  }
}

