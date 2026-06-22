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
      appBar: AppBar(
        title: Text(strings.tasks),
        actions: [
          PageHelpAction(title: strings.tasks, body: strings.tasksHelp),
        ],
      ),
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
                              members: members,
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
    required this.members,
    required this.currentMember,
    required this.familyRepository,
    required this.pointValue,
  });

  final TaskItem task;
  final Map<String, FamilyMember> members;
  final FamilyMember? currentMember;
  final FamilyRepository familyRepository;
  final double pointValue;

  @override
  Widget build(BuildContext context) {
    final isAdmin = currentMember?.role.isAdmin == true;
    final currentMemberId = currentMember?.id;
    final isParticipant = currentMemberId != null && task.isParticipant(currentMemberId);
    final hasCompleted = currentMemberId != null && task.hasCompleted(currentMemberId);
    final canClaimOpenTask = currentMember != null && task.canBeClaimed && !isParticipant;
    final canWorkOnTask = isParticipant && !hasCompleted && !task.isDone;
    final canReviewTask = isAdmin && task.completedBy.isNotEmpty && !task.isDone;
    final participantNames = task.participantIds
        .map((memberId) => members[memberId]?.name ?? memberId)
        .join(', ');
    final firstParticipant = task.participantIds.isEmpty ? null : members[task.participantIds.first];
    final rewardColor = firstParticipant == null ? null : familyMemberColor(firstParticipant);
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
              color: rewardColor,
              compact: true,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(participantNames.isEmpty ? strings.noAssignee : participantNames),
                  avatar: const Icon(Icons.group_rounded),
                ),
                Chip(
                  label: Text(strings.participantProgress(task.participantIds.length, task.participantLimit)),
                  avatar: const Icon(Icons.people_alt_rounded),
                ),
                Chip(label: Text(dateFormat.format(task.dueAt)), avatar: const Icon(Icons.event_rounded)),
                Chip(label: Text(timeFormat.format(task.dueAt)), avatar: const Icon(Icons.schedule_rounded)),
                Chip(label: Text(strings.taskRecurrence(task.recurrence)), avatar: const Icon(Icons.repeat_rounded)),
              ],
            ),
            if (canClaimOpenTask) ...[
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () async {
                  final claimed = await familyRepository.claimOpenTask(task, currentMember!);
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(claimed ? strings.taskClaimed : strings.taskAlreadyClaimed)),
                  );
                },
                icon: const Icon(Icons.front_hand_rounded),
                label: Text(strings.claimTask),
              ),
            ],
            if (canWorkOnTask) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed:
                        task.status == TaskStatus.pending ? () => familyRepository.startTask(task, currentMemberId) : null,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(strings.start),
                  ),
                  FilledButton.icon(
                    onPressed: () async {
                      final completed = await familyRepository.completeTask(task, currentMember!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(completed ? strings.taskSentForReview : strings.taskAlreadyClaimed)),
                        );
                      }
                    },
                    icon: const Icon(Icons.fact_check_rounded),
                    label: Text(strings.completeTask),
                  ),
                ],
              ),
            ],
            if (canReviewTask) ...[
              const SizedBox(height: 8),
              Text(strings.participants, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              for (final memberId in task.completedBy)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: members[memberId] == null
                      ? const CircleAvatar(child: Icon(Icons.person_rounded))
                      : MemberAvatar(member: members[memberId]!, radius: 18),
                  title: Text(members[memberId]?.name ?? memberId),
                  subtitle: Text(strings.taskSentForReview),
                  trailing: IconButton(
                    tooltip: strings.redoTask,
                    onPressed: () => familyRepository.returnTaskForRedo(task, memberId),
                    icon: const Icon(Icons.replay_rounded),
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  final approvedCount = await familyRepository.approveCompletedTask(task);
                  if (context.mounted && approvedCount > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.payoutComplete)),
                    );
                  }
                },
                icon: const Icon(Icons.verified_rounded),
                label: Text(strings.approveCompletedAndPay),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
