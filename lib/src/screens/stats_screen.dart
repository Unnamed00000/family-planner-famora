import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({
    required this.familyRepository,
    super.key,
  });

  final FamilyRepository familyRepository;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.stats),
        actions: [
          PageHelpAction(title: strings.stats, body: strings.statsHelp),
        ],
      ),
      body: StreamBuilder<List<FamilyMember>>(
        stream: familyRepository.watchMembers(),
        builder: (context, memberSnapshot) {
          final members = memberSnapshot.data ?? [];
          return StreamBuilder<List<TaskItem>>(
            stream: familyRepository.watchTasks(),
            builder: (context, taskSnapshot) {
              final tasks = taskSnapshot.data ?? [];
              return StreamBuilder<List<ActivityItem>>(
                stream: familyRepository.watchActivities(),
                builder: (context, activitySnapshot) {
                  final activities = activitySnapshot.data ?? [];
                  final done = tasks.where((task) => task.isDone).length;
                  final missed = tasks.where((task) => task.status == TaskStatus.overdue).length;
                  final percent = tasks.isEmpty ? 0 : ((done / tasks.length) * 100).round();
                  final todayActivities = activities.where(_isTodayActivity).toList();
                  final todayMinutes = todayActivities.fold<int>(0, (sum, activity) => sum + activity.durationMinutes);
                  final memberRows = [
                    for (final member in members) _MemberStats(member: member, tasks: tasks, activities: activities),
                  ]..sort((a, b) => b.rating.compareTo(a.rating));
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
                          StatPill(icon: Icons.check_circle_rounded, label: strings.completed, value: done.toString()),
                          StatPill(icon: Icons.cancel_rounded, label: strings.missed, value: missed.toString()),
                          StatPill(icon: Icons.percent_rounded, label: strings.percent, value: '$percent%'),
                          StatPill(
                            icon: Icons.timer_rounded,
                            label: strings.dailyActivityTime,
                            value: strings.activityDuration(todayMinutes),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(strings.taskStatsCalculated),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: () => _exportPdf(memberRows, tasks, activities),
                        icon: const Icon(Icons.picture_as_pdf_rounded),
                        label: Text(strings.exportPdf),
                      ),
                      const SizedBox(height: 18),
                      _ChartCard(
                        title: strings.chart7Days,
                        members: members,
                        tasks: tasks,
                        range: const Duration(days: 7),
                      ),
                      const SizedBox(height: 12),
                      _ChartCard(
                        title: strings.chart30Days,
                        members: members,
                        tasks: tasks,
                        range: const Duration(days: 30),
                      ),
                      const SizedBox(height: 18),
                      Text(strings.activityTimeByMember, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      for (final row in memberRows)
                        Card(
                          child: ListTile(
                            leading: MemberAvatar(member: row.member),
                            title: Text(row.member.name),
                            subtitle: Text(strings.activityDuration(row.todayActivityMinutes)),
                            trailing: Text(row.activityTitlesToday.join(', ')),
                          ),
                        ),
                      const SizedBox(height: 18),
                      Text(strings.familyRating, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      for (final row in memberRows)
                        Card(
                          child: ListTile(
                            leading: MemberAvatar(member: row.member),
                            title: Text(row.member.name),
                            subtitle: Text(
                              '${strings.memberStats(row.doneTasks, row.missedTasks)}\n'
                              '${strings.pointsAndMoney(row.points, pointValue)}',
                            ),
                            isThreeLine: true,
                            trailing: Text('${row.rating}'),
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

  bool _isTodayActivity(ActivityItem activity) {
    final now = DateTime.now();
    return activity.startAt.year == now.year && activity.startAt.month == now.month && activity.startAt.day == now.day;
  }

  Future<void> _exportPdf(List<_MemberStats> rows, List<TaskItem> tasks, List<ActivityItem> activities) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, text: 'Family Planner Statistics'),
          pw.Text('Completed tasks: ${tasks.where((task) => task.isDone).length}'),
          pw.Text('Missed tasks: ${tasks.where((task) => task.status == TaskStatus.overdue).length}'),
          pw.Text('Activity minutes today: ${activities.where(_isTodayActivity).fold<int>(0, (sum, activity) => sum + activity.durationMinutes)}'),
          pw.SizedBox(height: 16),
          pw.TableHelper.fromTextArray(
            headers: ['Member', 'Completed', 'Missed', 'Points', 'Rating', 'Activity minutes today'],
            data: [
              for (final row in rows)
                [
                  row.member.name,
                  row.doneTasks.toString(),
                  row.missedTasks.toString(),
                  row.points.toString(),
                  row.rating.toString(),
                  row.todayActivityMinutes.toString(),
                ],
            ],
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (_) async => doc.save());
  }
}

class _MemberStats {
  _MemberStats({
    required this.member,
    required List<TaskItem> tasks,
    required List<ActivityItem> activities,
  })  : doneTasks = tasks.where((task) => task.assignedToId == member.id && task.isDone).length,
        missedTasks = tasks.where((task) => task.assignedToId == member.id && task.status == TaskStatus.overdue).length,
        points = member.points,
        todayActivityMinutes = activities
            .where((activity) => activity.assignedToId == member.id && _isToday(activity))
            .fold<int>(0, (sum, activity) => sum + activity.durationMinutes),
        activityTitlesToday = activities
            .where((activity) => activity.assignedToId == member.id && _isToday(activity))
            .map((activity) => activity.title)
            .toList();

  final FamilyMember member;
  final int doneTasks;
  final int missedTasks;
  final int points;
  final int todayActivityMinutes;
  final List<String> activityTitlesToday;

  int get rating => points + doneTasks * 2 - missedTasks * 3;

  static bool _isToday(ActivityItem activity) {
    final now = DateTime.now();
    return activity.startAt.year == now.year && activity.startAt.month == now.month && activity.startAt.day == now.day;
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.members,
    required this.tasks,
    required this.range,
  });

  final String title;
  final List<FamilyMember> members;
  final List<TaskItem> tasks;
  final Duration range;

  @override
  Widget build(BuildContext context) {
    final memberLines = [
      for (final member in members) _MemberLine(member: member, spots: _spotsForMember(member)),
    ].where((line) => line.spots.any((spot) => spot.y > 0)).toList();
    final maxY = memberLines
        .expand((line) => line.spots)
        .fold<double>(0, (max, spot) => spot.y > max ? spot.y : max)
        .clamp(1, double.infinity)
        .toDouble();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY + 1,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    for (final line in memberLines)
                      LineChartBarData(
                        spots: line.spots,
                        color: familyMemberColor(line.member),
                        isCurved: true,
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final line in memberLines)
                  _LegendItem(member: line.member),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _spotsForMember(FamilyMember member) {
    final now = DateTime.now();
    final days = range.inDays;
    return [
      for (var i = days - 1; i >= 0; i--)
        FlSpot(
          (days - i).toDouble(),
          tasks
              .where((task) {
                final day = now.subtract(Duration(days: i));
                return task.assignedToId == member.id &&
                    task.isDone &&
                    task.dueAt.year == day.year &&
                    task.dueAt.month == day.month &&
                    task.dueAt.day == day.day;
              })
              .length
              .toDouble(),
        ),
    ];
  }
}

class _MemberLine {
  const _MemberLine({
    required this.member,
    required this.spots,
  });

  final FamilyMember member;
  final List<FlSpot> spots;
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final color = familyMemberColor(member);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(member.name),
      ],
    );
  }
}
