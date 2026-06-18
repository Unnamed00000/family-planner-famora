import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({
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
      appBar: AppBar(title: Text(strings.calendar)),
      body: StreamBuilder<List<FamilyMember>>(
        stream: familyRepository.watchMembers(),
        builder: (context, memberSnapshot) {
          final members = {for (final member in memberSnapshot.data ?? <FamilyMember>[]) member.id: member};
          return StreamBuilder<List<TaskItem>>(
            stream: familyRepository.watchTasks(),
            builder: (context, taskSnapshot) {
              final tasks = taskSnapshot.data ?? [];
              return StreamBuilder<List<ActivityItem>>(
                stream: familyRepository.watchActivities(),
                builder: (context, activitySnapshot) {
                  final activities = activitySnapshot.data ?? [];
                  final groupedTasks = <String, List<TaskItem>>{};
                  final groupedActivities = <String, List<ActivityItem>>{};
                  for (final task in tasks) {
                    groupedTasks.putIfAbsent(dateFormat.format(task.dueAt), () => []).add(task);
                  }
                  for (final activity in activities) {
                    groupedActivities.putIfAbsent(dateFormat.format(activity.startAt), () => []).add(activity);
                  }
                  final days = {...groupedTasks.keys, ...groupedActivities.keys}.toList()..sort();
                  if (days.isEmpty) {
                    return EmptyState(icon: Icons.calendar_month_rounded, title: strings.emptyCalendar);
                  }
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      for (final day in days)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(day, style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              for (final activity in groupedActivities[day] ?? <ActivityItem>[])
                                ...[
                                  Card(
                                    child: ListTile(
                                      leading: const Icon(Icons.sports_soccer_rounded),
                                      title: Text(activity.title),
                                      subtitle: Text(
                                        '${strings.activityFor(members[activity.assignedToId]?.name ?? strings.noAssignee)}\n'
                                        '${strings.startTime}: ${timeFormat.format(activity.startAt)}  '
                                        '${strings.leaveHomeTime}: ${timeFormat.format(activity.leaveAt)}'
                                        '${activity.location == null ? '' : '\n${strings.location}: ${activity.location}'}',
                                      ),
                                      isThreeLine: true,
                                      trailing: Chip(label: Text(strings.activityStatus(activity.status))),
                                    ),
                                  ),
                                  if (_canUpdateActivity(activity) && !_isFinished(activity))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8),
                                      child: Wrap(
                                        spacing: 8,
                                        children: [
                                          OutlinedButton.icon(
                                            onPressed: activity.status == ActivityStatus.planned
                                                ? () => familyRepository.markActivityStatus(activity, ActivityStatus.accepted)
                                                : null,
                                            icon: const Icon(Icons.check_circle_outline_rounded),
                                            label: Text(strings.acceptActivity),
                                          ),
                                          OutlinedButton.icon(
                                            onPressed: activity.status == ActivityStatus.planned ||
                                                    activity.status == ActivityStatus.accepted
                                                ? () => familyRepository.markActivityStatus(activity, ActivityStatus.onWay)
                                                : null,
                                            icon: const Icon(Icons.directions_walk_rounded),
                                            label: Text(strings.onWayActivity),
                                          ),
                                          FilledButton.icon(
                                            onPressed: activity.status == ActivityStatus.accepted ||
                                                    activity.status == ActivityStatus.onWay
                                                ? () => familyRepository.markActivityStatus(activity, ActivityStatus.completed)
                                                : null,
                                            icon: const Icon(Icons.flag_rounded),
                                            label: Text(strings.finishActivity),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              for (final task in groupedTasks[day] ?? <TaskItem>[])
                                Card(
                                  child: ListTile(
                                    leading: Icon(task.status.icon, color: task.priority.color),
                                    title: Text(task.title),
                                    subtitle: Text(
                                      '${members[task.assignedToId]?.name ?? strings.noAssignee} - ${timeFormat.format(task.dueAt)}',
                                    ),
                                    trailing: Text(strings.taskRecurrence(task.recurrence)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _canUpdateActivity(ActivityItem activity) {
    final member = currentMember;
    if (member == null) {
      return false;
    }
    return member.role.isAdmin || member.id == activity.assignedToId;
  }

  bool _isFinished(ActivityItem activity) {
    return activity.status == ActivityStatus.completed || activity.status == ActivityStatus.missed;
  }
}
