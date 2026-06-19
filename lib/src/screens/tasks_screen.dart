import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({
    required this.familyRepository,
    required this.currentMember,
    super.key,
  });

  final FamilyRepository familyRepository;
  final FamilyMember? currentMember;

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  String query = '';
  TaskStatus? status;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.tasks)),
      body: StreamBuilder<List<FamilyMember>>(
        stream: widget.familyRepository.watchMembers(),
        builder: (context, memberSnapshot) {
          final members = {for (final member in memberSnapshot.data ?? <FamilyMember>[]) member.id: member};
          return StreamBuilder<List<TaskItem>>(
            stream: widget.familyRepository.watchTasks(),
            builder: (context, taskSnapshot) {
              var tasks = taskSnapshot.data ?? [];
              if (query.trim().isNotEmpty) {
                final lower = query.toLowerCase();
                tasks = tasks
                    .where((task) =>
                        task.title.toLowerCase().contains(lower) || task.description.toLowerCase().contains(lower))
                    .toList();
              }
              if (status != null) {
                tasks = tasks.where((task) => task.status == status).toList();
              }
              return StreamBuilder<AppSettings>(
                stream: widget.familyRepository.watchAppSettings(),
                builder: (context, settingsSnapshot) {
                  final pointValue = settingsSnapshot.data?.pointValueDkk ?? 1;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          labelText: strings.taskSearch,
                        ),
                        onChanged: (value) => setState(() => query = value),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<TaskStatus?>(
                        initialValue: status,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.filter_alt_rounded),
                          labelText: strings.filter,
                        ),
                        items: [
                          DropdownMenuItem(value: null, child: Text(strings.allStatuses)),
                          for (final item in TaskStatus.values)
                            DropdownMenuItem(value: item, child: Text(strings.taskStatus(item))),
                        ],
                        onChanged: (value) => setState(() => status = value),
                      ),
                      const SizedBox(height: 14),
                      if (tasks.isEmpty)
                        EmptyState(icon: Icons.checklist_rounded, title: strings.noTasksFound)
                      else
                        for (final task in tasks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _TaskCard(
                              task: task,
                              member: members[task.assignedToId],
                              currentMember: widget.currentMember,
                              familyRepository: widget.familyRepository,
                              pointValue: pointValue,
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
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.member,
    required this.currentMember,
    required this.familyRepository,
    required this.pointValue,
  });

  final TaskItem task;
  final FamilyMember? member;
  final FamilyMember? currentMember;
  final FamilyRepository familyRepository;
  final double pointValue;

  @override
  Widget build(BuildContext context) {
    final canComplete =
        (currentMember?.role.isAdmin == true || currentMember?.id == task.assignedToId) && task.status != TaskStatus.done;
    final strings = AppStrings.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_rounded, color: task.priority.color),
                const SizedBox(width: 8),
                Expanded(child: Text(task.title, style: Theme.of(context).textTheme.titleMedium)),
                TaskStatusChip(status: task.status),
              ],
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(task.description),
            ],
            const SizedBox(height: 10),
            PointsRewardCard(
              points: task.points,
              pointValue: pointValue,
              label: strings.points,
              color: member == null ? null : familyMemberColor(member!),
              compact: true,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(member?.name ?? strings.noAssignee), avatar: const Icon(Icons.person_rounded)),
                Chip(label: Text(dateFormat.format(task.dueAt)), avatar: const Icon(Icons.event_rounded)),
                Chip(label: Text(timeFormat.format(task.dueAt)), avatar: const Icon(Icons.schedule_rounded)),
                Chip(label: Text(strings.taskRecurrence(task.recurrence)), avatar: const Icon(Icons.repeat_rounded)),
              ],
            ),
            if (canComplete) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        task.status == TaskStatus.inProgress ? null : () => familyRepository.markTask(task, TaskStatus.inProgress),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(strings.start),
                  ),
                  FilledButton.icon(
                    onPressed: task.status == TaskStatus.done
                        ? null
                        : () async {
                            await familyRepository.markTask(task, TaskStatus.done);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '+${strings.pointsAndMoney(task.points, pointValue)}',
                                  ),
                                ),
                              );
                            }
                          },
                    icon: const Icon(Icons.check_rounded),
                    label: Text(strings.done),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
