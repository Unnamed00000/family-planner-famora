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
                      if (today.isEmpty && announcements.isEmpty && notifications.isEmpty) {
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
                                  leading: members[task.assignedToId] == null
                                      ? CircleAvatar(child: Icon(task.status.icon))
                                      : MemberAvatar(member: members[task.assignedToId]!),
                                  title: Text(members[task.assignedToId]?.name ?? strings.noAssignee),
                                  subtitle: Text(
                                    task.status == TaskStatus.done && task.completedAt != null
                                        ? '${task.title} - ${timeFormat.format(task.completedAt!)}'
                                        : task.title,
                                  ),
                                  trailing: TaskStatusChip(status: task.status),
                                ),
                              ),
                        ],
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
