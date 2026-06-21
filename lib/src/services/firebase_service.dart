import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../firebase_options.dart';
import '../models/app_models.dart';
import '../utils/photo_url.dart';

class _TaskUpdateResult {
  const _TaskUpdateResult({
    this.createRecurringTask = false,
    this.createReviewNotification = false,
    this.clearReviewNotifications = false,
  });

  final bool createRecurringTask;
  final bool createReviewNotification;
  final bool clearReviewNotifications;
}

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithFamilyLogin(String login, String password) async {
    final key = login.trim().toLowerCase();
    final doc = await _firestore.collection('familyLogins').doc(key).get();
    final email = doc.data()?['email'] as String?;
    if (email == null || email.isEmpty) {
      throw FirebaseAuthException(
        code: 'family-login-not-found',
        message: 'Семейный логин не найден',
      );
    }
    await signInWithEmail(email, password);
  }

  Future<void> registerWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();
}

class FamilyRepository {
  FamilyRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
    FirebaseMessaging? messaging,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;
  final FirebaseMessaging _messaging;

  CollectionReference<Map<String, dynamic>> get _members => _firestore.collection('members');

  CollectionReference<Map<String, dynamic>> get _tasks => _firestore.collection('tasks');

  CollectionReference<Map<String, dynamic>> get _announcements => _firestore.collection('announcements');

  CollectionReference<Map<String, dynamic>> get _activities => _firestore.collection('activities');

  CollectionReference<Map<String, dynamic>> get _notifications => _firestore.collection('notifications');

  CollectionReference<Map<String, dynamic>> get _history => _firestore.collection('history');

  DocumentReference<Map<String, dynamic>> get _appSettings => _firestore.collection('settings').doc('app');

  Stream<List<FamilyMember>> watchMembers() {
    return _members.orderBy('points', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(FamilyMember.fromDoc).toList(),
        );
  }

  Stream<FamilyMember?> watchCurrentMember() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value(null);
    }
    return _members.doc(uid).snapshots().asyncMap((directDoc) async {
      if (directDoc.exists) {
        return FamilyMember.fromDoc(directDoc);
      }
      final snapshot = await _members.where('authUid', isEqualTo: uid).limit(1).get();
      if (snapshot.docs.isEmpty) {
        return null;
      }
      return FamilyMember.fromDoc(snapshot.docs.first);
    });
  }

  Future<void> claimMemberProfile(String memberId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return;
    }
    await _members.doc(memberId).update({
      'authUid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<TaskItem>> watchTasks() {
    return _tasks.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(TaskItem.fromDoc).toList(),
        );
  }

  Stream<List<TaskItem>> watchTasksForMember(String memberId) {
    return watchTasks().map(
      (tasks) => tasks.where((task) => task.isParticipant(memberId)).toList(),
    );
  }

  Stream<List<Announcement>> watchAnnouncements() {
    return _announcements.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(Announcement.fromDoc).toList(),
        );
  }

  Stream<List<ActivityItem>> watchActivities() {
    return _activities.orderBy('startAt').snapshots().map(
          (snapshot) => snapshot.docs.map(ActivityItem.fromDoc).toList(),
        );
  }

  Stream<List<ActivityItem>> watchActivitiesForMember(String memberId) {
    return _activities.where('assignedToId', isEqualTo: memberId).snapshots().map((snapshot) {
      final activities = snapshot.docs.map(ActivityItem.fromDoc).toList();
      activities.sort((a, b) => a.startAt.compareTo(b.startAt));
      return activities;
    });
  }

  Stream<List<FamilyNotification>> watchNotifications() {
    return _notifications.orderBy('createdAt', descending: true).snapshots().map(
          (snapshot) => snapshot.docs.map(FamilyNotification.fromDoc).where((item) => !item.isDeleted).toList(),
        );
  }

  Stream<AppSettings> watchAppSettings() {
    return _appSettings.snapshots().map(AppSettings.fromDoc);
  }

  Stream<List<HistoryEntry>> watchHistory() {
    return _history.orderBy('createdAt', descending: true).limit(80).snapshots().map(
          (snapshot) => snapshot.docs.map(HistoryEntry.fromDoc).toList(),
        );
  }

  Future<void> saveMember(FamilyMember member) async {
    final id = member.id.isEmpty ? _members.doc().id : member.id;
    await _members.doc(id).set(member.toJson(), SetOptions(merge: true));
    if (member.localLogin != null && member.email != null) {
      await _firestore.collection('familyLogins').doc(member.localLogin!.toLowerCase()).set({
        'email': member.email,
        'memberId': id,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await writeHistory('save', 'member', member.name);
  }

  Future<String> createAuthAccount({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:signUp'
        '?key=${DefaultFirebaseOptions.currentPlatform.apiKey}',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      final error = body['error'] as Map<String, dynamic>?;
      throw FirebaseAuthException(
        code: error?['message'] as String? ?? 'create-user-failed',
        message: error?['message'] as String? ?? response.body,
      );
    }
    return body['localId'] as String;
  }

  Future<void> deleteMember(String memberId) async {
    await _members.doc(memberId).delete();
    await writeHistory('delete', 'member', memberId);
  }

  Future<String> uploadMemberPhoto(
    String memberId,
    Uint8List bytes,
    String contentType, {
    double photoZoom = 1,
    double photoOffsetX = 0,
    double photoOffsetY = 0,
    void Function(double progress)? onProgress,
  }) async {
    final ref = _storage.ref('member_photos/$memberId/profile');
    final task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    onProgress?.call(0.01);
    final subscription = task.snapshotEvents.listen((snapshot) {
      final total = snapshot.totalBytes;
      if (total > 0) {
        onProgress?.call(snapshot.bytesTransferred / total);
      }
    });
    try {
      await task.timeout(
        const Duration(seconds: 60),
        onTimeout: () async {
          await task.cancel();
          throw TimeoutException('Фото не загрузилось за 60 секунд. Проверьте Firebase Storage и интернет.');
        },
      );
    } finally {
      await subscription.cancel();
    }
    onProgress?.call(1);
    final url = await ref.getDownloadURL().timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw TimeoutException('Не удалось получить ссылку на фото из Firebase Storage.'),
    );
    await _members.doc(memberId).update({
      'photoUrl': url,
      'photoZoom': photoZoom,
      'photoOffsetX': photoOffsetX.clamp(-1, 1),
      'photoOffsetY': photoOffsetY.clamp(-1, 1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeHistory('upload_photo', 'member', memberId);
    return url;
  }

  Future<void> updateMemberPreferences(
    String memberId, {
    ThemeMode? themeMode,
    bool? soundEnabled,
    bool? vibrationEnabled,
  }) async {
    await _members.doc(memberId).update({
      if (themeMode != null) 'themeMode': themeMode.name,
      if (soundEnabled != null) 'soundEnabled': soundEnabled,
      if (vibrationEnabled != null) 'vibrationEnabled': vibrationEnabled,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateMemberPhotoUrl(
    String memberId,
    String? photoUrl, {
    double photoZoom = 1,
    double photoOffsetX = 0,
    double photoOffsetY = 0,
  }) async {
    final cleanPhotoUrl = normalizePhotoUrl(photoUrl ?? '');
    await _members.doc(memberId).update({
      'photoUrl': cleanPhotoUrl.isEmpty ? null : cleanPhotoUrl,
      'photoZoom': photoZoom.clamp(1, 2),
      'photoOffsetX': photoOffsetX.clamp(-1, 1),
      'photoOffsetY': photoOffsetY.clamp(-1, 1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeHistory('set_photo_url', 'member', memberId);
  }

  Future<void> setMemberPoints(String memberId, int points) async {
    await _members.doc(memberId).update({
      'points': points,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeHistory('set_points', 'member', '$memberId: $points');
  }

  Future<void> saveTask(TaskItem task) async {
    final id = task.id.isEmpty ? _tasks.doc().id : task.id;
    final taskRef = _tasks.doc(id);
    final existing = task.id.isEmpty ? null : await taskRef.get();
    final current = existing?.exists == true ? TaskItem.fromDoc(existing!) : null;
    final participantIds = task.participantIds.isNotEmpty
        ? task.participantIds
        : task.assignedToId.isNotEmpty
            ? [task.assignedToId]
            : current?.participantIds ?? const <String>[];
    final savedTask = TaskItem(
      id: id,
      title: task.title,
      description: task.description,
      assignedToId: task.assignedToId,
      priority: task.priority,
      dueAt: task.dueAt,
      recurrence: task.recurrence,
      status: current?.isDone == true ? TaskStatus.done : task.status,
      points: task.points,
      participantLimit: task.assignedToId.isEmpty ? task.participantLimit : 1,
      participantIds: participantIds,
      createdBy: task.createdBy,
      completedBy: current?.completedBy ?? task.completedBy,
      approvedBy: current?.approvedBy ?? task.approvedBy,
      completedAt: current?.completedAt ?? task.completedAt,
      createdAt: task.createdAt,
    );
    await taskRef.set(savedTask.toJson(), SetOptions(merge: true));
    await writeHistory('save', 'task', task.title);
  }

  Future<void> deleteTask(String taskId) async {
    await _tasks.doc(taskId).delete();
    await writeHistory('delete', 'task', taskId);
  }

  Future<bool> claimOpenTask(TaskItem task, FamilyMember member) async {
    if (!task.canBeClaimed || task.isParticipant(member.id)) {
      return false;
    }

    final taskRef = _tasks.doc(task.id);
    final claimed = await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) {
        return false;
      }
      final current = TaskItem.fromDoc(snapshot);
      if (!current.canBeClaimed || current.isParticipant(member.id)) {
        return false;
      }
      transaction.update(taskRef, {
        'participantIds': [...current.participantIds, member.id],
        'status': TaskStatus.inProgress.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });

    if (claimed) {
      await _createTaskClaimNotifications(task, member);
      await writeHistory('claim', 'task', '${member.name}: ${task.title}');
    }
    return claimed;
  }

  Future<void> startTask(TaskItem task, String memberId) async {
    if (!task.isParticipant(memberId) || task.status == TaskStatus.done) {
      return;
    }
    await _tasks.doc(task.id).update({
      'status': TaskStatus.inProgress.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeHistory('start', 'task', task.title);
  }

  Future<bool> completeTask(TaskItem task, FamilyMember member) async {
    final taskRef = _tasks.doc(task.id);
    final completed = await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) {
        return false;
      }
      final current = TaskItem.fromDoc(snapshot);
      if (!current.isParticipant(member.id) || current.hasCompleted(member.id) || current.isDone) {
        return false;
      }
      transaction.update(taskRef, {
        'completedBy': [...current.completedBy, member.id],
        'status': TaskStatus.awaitingApproval.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
    if (completed) {
      await _createTaskReviewNotificationsForMember(task, member);
      await writeHistory('complete', 'task', '${member.name}: ${task.title}');
    }
    return completed;
  }

  Future<bool> approveTaskParticipant(TaskItem task, String memberId) async {
    final taskRef = _tasks.doc(task.id);
    final paid = await _firestore.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) {
        return false;
      }
      final current = TaskItem.fromDoc(snapshot);
      if (!current.hasCompleted(memberId) || current.hasApproved(memberId) || current.isDone) {
        return false;
      }
      final approvedBy = [...current.approvedBy, memberId];
      final isReadyForPayout = current.participantIds.isNotEmpty && current.participantIds.every(approvedBy.contains);
      transaction.update(taskRef, {
        'approvedBy': approvedBy,
        'status': isReadyForPayout ? TaskStatus.done.name : TaskStatus.awaitingApproval.name,
        if (isReadyForPayout) 'completedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!isReadyForPayout) {
        return false;
      }
      final basePoints = current.points ~/ approvedBy.length;
      final remainder = current.points % approvedBy.length;
      for (var index = 0; index < approvedBy.length; index++) {
        transaction.update(_members.doc(approvedBy[index]), {
          'completedTasks': FieldValue.increment(1),
          'points': FieldValue.increment(basePoints + (index < remainder ? 1 : 0)),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return true;
    });

    if (paid) {
      await acceptNotificationsForEntity(task.id);
      if (task.recurrence != TaskRecurrence.once) {
        await _createRecurringTask(task);
      }
      await writeHistory('approve_and_pay', 'task', task.title);
    } else {
      await writeHistory('approve', 'task', task.title);
    }
    return paid;
  }

  Future<void> returnTaskForRedo(TaskItem task, String memberId) async {
    final taskRef = _tasks.doc(task.id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) {
        return;
      }
      final current = TaskItem.fromDoc(snapshot);
      final completedBy = current.completedBy.where((id) => id != memberId).toList();
      final approvedBy = current.approvedBy.where((id) => id != memberId).toList();
      transaction.update(taskRef, {
        'completedBy': completedBy,
        'approvedBy': approvedBy,
        'status': completedBy.isEmpty ? TaskStatus.inProgress.name : TaskStatus.awaitingApproval.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    await writeHistory('redo', 'task', task.title);
  }

  Future<void> saveActivity(ActivityItem activity) async {
    final id = activity.id.isEmpty ? _activities.doc().id : activity.id;
    final doc = _activities.doc(id);
    final existing = activity.id.isEmpty ? null : await doc.get();
    final previousAssignee = existing?.data()?['assignedToId'] as String?;
    await doc.set(activity.toJson(), SetOptions(merge: true));
    if (activity.id.isEmpty || previousAssignee != activity.assignedToId) {
      await createNotification(
        title: activity.title,
        body: activity.location == null || activity.location!.isEmpty
            ? 'Leave at ${activity.leaveAt.toIso8601String()}'
            : '${activity.location} - leave at ${activity.leaveAt.toIso8601String()}',
        assignedToId: activity.assignedToId,
        type: 'activity',
        entityId: id,
      );
    }
    await writeHistory('save', 'activity', activity.title);
  }

  Future<void> deleteActivity(String activityId) async {
    await _activities.doc(activityId).delete();
    final snapshot = await _notifications.where('entityId', isEqualTo: activityId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'deletedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await writeHistory('delete', 'activity', activityId);
  }

  Future<void> markActivityStatus(ActivityItem activity, ActivityStatus status) async {
    final now = DateTime.now();
    await _activities.doc(activity.id).update({
      'status': status.name,
      if (status == ActivityStatus.accepted) 'acceptedAt': Timestamp.fromDate(now),
      if (status == ActivityStatus.onWay) 'onWayAt': Timestamp.fromDate(now),
      if (status == ActivityStatus.completed) 'completedAt': Timestamp.fromDate(now),
      if (status == ActivityStatus.missed) 'missedAt': Timestamp.fromDate(now),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (status == ActivityStatus.accepted) {
      await acceptNotificationsForEntity(activity.id);
    }
    await writeHistory(status.name, 'activity', activity.title);
  }

  Future<void> markTask(TaskItem task, TaskStatus status) async {
    if (task.status == TaskStatus.done && status != TaskStatus.done) {
      return;
    }
    final uid = _auth.currentUser?.uid;
    final now = DateTime.now();
    final completed = status == TaskStatus.done;
    final taskRef = _tasks.doc(task.id);
    final memberRef = _members.doc(task.assignedToId);
    final result = await _firestore.runTransaction<_TaskUpdateResult>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      final currentStatus = TaskStatusX.fromWire(snapshot.data()?['status'] as String?);
      if (currentStatus == TaskStatus.done && status != TaskStatus.done) {
        return const _TaskUpdateResult();
      }

      transaction.update(taskRef, {
        'status': status.name,
        'completedAt': completed ? Timestamp.fromDate(now) : null,
        'completedBy': completed ? uid : null,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (completed && currentStatus != TaskStatus.done) {
        transaction.update(memberRef, {
          'completedTasks': FieldValue.increment(1),
          'points': FieldValue.increment(task.points),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return _TaskUpdateResult(
          createRecurringTask: task.recurrence != TaskRecurrence.once,
          clearReviewNotifications: true,
        );
      }

      if (status == TaskStatus.awaitingApproval && currentStatus != TaskStatus.awaitingApproval) {
        return const _TaskUpdateResult(createReviewNotification: true);
      }

      if (currentStatus == TaskStatus.awaitingApproval && status == TaskStatus.pending) {
        return const _TaskUpdateResult(clearReviewNotifications: true);
      }

      if (status == TaskStatus.overdue && currentStatus != TaskStatus.overdue) {
        transaction.update(memberRef, {
          'missedTasks': FieldValue.increment(1),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      return const _TaskUpdateResult();
    });

    if (result.createReviewNotification) {
      await _createTaskReviewNotifications(task);
    }
    if (result.clearReviewNotifications) {
      await acceptNotificationsForEntity(task.id);
    }
    if (result.createRecurringTask) {
      final nextTask = TaskItem(
        id: '',
        title: task.title,
        description: task.description,
        assignedToId: task.assignedToId,
        priority: task.priority,
        dueAt: _nextDueAt(task.dueAt, task.recurrence),
        recurrence: task.recurrence,
        status: TaskStatus.pending,
        points: task.points,
        createdBy: task.createdBy,
      );
      await _tasks.add(nextTask.toJson());
    }
    await writeHistory(status.name, 'task', task.title);
  }

  Future<void> _createTaskReviewNotifications(TaskItem task) async {
    final admins = await _members.where('role', isEqualTo: 'admin').get();
    for (final admin in admins.docs) {
      await createNotification(
        title: 'Проверить задачу',
        body: '${task.title} — ребёнок отправил задачу на проверку. Подтверди и оплати или верни на переделку.',
        assignedToId: admin.id,
        type: 'task_review',
        entityId: task.id,
      );
    }
  }

  Future<void> _createTaskReviewNotificationsForMember(TaskItem task, FamilyMember member) async {
    final admins = await _members.where('role', isEqualTo: 'admin').get();
    for (final admin in admins.docs) {
      await createNotification(
        title: 'Task completed',
        body: '${member.name} completed "${task.title}" and is waiting for your approval.',
        assignedToId: admin.id,
        type: 'task_review',
        entityId: task.id,
      );
    }
  }

  Future<void> _createTaskClaimNotifications(TaskItem task, FamilyMember member) async {
    final admins = await _members.where('role', isEqualTo: 'admin').get();
    for (final admin in admins.docs) {
      await createNotification(
        title: 'Task claimed',
        body: '${member.name} claimed "${task.title}" and started working on it.',
        assignedToId: admin.id,
        type: 'task_claim',
        entityId: task.id,
      );
    }
  }

  Future<void> _createRecurringTask(TaskItem task) async {
    await _tasks.add(
      TaskItem(
        id: '',
        title: task.title,
        description: task.description,
        assignedToId: task.assignedToId,
        priority: task.priority,
        dueAt: _nextDueAt(task.dueAt, task.recurrence),
        recurrence: task.recurrence,
        status: TaskStatus.pending,
        points: task.points,
        participantLimit: task.participantLimit,
        participantIds: task.assignedToId.isEmpty ? const [] : task.participantIds,
        createdBy: task.createdBy,
      ).toJson(),
    );
  }

  DateTime _nextDueAt(DateTime current, TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.once:
        return current;
      case TaskRecurrence.daily:
        return current.add(const Duration(days: 1));
      case TaskRecurrence.weekly:
        return current.add(const Duration(days: 7));
      case TaskRecurrence.monthly:
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
    }
  }

  Future<void> createAnnouncement(String title, String body) async {
    await saveAnnouncement(
      Announcement(
        id: '',
        title: title,
        body: body,
        createdBy: _auth.currentUser?.uid,
        createdAt: DateTime.now(),
      ),
    );
    await writeHistory('create', 'announcement', title);
  }

  Future<void> saveAnnouncement(Announcement announcement) async {
    final id = announcement.id.isEmpty ? _announcements.doc().id : announcement.id;
    await _announcements.doc(id).set(announcement.toJson(), SetOptions(merge: true));
    await writeHistory('save', 'announcement', announcement.title);
  }

  Future<void> deleteAnnouncement(String announcementId) async {
    await _announcements.doc(announcementId).delete();
    await writeHistory('delete', 'announcement', announcementId);
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required String assignedToId,
    required String type,
    String? entityId,
  }) async {
    await _notifications.add({
      'title': title,
      'body': body,
      'assignedToId': assignedToId,
      'type': type,
      'entityId': entityId,
      'createdBy': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeHistory('create', 'notification', title);
  }

  Future<void> acceptNotification(FamilyNotification notification) async {
    await _notifications.doc(notification.id).update({
      'acceptedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    if (notification.type == 'activity' && notification.entityId != null) {
      final doc = await _activities.doc(notification.entityId).get();
      if (doc.exists) {
        final activity = ActivityItem.fromDoc(doc);
        if (activity.status == ActivityStatus.planned) {
          await markActivityStatus(activity, ActivityStatus.accepted);
        }
      }
    }
  }

  Future<void> acceptNotificationsForEntity(String entityId) async {
    final snapshot = await _notifications.where('entityId', isEqualTo: entityId).get();
    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'acceptedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    await _notifications.doc(notificationId).update({
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await writeHistory('delete', 'notification', notificationId);
  }

  Future<void> savePointValueDkk(double value) async {
    await _appSettings.set({
      'pointValueDkk': value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await writeHistory('save', 'settings', 'pointValueDkk');
  }

  Future<void> savePushToken(FamilyMember member) async {
    try {
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return;
      }
      final token = await _messaging.getToken();
      if (token == null) {
        return;
      }
      await _members.doc(member.id).update({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      return;
    }
  }

  Future<void> writeHistory(String action, String entity, String? details) async {
    await _history.add({
      'action': action,
      'entity': entity,
      'details': details,
      'actorId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> exportBackup() async {
    final members = await _members.get();
    final tasks = await _tasks.get();
    final activities = await _activities.get();
    final announcements = await _announcements.get();
    final history = await _history.orderBy('createdAt', descending: true).limit(200).get();
    return {
      'exportedAt': DateTime.now().toIso8601String(),
      'members': {
        for (final doc in members.docs) doc.id: _jsonSafe(doc.data()),
      },
      'tasks': {
        for (final doc in tasks.docs) doc.id: _jsonSafe(doc.data()),
      },
      'activities': {
        for (final doc in activities.docs) doc.id: _jsonSafe(doc.data()),
      },
      'announcements': {
        for (final doc in announcements.docs) doc.id: _jsonSafe(doc.data()),
      },
      'history': {
        for (final doc in history.docs) doc.id: _jsonSafe(doc.data()),
      },
    };
  }

  Map<String, dynamic> _jsonSafe(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Timestamp) {
        return MapEntry(key, value.toDate().toIso8601String());
      }
      return MapEntry(key, value);
    });
  }
}
