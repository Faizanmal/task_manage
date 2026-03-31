class Task {
  final int id;
  final String title;
  final String description;
  final String dueDate;
  final String status;
  final int? blockedBy;
  final Map<String, dynamic>? blockedByDetails;
  final String recurring;
  final bool isRecurringInstance;
  final int? recurringParent;
  final int position;
  final String createdAt;
  final String updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.status,
    this.blockedBy,
    this.blockedByDetails,
    this.recurring = 'NONE',
    this.isRecurringInstance = false,
    this.recurringParent,
    this.position = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      dueDate: json['due_date'] as String,
      status: json['status'] as String,
      blockedBy: json['blocked_by'] as int?,
      blockedByDetails: json['blocked_by_details'] as Map<String, dynamic>?,
      recurring: json['recurring'] as String? ?? 'NONE',
      isRecurringInstance: json['is_recurring_instance'] as bool? ?? false,
      recurringParent: json['recurring_parent'] as int?,
      position: json['position'] as int? ?? 0,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'due_date': dueDate,
      'status': status,
      'blocked_by': blockedBy,
      'recurring': recurring,
      'position': position,
    };
  }

  Task copyWith({
    int? id,
    String? title,
    String? description,
    String? dueDate,
    String? status,
    int? blockedBy,
    Map<String, dynamic>? blockedByDetails,
    String? recurring,
    bool? isRecurringInstance,
    int? recurringParent,
    int? position,
    String? createdAt,
    String? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      blockedBy: blockedBy ?? this.blockedBy,
      blockedByDetails: blockedByDetails ?? this.blockedByDetails,
      recurring: recurring ?? this.recurring,
      isRecurringInstance: isRecurringInstance ?? this.isRecurringInstance,
      recurringParent: recurringParent ?? this.recurringParent,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isBlocked {
    if (blockedByDetails == null) return false;
    final blockedByStatus = blockedByDetails!['status'] as String?;
    return blockedByStatus != 'DONE';
  }
  
  bool get isRecurring => recurring != 'NONE';
  
  String get recurringLabel {
    switch (recurring) {
      case 'DAILY':
        return 'Daily';
      case 'WEEKLY':
        return 'Weekly';
      case 'MONTHLY':
        return 'Monthly';
      default:
        return 'None';
    }
  }
}
