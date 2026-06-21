import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.familyRepository,
    super.key,
  });

  final FamilyRepository familyRepository;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.home),
        actions: [
          PageHelpAction(title: strings.home, body: strings.homeHelp),
        ],
      ),
      body: StreamBuilder<List<FamilyMember>>(
        stream: familyRepository.watchMembers(),
        builder: (context, membersSnapshot) {
          final members = membersSnapshot.data ?? [];
          return StreamBuilder<List<TaskItem>>(
            stream: familyRepository.watchTasks(),
            builder: (context, tasksSnapshot) {
              final tasks = tasksSnapshot.data ?? [];
              if (members.isEmpty) {
                return EmptyState(
                  icon: Icons.family_restroom_rounded,
                  title: strings.addFamilyMembers,
                  subtitle: strings.adminCanCreateProfiles,
                );
              }
              final todayTasks = tasks.where((task) => task.isToday).toList();
              final leader = _leader(members, todayTasks);
              final notDone = members.where((member) {
                final memberTasks = todayTasks.where((task) => task.isParticipant(member.id));
                return memberTasks.any((task) => !task.isCompletedFor(member.id));
              }).toList();
              return StreamBuilder<AppSettings>(
                stream: familyRepository.watchAppSettings(),
                builder: (context, settingsSnapshot) {
                  final pointValue = settingsSnapshot.data?.pointValueDkk ?? 1;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          StatPill(
                            icon: Icons.emoji_events_rounded,
                            label: strings.dayLeader,
                            value: leader?.name ?? strings.noneYet,
                          ),
                          StatPill(
                            icon: Icons.check_circle_rounded,
                            label: strings.completedToday,
                            value: todayTasks.where((task) => task.isDone).length.toString(),
                          ),
                          StatPill(
                            icon: Icons.pending_actions_rounded,
                            label: strings.stillLeft,
                            value: todayTasks.where((task) => !task.isDone).length.toString(),
                          ),
                        ],
                      ),
                      if (notDone.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Text(strings.tasksRemainFor(notDone.map((member) => member.name).join(', '))),
                      ],
                      const SizedBox(height: 18),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 360,
                          mainAxisExtent: 320,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: members.length,
                        itemBuilder: (context, index) {
                          final member = members[index];
                          final memberTasks = todayTasks.where((task) => task.isParticipant(member.id)).toList();
                          final done = memberTasks.where((task) => task.isCompletedFor(member.id)).length;
                          final percent = memberTasks.isEmpty ? 0.0 : done / memberTasks.length;
                          final todayPoints = memberTasks
                              .fold<int>(0, (sum, task) => sum + task.pointsForApprovedMember(member.id));
                          return Card(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border(left: BorderSide(color: familyMemberColor(member), width: 5)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          MemberAvatar(member: member),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(member.name, style: Theme.of(context).textTheme.titleMedium),
                                                Text(strings.yearsRole(member.age, member.role.isAdmin)),
                                              ],
                                            ),
                                          ),
                                          Text('${(percent * 100).round()}%'),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      LinearProgressIndicator(value: percent),
                                      const SizedBox(height: 12),
                                      PointsRewardCard(
                                        points: member.points,
                                        pointValue: pointValue,
                                        label: strings.totalPoints,
                                        color: familyMemberColor(member),
                                        compact: true,
                                      ),
                                      const SizedBox(height: 10),
                                      Text('${strings.completed}: ${strings.doneOf(done, memberTasks.length)}'),
                                      Text('${strings.todayPoints}: ${strings.pointsAndMoney(todayPoints, pointValue)}'),
                                      const SizedBox(height: 8),
                                      Expanded(
                                        child: memberTasks.isEmpty
                                            ? Text(strings.noTasksToday)
                                            : ListView(
                                                physics: const NeverScrollableScrollPhysics(),
                                                children: [
                                                  for (final task in memberTasks.take(3))
                                                    Row(
                                                      children: [
                                                        Icon(task.status.icon, size: 18),
                                                        const SizedBox(width: 6),
                                                        Expanded(
                                                          child: Text(
                                                            task.title,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                      ],
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
                        },
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

  FamilyMember? _leader(List<FamilyMember> members, List<TaskItem> todayTasks) {
    FamilyMember? best;
    var bestDone = -1;
    for (final member in members) {
      final done = todayTasks.where((task) => task.isCompletedFor(member.id)).length;
      if (done > bestDone) {
        best = member;
        bestDone = done;
      }
    }
    return bestDone > 0 ? best : null;
  }
}
