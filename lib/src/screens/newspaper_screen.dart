import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class NewspaperScreen extends StatelessWidget {
  const NewspaperScreen({
    required this.familyRepository,
    super.key,
  });

  final FamilyRepository familyRepository;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.newspaper)),
      body: StreamBuilder<List<FamilyMember>>(
        stream: familyRepository.watchMembers(),
        builder: (context, memberSnapshot) {
          final members = memberSnapshot.data ?? [];
          return StreamBuilder<List<TaskItem>>(
            stream: familyRepository.watchTasks(),
            builder: (context, taskSnapshot) {
              final tasks = taskSnapshot.data ?? [];
              final today = tasks.where((task) => task.isToday).toList();
              final weekStart = DateTime.now().subtract(const Duration(days: 7));
              final week = tasks.where((task) => task.dueAt.isAfter(weekStart)).toList();
              final dayWinner = _winner(members, today);
              final weekWinner = _winner(members, week);
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _Section(
                    title: strings.daySummary,
                    children: [
                      StatPill(
                        icon: Icons.emoji_events_rounded,
                        label: strings.mostTasks,
                        value: dayWinner?.name ?? strings.noneYet,
                      ),
                      StatPill(
                        icon: Icons.local_fire_department_rounded,
                        label: strings.mostActive,
                        value: dayWinner?.name ?? strings.noneYet,
                      ),
                      StatPill(
                        icon: Icons.check_circle_rounded,
                        label: strings.wholeFamily,
                        value: today.where((task) => task.isDone).length.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: strings.weekSummary,
                    children: [
                      StatPill(
                        icon: Icons.workspace_premium_rounded,
                        label: strings.bestHelper,
                        value: weekWinner?.name ?? strings.noneYet,
                      ),
                      StatPill(
                        icon: Icons.verified_rounded,
                        label: strings.mostResponsible,
                        value: weekWinner?.name ?? strings.noneYet,
                      ),
                      StatPill(
                        icon: Icons.bar_chart_rounded,
                        label: strings.doneThisWeek,
                        value: week.where((task) => task.isDone).length.toString(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(strings.announcements, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  StreamBuilder<List<Announcement>>(
                    stream: familyRepository.watchAnnouncements(),
                    builder: (context, announcementSnapshot) {
                      final announcements = announcementSnapshot.data ?? [];
                      if (announcements.isEmpty) {
                        return EmptyState(
                          icon: Icons.campaign_rounded,
                          title: strings.noAnnouncements,
                        );
                      }
                      return Column(
                        children: [
                          for (final announcement in announcements)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Card(
                                child: ListTile(
                                  leading: const Icon(Icons.campaign_rounded),
                                  title: Text(announcement.title),
                                  subtitle: Text('${announcement.body}\n${dateFormat.format(announcement.createdAt)}'),
                                  isThreeLine: true,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  FamilyMember? _winner(List<FamilyMember> members, List<TaskItem> tasks) {
    FamilyMember? best;
    var count = 0;
    for (final member in members) {
      final done = tasks.where((task) => task.isCompletedFor(member.id)).length;
      if (done > count) {
        count = done;
        best = member;
      }
    }
    return best;
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(spacing: 10, runSpacing: 10, children: children),
      ],
    );
  }
}
