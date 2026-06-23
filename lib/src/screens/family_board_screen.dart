import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class FamilyBoardScreen extends StatelessWidget {
  const FamilyBoardScreen({
    required this.familyRepository,
    required this.currentMember,
    super.key,
  });

  final FamilyRepository familyRepository;
  final FamilyMember? currentMember;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.board),
        actions: [
          PageHelpAction(title: strings.board, body: strings.boardHelp),
        ],
      ),
      body: StreamBuilder<List<FamilyMember>>(
        stream: familyRepository.watchMembers(),
        builder: (context, memberSnapshot) {
          final members = {for (final member in memberSnapshot.data ?? <FamilyMember>[]) member.id: member};
          return StreamBuilder<List<FamilyNotification>>(
            stream: familyRepository.watchNotifications(),
            builder: (context, notificationSnapshot) {
              final member = currentMember;
              final notifications = (notificationSnapshot.data ?? [])
                  .where((item) => member?.role.isAdmin == true || item.assignedToId == member?.id)
                  .toList();
              return StreamBuilder<List<Announcement>>(
                stream: familyRepository.watchAnnouncements(),
                builder: (context, announcementSnapshot) {
                  final announcements = announcementSnapshot.data ?? [];
                  return StreamBuilder<List<TaskItem>>(
                    stream: familyRepository.watchTasks(),
                    builder: (context, taskSnapshot) {
                      final today = (taskSnapshot.data ?? []).where((task) => task.isToday).toList();
                      return StreamBuilder<List<HistoryEntry>>(
                        stream: familyRepository.watchHistory(),
                        builder: (context, historySnapshot) {
                          final taskHistory = (historySnapshot.data ?? [])
                              .where((entry) => entry.action == 'task_finalized')
                              .toList();
                          if (today.isEmpty && announcements.isEmpty && notifications.isEmpty && taskHistory.isEmpty) {
                            return EmptyState(
                              icon: Icons.dashboard_rounded,
                              title: strings.noTasksToday,
                            );
                          }
                          return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _SectionTitle(title: strings.notifications, icon: Icons.notifications_active_rounded),
                          if (notifications.isEmpty)
                            Card(child: ListTile(title: Text(strings.noNotifications)))
                          else
                            for (final notification in notifications)
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.notifications_rounded),
                                  title: Text(notification.title),
                                  subtitle: Text(
                                    '${members[notification.assignedToId]?.name ?? strings.noAssignee}\n${notification.body}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Wrap(
                                    spacing: 4,
                                    children: [
                                      if (notification.isAccepted)
                                        Chip(label: Text(strings.notificationAccepted))
                                      else if (member?.id == notification.assignedToId)
                                        FilledButton(
                                          onPressed: () => familyRepository.acceptNotification(notification),
                                          child: Text(strings.acceptNotification),
                                        ),
                                      if (member?.role.isAdmin == true)
                                        IconButton(
                                          tooltip: strings.delete,
                                          onPressed: () => familyRepository.deleteNotification(notification.id),
                                          icon: const Icon(Icons.delete_rounded),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                          const SizedBox(height: 16),
                          _SectionTitle(title: strings.announcements, icon: Icons.campaign_rounded),
                          if (announcements.isEmpty)
                            Card(child: ListTile(title: Text(strings.noAnnouncements)))
                          else
                            for (final announcement in announcements.take(8))
                              Card(
                                child: ListTile(
                                  leading: const Icon(Icons.campaign_rounded),
                                  title: Text(announcement.title),
                                  subtitle: Text(announcement.body),
                                ),
                              ),
                          const SizedBox(height: 16),
                          _SectionTitle(title: strings.boardTasks, icon: Icons.checklist_rounded),
                          if (today.isEmpty)
                            Card(child: ListTile(title: Text(strings.noTasksToday)))
                          else
                            for (final task in today)
                              Card(
                                child: ListTile(
                                  leading: task.participantIds.isEmpty || members[task.participantIds.first] == null
                                      ? CircleAvatar(child: Icon(task.status.icon))
                                      : MemberAvatar(member: members[task.participantIds.first]!),
                                  title: Text(
                                    task.participantIds.isEmpty
                                        ? strings.noAssignee
                                        : task.participantIds.map((id) => members[id]?.name ?? id).join(', '),
                                  ),
                                  subtitle: Text(
                                    task.status == TaskStatus.done && task.completedAt != null
                                        ? '${task.title} - ${timeFormat.format(task.completedAt!)}'
                                        : task.title,
                                  ),
                                  trailing: TaskStatusChip(status: task.status),
                                ),
                              ),
                          const SizedBox(height: 16),
                          _SectionTitle(title: strings.history, icon: Icons.history_rounded),
                          if (taskHistory.isEmpty)
                            Card(child: ListTile(title: Text(strings.historyEmpty)))
                          else
                            for (final entry in taskHistory.take(30))
                              _TaskHistoryCard(entry: entry, members: members),
                        ],
                      );
                        },
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _TaskHistoryCard extends StatelessWidget {
  const _TaskHistoryCard({
    required this.entry,
    required this.members,
  });

  final HistoryEntry entry;
  final Map<String, FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final data = entry.data;
    final approvedIds = _stringIds(data?['approvedMemberIds']);
    final droppedIds = _stringIds(data?['droppedMemberIds']);
    final rewardData = data?['rewards'];
    final rewards = rewardData is Map
        ? rewardData.map<String, int>((key, value) => MapEntry(key.toString(), (value as num?)?.toInt() ?? 0))
        : <String, int>{};
    final adminId = data?['approvedByAdminId'] as String?;
    final title = data?['taskTitle'] as String? ?? entry.details ?? strings.tasks;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.task_alt_rounded),
                const SizedBox(width: 8),
                Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),
            if (adminId != null)
              Text('${strings.confirmedBy}: ${members[adminId]?.name ?? adminId}'),
            Text('${dateFormat.format(entry.createdAt)} ${timeFormat.format(entry.createdAt)}'),
            if (approvedIds.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final memberId in approvedIds)
                Text(
                  '${members[memberId]?.name ?? memberId}: ${strings.participantApproved} '
                  '+${rewards[memberId] ?? 0} ${strings.points}',
                ),
            ],
            if (droppedIds.isNotEmpty) ...[
              const SizedBox(height: 6),
              for (final memberId in droppedIds)
                Text('${members[memberId]?.name ?? memberId}: ${strings.withdrewNoReward}'),
            ],
          ],
        ),
      ),
    );
  }

  List<String> _stringIds(dynamic value) {
    if (value is List) {
      return value.whereType<String>().toList();
    }
    return const [];
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.icon,
  });

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
        ],
      ),
    );
  }
}
