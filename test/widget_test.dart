import 'package:family_planner/src/l10n/app_strings.dart';
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
}
