import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/browser_notifier.dart';
import '../services/device_feedback.dart';
import '../services/firebase_service.dart';
import '../widgets/common.dart';
import 'admin_screen.dart';
import 'calendar_screen.dart';
import 'family_board_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';
import 'tasks_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({
    required this.authRepository,
    required this.familyRepository,
    required this.locale,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    super.key,
  });

  final AuthRepository authRepository;
  final FamilyRepository familyRepository;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  static int lastIndex = 0;
  late int index = lastIndex;
  String? tokenSavedForMemberId;
  String? themeAppliedForMemberId;
  FamilyMember? feedbackMember;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return StreamBuilder<FamilyMember?>(
      stream: widget.familyRepository.watchCurrentMember(),
      builder: (context, memberSnapshot) {
        final currentMember = memberSnapshot.data;
        feedbackMember = currentMember;
        if (currentMember != null && tokenSavedForMemberId != currentMember.id) {
          tokenSavedForMemberId = currentMember.id;
          widget.familyRepository.savePushToken(currentMember);
        }
        if (currentMember != null && themeAppliedForMemberId != currentMember.id) {
          themeAppliedForMemberId = currentMember.id;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.onThemeModeChanged(currentMember.themeMode);
          });
        }
        final destinations = [
          NavigationDestination(icon: const Icon(Icons.home_rounded), label: strings.home),
          NavigationDestination(icon: const Icon(Icons.dashboard_rounded), label: strings.board),
          NavigationDestination(icon: const Icon(Icons.checklist_rounded), label: strings.tasks),
          NavigationDestination(icon: const Icon(Icons.calendar_month_rounded), label: strings.calendar),
          NavigationDestination(icon: const Icon(Icons.bar_chart_rounded), label: strings.stats),
          NavigationDestination(icon: const Icon(Icons.person_rounded), label: strings.profile),
          if (currentMember?.role.isAdmin ?? false)
            NavigationDestination(icon: const Icon(Icons.admin_panel_settings_rounded), label: strings.admin),
        ];
        final pages = [
          HomeScreen(familyRepository: widget.familyRepository),
          FamilyBoardScreen(familyRepository: widget.familyRepository, currentMember: currentMember),
          TasksScreen(familyRepository: widget.familyRepository, currentMember: currentMember),
          CalendarScreen(
            familyRepository: widget.familyRepository,
            currentMember: currentMember,
          ),
          StatsScreen(familyRepository: widget.familyRepository),
          ProfileScreen(
            authRepository: widget.authRepository,
            familyRepository: widget.familyRepository,
            currentMember: currentMember,
            locale: widget.locale,
            onLocaleChanged: widget.onLocaleChanged,
            onThemeModeChanged: widget.onThemeModeChanged,
          ),
          if (currentMember?.role.isAdmin ?? false)
            AdminScreen(familyRepository: widget.familyRepository, currentMember: currentMember),
        ];
        final safeIndex = index.clamp(0, pages.length - 1).toInt();
        lastIndex = safeIndex;
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (wide) {
              return Scaffold(
                body: Row(
                  children: [
                    SizedBox(
                      width: 112,
                      child: Column(
                        children: [
                          Expanded(
                            child: NavigationRail(
                              selectedIndex: safeIndex,
                              onDestinationSelected: _selectIndex,
                              labelType: NavigationRailLabelType.all,
                              destinations: [
                                for (final destination in destinations)
                                  NavigationRailDestination(
                                    icon: destination.icon,
                                    label: Text(destination.label),
                                  ),
                              ],
                            ),
                          ),
                          const AppFooter(compact: true),
                        ],
                      ),
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: _TapFeedbackLayer(
                        currentMember: currentMember,
                        child: Stack(
                          children: [
                            pages[safeIndex],
                            if (currentMember != null)
                              _ActivityReminderWatcher(
                                familyRepository: widget.familyRepository,
                                currentMember: currentMember,
                              ),
                            if (currentMember != null)
                              _NotificationWatcher(
                                familyRepository: widget.familyRepository,
                                currentMember: currentMember,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            return Scaffold(
              body: _TapFeedbackLayer(
                currentMember: currentMember,
                child: Stack(
                  children: [
                    pages[safeIndex],
                    if (currentMember != null)
                      _ActivityReminderWatcher(
                        familyRepository: widget.familyRepository,
                        currentMember: currentMember,
                      ),
                    if (currentMember != null)
                      _NotificationWatcher(
                        familyRepository: widget.familyRepository,
                        currentMember: currentMember,
                      ),
                  ],
                ),
              ),
              bottomNavigationBar: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BottomNavigationBar(
                    currentIndex: safeIndex,
                    onTap: (value) {
                      final member = feedbackMember;
                      if (member != null) {
                        try {
                          playTapFeedback(
                            soundEnabled: member.soundEnabled,
                            vibrationEnabled: member.vibrationEnabled,
                          );
                        } catch (_) {}
                      }
                      lastIndex = value;
                      setState(() => index = value);
                    },
                    type: BottomNavigationBarType.fixed,
                    showUnselectedLabels: true,
                    items: [
                      for (final destination in destinations)
                        BottomNavigationBarItem(
                          icon: destination.icon,
                          label: destination.label,
                        ),
                    ],
                  ),
                  const AppFooter(),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _selectIndex(int value) {
    final member = feedbackMember;
    if (member != null) {
      playTapFeedback(
        soundEnabled: member.soundEnabled,
        vibrationEnabled: member.vibrationEnabled,
      );
    }
    lastIndex = value;
    setState(() => index = value);
  }
}

class _TapFeedbackLayer extends StatefulWidget {
  const _TapFeedbackLayer({
    required this.currentMember,
    required this.child,
  });

  final FamilyMember? currentMember;
  final Widget child;

  @override
  State<_TapFeedbackLayer> createState() => _TapFeedbackLayerState();
}

class _TapFeedbackLayerState extends State<_TapFeedbackLayer> {
  Offset? pointerDownPosition;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) => pointerDownPosition = event.position,
      onPointerUp: (event) {
        final start = pointerDownPosition;
        pointerDownPosition = null;
        if (start != null && (event.position - start).distance > 12) {
          return;
        }
        final member = widget.currentMember;
        if (member == null) {
          return;
        }
        playTapFeedback(
          soundEnabled: member.soundEnabled,
          vibrationEnabled: member.vibrationEnabled,
        );
      },
      child: widget.child,
    );
  }
}

class _NotificationWatcher extends StatefulWidget {
  const _NotificationWatcher({
    required this.familyRepository,
    required this.currentMember,
  });

  final FamilyRepository familyRepository;
  final FamilyMember currentMember;

  @override
  State<_NotificationWatcher> createState() => _NotificationWatcherState();
}

class _NotificationWatcherState extends State<_NotificationWatcher> {
  final seenIds = <String>{};
  var firstSnapshot = true;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyNotification>>(
      stream: widget.familyRepository.watchNotifications(),
      builder: (context, snapshot) {
        final notifications = (snapshot.data ?? [])
            .where((item) => item.assignedToId == widget.currentMember.id && !item.isAccepted)
            .toList();
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (final notification in notifications) {
            if (firstSnapshot) {
              seenIds.add(notification.id);
              continue;
            }
            if (seenIds.add(notification.id)) {
              showBrowserNotification(title: notification.title, body: notification.body);
              _playAlert(widget.currentMember);
            }
          }
          firstSnapshot = false;
        });
        return const SizedBox.shrink();
      },
    );
  }
}

class _ActivityReminderWatcher extends StatefulWidget {
  const _ActivityReminderWatcher({
    required this.familyRepository,
    required this.currentMember,
  });

  final FamilyRepository familyRepository;
  final FamilyMember currentMember;

  @override
  State<_ActivityReminderWatcher> createState() => _ActivityReminderWatcherState();
}

class _ActivityReminderWatcherState extends State<_ActivityReminderWatcher> {
  final notifiedIds = <String>{};
  List<ActivityItem> activities = [];
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(minutes: 1), (_) => _checkReminders());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityItem>>(
      stream: widget.familyRepository.watchActivitiesForMember(widget.currentMember.id),
      builder: (context, snapshot) {
        activities = snapshot.data ?? [];
        WidgetsBinding.instance.addPostFrameCallback((_) => _checkReminders());
        return const SizedBox.shrink();
      },
    );
  }

  void _checkReminders() {
    if (!mounted) {
      return;
    }
    final strings = AppStrings.of(context);
    final now = DateTime.now();
    for (final activity in activities) {
      final dueToLeave = !activity.leaveAt.isAfter(now);
      final stillRelevant = activity.startAt.isAfter(now.subtract(const Duration(minutes: 5)));
      if (dueToLeave && stillRelevant && notifiedIds.add(activity.id)) {
        showBrowserNotification(
          title: strings.leaveNow,
          body: strings.activityReminder(activity.title),
        );
        _playAlert(widget.currentMember);
      }
    }
  }
}

void _playAlert(FamilyMember member) {
  if (member.soundEnabled) {
    SystemSound.play(SystemSoundType.alert);
  }
  if (member.vibrationEnabled) {
    HapticFeedback.vibrate();
  }
}
