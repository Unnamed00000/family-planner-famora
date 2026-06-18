import 'package:family_planner/src/l10n/app_strings.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('localizes app name in supported languages', () {
    expect(AppStrings(const Locale('ru')).appName, 'Семейный планировщик');
    expect(AppStrings(const Locale('da')).appName, 'Familieplan');
    expect(AppStrings(const Locale('en')).appName, 'Family Planner');
  });
}
