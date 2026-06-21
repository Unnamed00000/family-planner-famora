import 'package:family_planner/src/l10n/app_strings.dart';
import 'package:family_planner/src/models/app_models.dart';
import 'package:family_planner/src/utils/photo_url.dart';
import 'package:family_planner/src/utils/week_number.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizes app name in supported languages', () {
    expect(AppStrings(const Locale('ru')).appName, 'Семейный планировщик');
    expect(AppStrings(const Locale('da')).appName, 'Familieplan');
    expect(AppStrings(const Locale('en')).appName, 'Family Planner');
  });

  test('normalizes GitHub photo links to raw image URLs', () {
    expect(
      normalizePhotoUrl('https://github.com/Unnamed00000/family-planner-famora/blob/main/Profile%20photos/Samira.jpg'),
      'https://raw.githubusercontent.com/Unnamed00000/family-planner-famora/main/Profile%20photos/Samira.jpg',
    );
    expect(
      normalizePhotoUrl(
        '[Samira.jpg](https://github.com/Unnamed00000/family-planner-famora/blob/main/Profile%20photos/Samira.jpg)',
      ),
      'https://raw.githubusercontent.com/Unnamed00000/family-planner-famora/main/Profile%20photos/Samira.jpg',
    );
  });

  test('uses ISO week 25 for 19 June 2026', () {
    expect(isoWeekNumber(DateTime(2026, 6, 15)), 25);
    expect(isoWeekNumber(DateTime(2026, 6, 19)), 25);
    expect(isoWeekNumber(DateTime(2026, 6, 22)), 26);
  });

  test('recognizes an unassigned task as open', () {
    final task = TaskItem(
      id: 'task-1',
      title: 'Open task',
      description: '',
      assignedToId: '',
      priority: TaskPriority.normal,
      dueAt: DateTime(2026, 6, 21),
      recurrence: TaskRecurrence.once,
      status: TaskStatus.pending,
      points: 5,
    );

    expect(task.isOpenTask, isTrue);
  });

  test('splits task points between approved participants', () {
    final task = TaskItem(
      id: 'task-2',
      title: 'Shared task',
      description: '',
      assignedToId: '',
      priority: TaskPriority.normal,
      dueAt: DateTime(2026, 6, 21),
      recurrence: TaskRecurrence.once,
      status: TaskStatus.done,
      points: 50,
      participantLimit: 2,
      participantIds: const ['samira', 'maryam'],
      completedBy: const ['samira', 'maryam'],
      approvedBy: const ['samira', 'maryam'],
    );

    expect(task.isReadyForPayout, isTrue);
    expect(task.pointsForApprovedMember('samira'), 25);
    expect(task.pointsForApprovedMember('maryam'), 25);
  });
}
