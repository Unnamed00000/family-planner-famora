import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../utils/week_number.dart';
import '../widgets/common.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    required this.familyRepository,
    required this.currentMember,
    super.key,
  });

  final FamilyRepository familyRepository;
  final FamilyMember? currentMember;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime focusedMonth = _monthKey(DateTime.now());
  late DateTime selectedDay = _dayKey(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.calendar),
        actions: [
          PageHelpAction(title: strings.calendar, body: strings.calendarHelp),
        ],
      ),
      body: StreamBuilder<List<FamilyMember>>(
        stream: widget.familyRepository.watchMembers(),
        builder: (context, memberSnapshot) {
          final memberList = memberSnapshot.data ?? [];
          final members = {for (final member in memberList) member.id: member};
          return StreamBuilder<List<TaskItem>>(
            stream: widget.familyRepository.watchTasks(),
            builder: (context, taskSnapshot) {
              final tasks = taskSnapshot.data ?? [];
              return StreamBuilder<List<ActivityItem>>(
                stream: widget.familyRepository.watchActivities(),
                builder: (context, activitySnapshot) {
                  final activities = activitySnapshot.data ?? [];
                  final groupedTasks = _groupTasks(tasks);
                  final groupedActivities = _groupActivities(activities);
                  final selectedTasks = groupedTasks[selectedDay] ?? <TaskItem>[];
                  final selectedActivities = groupedActivities[selectedDay] ?? <ActivityItem>[];
                  final isAdmin = widget.currentMember?.role.isAdmin == true;
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _MonthCalendar(
                        focusedMonth: focusedMonth,
                        selectedDay: selectedDay,
                        groupedTasks: groupedTasks,
                        groupedActivities: groupedActivities,
                        onPreviousMonth: () => setState(() {
                          focusedMonth = DateTime(focusedMonth.year, focusedMonth.month - 1);
                        }),
                        onNextMonth: () => setState(() {
                          focusedMonth = DateTime(focusedMonth.year, focusedMonth.month + 1);
                        }),
                        onSelectDay: (day) => setState(() {
                          selectedDay = day;
                          focusedMonth = _monthKey(day);
                        }),
                      ),
                      const SizedBox(height: 14),
                      if (isAdmin)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: memberList.isEmpty
                                  ? null
                                  : () => _createTaskForDay(context, selectedDay, memberList),
                              icon: const Icon(Icons.add_task_rounded),
                              label: Text(strings.createTask),
                            ),
                            OutlinedButton.icon(
                              onPressed: memberList.isEmpty
                                  ? null
                                  : () => _createActivityForDay(context, selectedDay, memberList),
                              icon: const Icon(Icons.sports_soccer_rounded),
                              label: Text(strings.createActivity),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Text(dateFormat.format(selectedDay), style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      if (selectedTasks.isEmpty && selectedActivities.isEmpty)
                        EmptyState(icon: Icons.event_available_rounded, title: strings.emptyCalendar)
                      else ...[
                        for (final activity in selectedActivities)
                          ..._activityTile(context, activity, members),
                        for (final task in selectedTasks)
                          Card(
                            child: ListTile(
                              leading: Icon(task.status.icon, color: task.priority.color),
                              title: Text(task.title),
                              subtitle: Text(
                                '${members[task.assignedToId]?.name ?? strings.noAssignee} - '
                                '${timeFormat.format(task.dueAt)}',
                              ),
                              trailing: TaskStatusChip(status: task.status),
                            ),
                          ),
                      ],
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

  List<Widget> _activityTile(
    BuildContext context,
    ActivityItem activity,
    Map<String, FamilyMember> members,
  ) {
    final strings = AppStrings.of(context);
    return [
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
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: activity.status == ActivityStatus.planned
                    ? () => widget.familyRepository.markActivityStatus(activity, ActivityStatus.accepted)
                    : null,
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: Text(strings.acceptActivity),
              ),
              OutlinedButton.icon(
                onPressed: activity.status == ActivityStatus.planned || activity.status == ActivityStatus.accepted
                    ? () => widget.familyRepository.markActivityStatus(activity, ActivityStatus.onWay)
                    : null,
                icon: const Icon(Icons.directions_walk_rounded),
                label: Text(strings.onWayActivity),
              ),
              FilledButton.icon(
                onPressed: activity.status == ActivityStatus.accepted || activity.status == ActivityStatus.onWay
                    ? () => widget.familyRepository.markActivityStatus(activity, ActivityStatus.completed)
                    : null,
                icon: const Icon(Icons.flag_rounded),
                label: Text(strings.finishActivity),
              ),
            ],
          ),
        ),
    ];
  }

  Future<void> _createTaskForDay(BuildContext context, DateTime day, List<FamilyMember> members) async {
    final strings = AppStrings.of(context);
    final title = TextEditingController();
    final description = TextEditingController();
    final points = TextEditingController(text: '5');
    final selectedIds = <String>{members.first.id};
    var dueAt = DateTime(day.year, day.month, day.day, DateTime.now().hour + 1, 0);
    var priority = TaskPriority.normal;
    var recurrence = TaskRecurrence.once;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(strings.newTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: InputDecoration(labelText: strings.title), autofocus: true),
                const SizedBox(height: 10),
                TextField(controller: description, decoration: InputDecoration(labelText: strings.description)),
                const SizedBox(height: 10),
                TextField(
                  controller: points,
                  decoration: InputDecoration(labelText: strings.points),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                _CalendarAssigneeSelector(
                  members: members,
                  selectedIds: selectedIds,
                  onChanged: (memberId, selected) => setDialogState(() {
                    if (selected) {
                      selectedIds.add(memberId);
                    } else if (selectedIds.length > 1) {
                      selectedIds.remove(memberId);
                    }
                  }),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: priority,
                  decoration: InputDecoration(labelText: strings.priority),
                  items: [
                    for (final item in TaskPriority.values)
                      DropdownMenuItem(value: item, child: Text(strings.taskPriority(item))),
                  ],
                  onChanged: (value) => setDialogState(() => priority = value ?? priority),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskRecurrence>(
                  initialValue: recurrence,
                  decoration: InputDecoration(labelText: strings.recurrence),
                  items: [
                    for (final item in TaskRecurrence.values)
                      DropdownMenuItem(value: item, child: Text(strings.taskRecurrence(item))),
                  ],
                  onChanged: (value) => setDialogState(() => recurrence = value ?? recurrence),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final time = await showTimePicker(context: dialogContext, initialTime: TimeOfDay.fromDateTime(dueAt));
                    if (time != null) {
                      setDialogState(() => dueAt = DateTime(day.year, day.month, day.day, time.hour, time.minute));
                    }
                  },
                  icon: const Icon(Icons.schedule_rounded),
                  label: Text('${dateFormat.format(day)} ${timeFormat.format(dueAt)}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(strings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(strings.save)),
          ],
        ),
      ),
    );
    if (saved != true || title.text.trim().isEmpty) {
      return;
    }
    for (final memberId in selectedIds) {
      await widget.familyRepository.saveTask(
        TaskItem(
          id: '',
          title: title.text.trim(),
          description: description.text.trim(),
          assignedToId: memberId,
          priority: priority,
          dueAt: dueAt,
          recurrence: recurrence,
          status: TaskStatus.pending,
          points: int.tryParse(points.text.trim()) ?? 5,
          createdBy: widget.currentMember?.id,
        ),
      );
    }
  }

  Future<void> _createActivityForDay(BuildContext context, DateTime day, List<FamilyMember> members) async {
    final strings = AppStrings.of(context);
    final title = TextEditingController();
    final description = TextEditingController();
    final location = TextEditingController();
    final selectedIds = <String>{members.first.id};
    var startAt = DateTime(day.year, day.month, day.day, DateTime.now().hour + 2, 0);
    var leaveAt = startAt.subtract(const Duration(minutes: 30));
    var endAt = startAt.add(const Duration(hours: 1));
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(strings.newActivity),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: InputDecoration(labelText: strings.title), autofocus: true),
                const SizedBox(height: 10),
                TextField(controller: description, decoration: InputDecoration(labelText: strings.description)),
                const SizedBox(height: 10),
                TextField(controller: location, decoration: InputDecoration(labelText: strings.location)),
                const SizedBox(height: 10),
                _CalendarAssigneeSelector(
                  members: members,
                  selectedIds: selectedIds,
                  onChanged: (memberId, selected) => setDialogState(() {
                    if (selected) {
                      selectedIds.add(memberId);
                    } else if (selectedIds.length > 1) {
                      selectedIds.remove(memberId);
                    }
                  }),
                ),
                const SizedBox(height: 10),
                _TimeButton(
                  label: strings.startTime,
                  value: startAt,
                  onPicked: (value) => setDialogState(() {
                    startAt = value;
                    if (!leaveAt.isBefore(startAt)) {
                      leaveAt = startAt.subtract(const Duration(minutes: 30));
                    }
                    if (!endAt.isAfter(startAt)) {
                      endAt = startAt.add(const Duration(hours: 1));
                    }
                  }),
                ),
                const SizedBox(height: 10),
                _TimeButton(
                  label: strings.leaveHomeTime,
                  value: leaveAt,
                  onPicked: (value) => setDialogState(() => leaveAt = value),
                ),
                const SizedBox(height: 10),
                _TimeButton(
                  label: strings.endTime,
                  value: endAt,
                  onPicked: (value) => setDialogState(() => endAt = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(strings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(strings.save)),
          ],
        ),
      ),
    );
    if (saved != true || title.text.trim().isEmpty) {
      return;
    }
    for (final memberId in selectedIds) {
      await widget.familyRepository.saveActivity(
        ActivityItem(
          id: '',
          title: title.text.trim(),
          description: description.text.trim(),
          assignedToId: memberId,
          startAt: startAt,
          leaveAt: leaveAt,
          endAt: endAt,
          status: ActivityStatus.planned,
          location: location.text.trim().isEmpty ? null : location.text.trim(),
          createdBy: widget.currentMember?.id,
        ),
      );
    }
  }

  bool _canUpdateActivity(ActivityItem activity) {
    final member = widget.currentMember;
    if (member == null) {
      return false;
    }
    return member.role.isAdmin || member.id == activity.assignedToId;
  }

  bool _isFinished(ActivityItem activity) {
    return activity.status == ActivityStatus.completed || activity.status == ActivityStatus.missed;
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.focusedMonth,
    required this.selectedDay,
    required this.groupedTasks,
    required this.groupedActivities,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDay,
  });

  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<DateTime, List<TaskItem>> groupedTasks;
  final Map<DateTime, List<ActivityItem>> groupedActivities;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final weeks = _calendarWeeks(focusedMonth);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(onPressed: onPreviousMonth, icon: const Icon(Icons.chevron_left_rounded)),
                Expanded(
                  child: Text(
                    _monthTitle(context, focusedMonth),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
                IconButton(onPressed: onNextMonth, icon: const Icon(Icons.chevron_right_rounded)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(
                      '№',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                for (final label in _weekdayLabels(context))
                  Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            for (final week in weeks)
              Row(
                children: [
                  SizedBox(
                    width: 40,
                    height: 48,
                    child: Center(
                      child: Text(
                        '${isoWeekNumber(week.firstWhere((day) => day != null)!)}',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  for (final day in week)
                    Expanded(
                      child: _CalendarDayCell(
                        day: day,
                        focusedMonth: focusedMonth,
                        selectedDay: selectedDay,
                        groupedTasks: groupedTasks,
                        groupedActivities: groupedActivities,
                        onSelectDay: onSelectDay,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.focusedMonth,
    required this.selectedDay,
    required this.groupedTasks,
    required this.groupedActivities,
    required this.onSelectDay,
  });

  final DateTime? day;
  final DateTime focusedMonth;
  final DateTime selectedDay;
  final Map<DateTime, List<TaskItem>> groupedTasks;
  final Map<DateTime, List<ActivityItem>> groupedActivities;
  final ValueChanged<DateTime> onSelectDay;

  @override
  Widget build(BuildContext context) {
    if (day == null) {
      return const SizedBox(height: 48);
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final key = _dayKey(day!);
    final hasEvents = (groupedTasks[key]?.isNotEmpty ?? false) || (groupedActivities[key]?.isNotEmpty ?? false);
    final selected = _sameDay(day!, selectedDay);
    final today = _sameDay(day!, DateTime.now());
    final outsideMonth = day!.month != focusedMonth.month;
    return Padding(
      padding: const EdgeInsets.all(3),
      child: SizedBox(
        height: 48,
        child: InkWell(
          onTap: outsideMonth ? null : () => onSelectDay(key),
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              color: selected
                  ? colors.primaryContainer
                  : today
                      ? colors.secondaryContainer.withValues(alpha: 0.55)
                      : colors.surfaceContainerHighest.withValues(alpha: outsideMonth ? 0.16 : 0.38),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    '${day!.day}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: outsideMonth
                          ? colors.onSurfaceVariant.withValues(alpha: 0.45)
                          : selected
                              ? colors.onPrimaryContainer
                              : colors.onSurface,
                    ),
                  ),
                ),
                if (hasEvents && !outsideMonth)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      width: 19,
                      height: 19,
                      decoration: BoxDecoration(
                        color: colors.error,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '!',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: colors.onError,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarAssigneeSelector extends StatelessWidget {
  const _CalendarAssigneeSelector({
    required this.members,
    required this.selectedIds,
    required this.onChanged,
  });

  final List<FamilyMember> members;
  final Set<String> selectedIds;
  final void Function(String memberId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: strings.assignee,
        prefixIcon: const Icon(Icons.group_rounded),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final member in members)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              secondary: MemberAvatar(member: member, radius: 16),
              title: Text(member.name),
              value: selectedIds.contains(member.id),
              activeColor: familyMemberColor(member),
              onChanged: (value) {
                if (selectedIds.length == 1 && selectedIds.contains(member.id) && value == false) {
                  return;
                }
                onChanged(member.id, value ?? false);
              },
            ),
        ],
      ),
    );
  }
}

class _TimeButton extends StatelessWidget {
  const _TimeButton({
    required this.label,
    required this.value,
    required this.onPicked,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onPicked;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
        if (time != null) {
          onPicked(DateTime(value.year, value.month, value.day, time.hour, time.minute));
        }
      },
      icon: const Icon(Icons.schedule_rounded),
      label: Text('$label: ${timeFormat.format(value)}'),
    );
  }
}

Map<DateTime, List<TaskItem>> _groupTasks(List<TaskItem> tasks) {
  final grouped = <DateTime, List<TaskItem>>{};
  for (final task in tasks) {
    grouped.putIfAbsent(_dayKey(task.dueAt), () => []).add(task);
  }
  for (final dayTasks in grouped.values) {
    dayTasks.sort((a, b) {
      final aCreated = a.createdAt ?? a.dueAt;
      final bCreated = b.createdAt ?? b.dueAt;
      return bCreated.compareTo(aCreated);
    });
  }
  return grouped;
}

Map<DateTime, List<ActivityItem>> _groupActivities(List<ActivityItem> activities) {
  final grouped = <DateTime, List<ActivityItem>>{};
  for (final activity in activities) {
    grouped.putIfAbsent(_dayKey(activity.startAt), () => []).add(activity);
  }
  for (final dayActivities in grouped.values) {
    dayActivities.sort((a, b) => b.startAt.compareTo(a.startAt));
  }
  return grouped;
}

String _monthTitle(BuildContext context, DateTime month) {
  final locale = Localizations.localeOf(context).languageCode;
  final names = switch (locale) {
    'ru' => const [
        'Январь',
        'Февраль',
        'Март',
        'Апрель',
        'Май',
        'Июнь',
        'Июль',
        'Август',
        'Сентябрь',
        'Октябрь',
        'Ноябрь',
        'Декабрь',
      ],
    'da' => const [
        'Januar',
        'Februar',
        'Marts',
        'April',
        'Maj',
        'Juni',
        'Juli',
        'August',
        'September',
        'Oktober',
        'November',
        'December',
      ],
    _ => const [
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
      ],
  };
  return '${names[month.month - 1]} ${month.year}';
}

List<String> _weekdayLabels(BuildContext context) {
  return switch (Localizations.localeOf(context).languageCode) {
    'ru' => const ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'],
    'da' => const ['Man', 'Tir', 'Ons', 'Tor', 'Fre', 'Lør', 'Søn'],
    _ => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  };
}

List<List<DateTime?>> _calendarWeeks(DateTime month) {
  final firstDay = DateTime(month.year, month.month);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final leadingEmptyDays = firstDay.weekday - 1;
  final cells = <DateTime?>[
    for (var i = 0; i < leadingEmptyDays; i++) null,
    for (var day = 1; day <= daysInMonth; day++) DateTime(month.year, month.month, day),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return [
    for (var index = 0; index < cells.length; index += 7) cells.sublist(index, index + 7),
  ];
}

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _monthKey(DateTime value) => DateTime(value.year, value.month);

DateTime _dayKey(DateTime value) => DateTime(value.year, value.month, value.day);
