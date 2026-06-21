import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum UserRole { admin, member }

enum TaskPriority { low, normal, high, urgent }

enum TaskRecurrence { once, daily, weekly, monthly }

enum TaskStatus { pending, inProgress, awaitingApproval, done, overdue }

enum ActivityStatus { planned, accepted, onWay, completed, missed }

extension UserRoleX on UserRole {
  String get wire => name == 'member' ? 'user' : 'admin';

  bool get isAdmin => this == UserRole.admin;

  static UserRole fromWire(String? value) {
    return value == 'admin' ? UserRole.admin : UserRole.member;
  }
}

extension TaskPriorityX on TaskPriority {
  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Низкий';
      case TaskPriority.normal:
        return 'Обычный';
      case TaskPriority.high:
        return 'Высокий';
      case TaskPriority.urgent:
        return 'Срочный';
    }
  }

  Color get color {
    switch (this) {
      case TaskPriority.low:
        return Colors.teal;
      case TaskPriority.normal:
        return Colors.blue;
      case TaskPriority.high:
        return Colors.orange;
      case TaskPriority.urgent:
        return Colors.red;
    }
  }

  static TaskPriority fromWire(String? value) {
    return TaskPriority.values.firstWhere(
      (item) => item.name == value,
      orElse: () => TaskPriority.normal,
    );
  }
}

extension TaskRecurrenceX on TaskRecurrence {
  String get label {
    switch (this) {
      case TaskRecurrence.once:
        return 'Один раз';
      case TaskRecurrence.daily:
        return 'Каждый день';
      case TaskRecurrence.weekly:
        return 'Каждую неделю';
      case TaskRecurrence.monthly:
        return 'Каждый месяц';
    }
  }

  static TaskRecurrence fromWire(String? value) {
    return TaskRecurrence.values.firstWhere(
      (item) => item.name == value,
      orElse: () => TaskRecurrence.once,
    );
  }
}

extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Ожидает';
      case TaskStatus.inProgress:
        return 'Выполняется';
      case TaskStatus.awaitingApproval:
        return 'На проверке';
      case TaskStatus.done:
        return 'Выполнено';
      case TaskStatus.overdue:
        return 'Просрочено';
    }
  }

  IconData get icon {
    switch (this) {
      case TaskStatus.pending:
        return Icons.hourglass_bottom_rounded;
      case TaskStatus.inProgress:
        return Icons.play_circle_rounded;
      case TaskStatus.awaitingApproval:
        return Icons.fact_check_rounded;
      case TaskStatus.done:
        return Icons.check_circle_rounded;
      case TaskStatus.overdue:
        return Icons.warning_rounded;
    }
  }

  static TaskStatus fromWire(String? value) {
    return TaskStatus.values.firstWhere(
      (item) => item.name == value,
      orElse: () => TaskStatus.pending,
    );
  }
}

DateTime? _dateFromJson(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  return null;
}

class FamilyMember {
  const FamilyMember({
    required this.id,
    required this.name,
    required this.age,
    required this.role,
    required this.completedTasks,
    required this.missedTasks,
    required this.points,
    this.authUid,
    this.email,
    this.localLogin,
    this.photoUrl,
    this.photoZoom = 1,
    this.photoOffsetX = 0,
    this.photoOffsetY = 0,
    this.themeMode = ThemeMode.system,
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final int age;
  final UserRole role;
  final int completedTasks;
  final int missedTasks;
  final int points;
  final String? authUid;
  final String? email;
  final String? localLogin;
  final String? photoUrl;
  final double photoZoom;
  final double photoOffsetX;
  final double photoOffsetY;
  final ThemeMode themeMode;
  final bool soundEnabled;
  final bool vibrationEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  double get completionRate {
    final total = completedTasks + missedTasks;
    if (total == 0) {
      return 0;
    }
    return completedTasks / total;
  }

  int get rating => points + completedTasks * 2 - missedTasks * 3;

  List<String> get achievements {
    final result = <String>[];
    if (completedTasks >= 1) {
      result.add('Первая выполненная задача');
    }
    if (completedTasks >= 10) {
      result.add('10 выполненных задач');
    }
    if (completedTasks >= 50) {
      result.add('50 выполненных задач');
    }
    if (completedTasks >= 100) {
      result.add('100 выполненных задач');
    }
    if (missedTasks == 0 && completedTasks >= 7) {
      result.add('Неделя без пропусков');
    }
    if (missedTasks == 0 && completedTasks >= 30) {
      result.add('Месяц без пропусков');
    }
    return result;
  }

  factory FamilyMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FamilyMember(
      id: doc.id,
      name: data['name'] as String? ?? 'Без имени',
      age: (data['age'] as num?)?.toInt() ?? 0,
      role: UserRoleX.fromWire(data['role'] as String?),
      completedTasks: (data['completedTasks'] as num?)?.toInt() ?? 0,
      missedTasks: (data['missedTasks'] as num?)?.toInt() ?? 0,
      points: (data['points'] as num?)?.toInt() ?? 0,
      authUid: data['authUid'] as String?,
      email: data['email'] as String?,
      localLogin: data['localLogin'] as String?,
      photoUrl: data['photoUrl'] as String?,
      photoZoom: (data['photoZoom'] as num?)?.toDouble() ?? 1,
      photoOffsetX: (data['photoOffsetX'] as num?)?.toDouble() ?? 0,
      photoOffsetY: (data['photoOffsetY'] as num?)?.toDouble() ?? 0,
      themeMode: _themeModeFromWire(data['themeMode'] as String?),
      soundEnabled: data['soundEnabled'] as bool? ?? true,
      vibrationEnabled: data['vibrationEnabled'] as bool? ?? true,
      createdAt: _dateFromJson(data['createdAt']),
      updatedAt: _dateFromJson(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'age': age,
      'role': role.wire,
      'completedTasks': completedTasks,
      'missedTasks': missedTasks,
      'points': points,
      'authUid': authUid,
      'email': email,
      'localLogin': localLogin,
      'photoUrl': photoUrl,
      'photoZoom': photoZoom,
      'photoOffsetX': photoOffsetX,
      'photoOffsetY': photoOffsetY,
      'themeMode': themeMode.name,
      'soundEnabled': soundEnabled,
      'vibrationEnabled': vibrationEnabled,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

ThemeMode _themeModeFromWire(String? value) {
  return ThemeMode.values.firstWhere(
    (item) => item.name == value,
    orElse: () => ThemeMode.system,
  );
}

class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToId,
    required this.priority,
    required this.dueAt,
    required this.recurrence,
    required this.status,
    required this.points,
    this.createdBy,
    this.completedBy,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String assignedToId;
  final TaskPriority priority;
  final DateTime dueAt;
  final TaskRecurrence recurrence;
  final TaskStatus status;
  final int points;
  final String? createdBy;
  final String? completedBy;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDone => status == TaskStatus.done;

  bool get isOpenTask => assignedToId.isEmpty;

  bool get isToday {
    final now = DateTime.now();
    return dueAt.year == now.year && dueAt.month == now.month && dueAt.day == now.day;
  }

  factory TaskItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TaskItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Задача',
      description: data['description'] as String? ?? '',
      assignedToId: data['assignedToId'] as String? ?? '',
      priority: TaskPriorityX.fromWire(data['priority'] as String?),
      dueAt: _dateFromJson(data['dueAt']) ?? DateTime.now(),
      recurrence: TaskRecurrenceX.fromWire(data['recurrence'] as String?),
      status: TaskStatusX.fromWire(data['status'] as String?),
      points: (data['points'] as num?)?.toInt() ?? 5,
      createdBy: data['createdBy'] as String?,
      completedBy: data['completedBy'] as String?,
      completedAt: _dateFromJson(data['completedAt']),
      createdAt: _dateFromJson(data['createdAt']),
      updatedAt: _dateFromJson(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'assignedToId': assignedToId,
      'priority': priority.name,
      'dueAt': Timestamp.fromDate(dueAt),
      'recurrence': recurrence.name,
      'status': status.name,
      'points': points,
      'createdBy': createdBy,
      'completedBy': completedBy,
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    this.createdBy,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? updatedAt;

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Announcement(
      id: doc.id,
      title: data['title'] as String? ?? 'Объявление',
      body: data['body'] as String? ?? '',
      createdBy: data['createdBy'] as String?,
      createdAt: _dateFromJson(data['createdAt']) ?? DateTime.now(),
      updatedAt: _dateFromJson(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'createdBy': createdBy,
      'createdAt': id.isEmpty ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.title,
    required this.description,
    required this.assignedToId,
    required this.startAt,
    required this.leaveAt,
    required this.endAt,
    required this.status,
    this.location,
    this.acceptedAt,
    this.onWayAt,
    this.completedAt,
    this.missedAt,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String assignedToId;
  final DateTime startAt;
  final DateTime leaveAt;
  final DateTime endAt;
  final ActivityStatus status;
  final String? location;
  final DateTime? acceptedAt;
  final DateTime? onWayAt;
  final DateTime? completedAt;
  final DateTime? missedAt;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isToday {
    final now = DateTime.now();
    return startAt.year == now.year && startAt.month == now.month && startAt.day == now.day;
  }

  int get durationMinutes {
    final minutes = endAt.difference(startAt).inMinutes;
    return minutes <= 0 ? 0 : minutes;
  }

  factory ActivityItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final startAt = _dateFromJson(data['startAt']) ?? DateTime.now();
    return ActivityItem(
      id: doc.id,
      title: data['title'] as String? ?? 'Activity',
      description: data['description'] as String? ?? '',
      assignedToId: data['assignedToId'] as String? ?? '',
      startAt: startAt,
      leaveAt: _dateFromJson(data['leaveAt']) ?? startAt,
      endAt: _dateFromJson(data['endAt']) ?? startAt.add(const Duration(hours: 1)),
      status: ActivityStatus.values.firstWhere(
        (item) => item.name == data['status'],
        orElse: () => ActivityStatus.planned,
      ),
      location: data['location'] as String?,
      acceptedAt: _dateFromJson(data['acceptedAt']),
      onWayAt: _dateFromJson(data['onWayAt']),
      completedAt: _dateFromJson(data['completedAt']),
      missedAt: _dateFromJson(data['missedAt']),
      createdBy: data['createdBy'] as String?,
      createdAt: _dateFromJson(data['createdAt']),
      updatedAt: _dateFromJson(data['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'assignedToId': assignedToId,
      'startAt': Timestamp.fromDate(startAt),
      'leaveAt': Timestamp.fromDate(leaveAt),
      'endAt': Timestamp.fromDate(endAt),
      'status': status.name,
      'location': location,
      'acceptedAt': acceptedAt == null ? null : Timestamp.fromDate(acceptedAt!),
      'onWayAt': onWayAt == null ? null : Timestamp.fromDate(onWayAt!),
      'completedAt': completedAt == null ? null : Timestamp.fromDate(completedAt!),
      'missedAt': missedAt == null ? null : Timestamp.fromDate(missedAt!),
      'createdBy': createdBy,
      'createdAt': createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(createdAt!),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class FamilyNotification {
  const FamilyNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.assignedToId,
    required this.type,
    required this.createdAt,
    this.entityId,
    this.createdBy,
    this.acceptedAt,
    this.deletedAt,
  });

  final String id;
  final String title;
  final String body;
  final String assignedToId;
  final String type;
  final DateTime createdAt;
  final String? entityId;
  final String? createdBy;
  final DateTime? acceptedAt;
  final DateTime? deletedAt;

  bool get isAccepted => acceptedAt != null;
  bool get isDeleted => deletedAt != null;

  factory FamilyNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return FamilyNotification(
      id: doc.id,
      title: data['title'] as String? ?? 'Notification',
      body: data['body'] as String? ?? '',
      assignedToId: data['assignedToId'] as String? ?? '',
      type: data['type'] as String? ?? 'general',
      entityId: data['entityId'] as String?,
      createdBy: data['createdBy'] as String?,
      acceptedAt: _dateFromJson(data['acceptedAt']),
      deletedAt: _dateFromJson(data['deletedAt']),
      createdAt: _dateFromJson(data['createdAt']) ?? DateTime.now(),
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.pointValueDkk,
  });

  final double pointValueDkk;

  factory AppSettings.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppSettings(
      pointValueDkk: (data['pointValueDkk'] as num?)?.toDouble() ?? 1,
    );
  }
}

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.action,
    required this.entity,
    required this.createdAt,
    this.actorId,
    this.details,
  });

  final String id;
  final String action;
  final String entity;
  final DateTime createdAt;
  final String? actorId;
  final String? details;

  factory HistoryEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return HistoryEntry(
      id: doc.id,
      action: data['action'] as String? ?? '',
      entity: data['entity'] as String? ?? '',
      actorId: data['actorId'] as String?,
      details: data['details'] as String?,
      createdAt: _dateFromJson(data['createdAt']) ?? DateTime.now(),
    );
  }
}
