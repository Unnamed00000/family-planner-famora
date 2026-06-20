import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../utils/photo_url.dart';
import '../widgets/common.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({
    required this.familyRepository,
    required this.currentMember,
    super.key,
  });

  final FamilyRepository familyRepository;
  final FamilyMember? currentMember;

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late final TabController tabController = TabController(length: 5, vsync: this);

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.management),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelPadding: const EdgeInsets.symmetric(horizontal: 14),
          tabs: [
            Tab(icon: const Icon(Icons.group_rounded), text: strings.members),
            Tab(icon: const Icon(Icons.add_task_rounded), text: strings.taskTab),
            Tab(icon: const Icon(Icons.sports_soccer_rounded), text: strings.activityTab),
            Tab(icon: const Icon(Icons.campaign_rounded), text: strings.announcements),
            Tab(icon: const Icon(Icons.history_rounded), text: strings.history),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: [
          _MembersAdmin(repository: widget.familyRepository),
          _TasksAdmin(repository: widget.familyRepository, currentMember: widget.currentMember),
          _ActivitiesAdmin(repository: widget.familyRepository, currentMember: widget.currentMember),
          _AnnouncementsAdmin(repository: widget.familyRepository),
          _HistoryAdmin(repository: widget.familyRepository),
        ],
      ),
    );
  }
}

class _ActivitiesAdmin extends StatelessWidget {
  const _ActivitiesAdmin({
    required this.repository,
    required this.currentMember,
  });

  final FamilyRepository repository;
  final FamilyMember? currentMember;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return StreamBuilder<List<FamilyMember>>(
      stream: repository.watchMembers(),
      builder: (context, memberSnapshot) {
        final members = memberSnapshot.data ?? [];
        final membersById = {for (final member in members) member.id: member};
        return StreamBuilder<List<ActivityItem>>(
          stream: repository.watchActivities(),
          builder: (context, activitySnapshot) {
            final activities = activitySnapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: members.isEmpty ? null : () => _editActivity(context, members, null),
                  icon: const Icon(Icons.sports_soccer_rounded),
                  label: Text(strings.createActivity),
                ),
                const SizedBox(height: 12),
                for (final activity in activities)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_available_rounded),
                      title: Text(activity.title),
                      subtitle: Text(
                        '${membersById[activity.assignedToId]?.name ?? strings.noAssignee} - '
                        '${dateFormat.format(activity.startAt)} ${timeFormat.format(activity.startAt)}\n'
                        '${strings.leaveHomeTime}: ${timeFormat.format(activity.leaveAt)}  '
                        '${strings.status}: ${strings.activityStatus(activity.status)}',
                      ),
                      isThreeLine: true,
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: strings.edit,
                            onPressed: () => _editActivity(context, members, activity),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: strings.delete,
                            onPressed: () => repository.deleteActivity(activity.id),
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editActivity(BuildContext context, List<FamilyMember> members, ActivityItem? activity) async {
    final strings = AppStrings.of(context);
    final title = TextEditingController(text: activity?.title ?? '');
    final description = TextEditingController(text: activity?.description ?? '');
    final location = TextEditingController(text: activity?.location ?? '');
    final selectedAssigneeIds = <String>{activity?.assignedToId ?? members.first.id};
    var startAt = activity?.startAt ?? DateTime.now().add(const Duration(hours: 2));
    var leaveAt = activity?.leaveAt ?? startAt.subtract(const Duration(minutes: 30));
    var endAt = activity?.endAt ?? startAt.add(const Duration(hours: 1));
    var status = activity?.status ?? ActivityStatus.planned;

    Future<DateTime?> pickDateTime(DateTime initial) async {
      final date = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime.now().subtract(const Duration(days: 30)),
        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
      );
      if (date == null || !context.mounted) {
        return null;
      }
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
      if (time == null) {
        return null;
      }
      return DateTime(date.year, date.month, date.day, time.hour, time.minute);
    }

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(activity == null ? strings.newActivity : strings.editActivity),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: InputDecoration(labelText: strings.title)),
                const SizedBox(height: 10),
                TextField(controller: description, decoration: InputDecoration(labelText: strings.description)),
                const SizedBox(height: 10),
                TextField(controller: location, decoration: InputDecoration(labelText: strings.location)),
                const SizedBox(height: 10),
                _AssigneeSelector(
                  members: members,
                  selectedIds: selectedAssigneeIds,
                  onChanged: (memberId, selected) {
                    setState(() {
                      if (selected) {
                        selectedAssigneeIds.add(memberId);
                      } else if (selectedAssigneeIds.length > 1) {
                        selectedAssigneeIds.remove(memberId);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await pickDateTime(startAt);
                    if (selected == null) {
                      return;
                    }
                    setState(() {
                      startAt = selected;
                      if (!leaveAt.isBefore(startAt)) {
                        leaveAt = startAt.subtract(const Duration(minutes: 30));
                      }
                      if (!endAt.isAfter(startAt)) {
                        endAt = startAt.add(const Duration(hours: 1));
                      }
                    });
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text('${strings.startTime}: ${dateFormat.format(startAt)} ${timeFormat.format(startAt)}'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await pickDateTime(endAt);
                    if (selected == null) {
                      return;
                    }
                    setState(() => endAt = selected);
                  },
                  icon: const Icon(Icons.flag_rounded),
                  label: Text('${strings.endTime}: ${dateFormat.format(endAt)} ${timeFormat.format(endAt)}'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final selected = await pickDateTime(leaveAt);
                    if (selected == null) {
                      return;
                    }
                    setState(() => leaveAt = selected);
                  },
                  icon: const Icon(Icons.directions_walk_rounded),
                  label: Text('${strings.leaveHomeTime}: ${dateFormat.format(leaveAt)} ${timeFormat.format(leaveAt)}'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<ActivityStatus>(
                  initialValue: status,
                  decoration: InputDecoration(labelText: strings.status),
                  items: [
                    for (final item in ActivityStatus.values)
                      DropdownMenuItem(value: item, child: Text(strings.activityStatus(item))),
                  ],
                  onChanged: (value) => setState(() => status = value ?? status),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.save)),
          ],
        ),
      ),
    );
    if (saved != true) {
      return;
    }
    final assigneeIds = selectedAssigneeIds.toList();
    for (var index = 0; index < assigneeIds.length; index++) {
      await repository.saveActivity(
        ActivityItem(
          id: index == 0 ? activity?.id ?? '' : '',
          title: title.text.trim(),
          description: description.text.trim(),
          assignedToId: assigneeIds[index],
          startAt: startAt,
          leaveAt: leaveAt,
          endAt: endAt,
          status: status,
          location: location.text.trim().isEmpty ? null : location.text.trim(),
          createdBy: activity?.createdBy ?? currentMember?.id,
          createdAt: index == 0 ? activity?.createdAt : null,
        ),
      );
    }
  }
}

class _MembersAdmin extends StatelessWidget {
  const _MembersAdmin({required this.repository});

  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Scaffold(
      body: StreamBuilder<List<FamilyMember>>(
        stream: repository.watchMembers(),
        builder: (context, snapshot) {
          final members = snapshot.data ?? [];
          return StreamBuilder<AppSettings>(
            stream: repository.watchAppSettings(),
            builder: (context, settingsSnapshot) {
              final pointValue = settingsSnapshot.data?.pointValueDkk ?? 1;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  FilledButton.icon(
                    onPressed: () => _editMember(context, null),
                    icon: const Icon(Icons.person_add_rounded),
                    label: Text(strings.addMember),
                  ),
                  const SizedBox(height: 12),
                  _PointValueCard(repository: repository),
                  const SizedBox(height: 12),
                  for (final member in members)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                MemberAvatar(member: member),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(member.name, style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 2),
                                      Text('${member.age} - ${member.localLogin ?? member.email ?? ''}'),
                                      const SizedBox(height: 2),
                                      Text(
                                        strings.pointsAndMoney(member.points, pointValue),
                                        style: Theme.of(context).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Divider(height: 1),
                            const SizedBox(height: 4),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                children: [
                                  IconButton(
                                    tooltip: strings.editPoints,
                                    onPressed: () => _editMemberPoints(context, member, pointValue),
                                    icon: const Icon(Icons.stars_rounded),
                                  ),
                                  IconButton(
                                    tooltip: strings.photo,
                                    onPressed: () => _uploadPhoto(context, member),
                                    icon: const Icon(Icons.photo_camera_rounded),
                                  ),
                                  IconButton(
                                    tooltip: strings.usePhotoLink,
                                    onPressed: () => _setPhotoLink(context, member),
                                    icon: const Icon(Icons.link_rounded),
                                  ),
                                  IconButton(
                                    tooltip: strings.edit,
                                    onPressed: () => _editMember(context, member),
                                    icon: const Icon(Icons.edit_rounded),
                                  ),
                                  IconButton(
                                    tooltip: strings.delete,
                                    onPressed: () => repository.deleteMember(member.id),
                                    icon: const Icon(Icons.delete_rounded),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _editMemberPoints(BuildContext context, FamilyMember member, double pointValue) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: member.points.toString());
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${strings.editPoints}: ${member.name}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: strings.pointsBalance,
            helperText: strings.moneyForPoints(member.points, pointValue),
            prefixIcon: const Icon(Icons.stars_rounded),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.save)),
        ],
      ),
    );
    if (saved != true) {
      return;
    }
    await repository.setMemberPoints(member.id, int.tryParse(controller.text.trim()) ?? member.points);
  }

  Future<void> _uploadPhoto(BuildContext context, FamilyMember member) async {
    final strings = AppStrings.of(context);
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (image == null) {
      return;
    }
    final bytes = await image.readAsBytes();
    if (!context.mounted) {
      return;
    }
    var zoom = member.photoZoom;
    var progress = 0.0;
    var uploading = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(strings.choosePhotoFraming),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: familyMemberColor(member), width: 3),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Transform.scale(
                    scale: zoom,
                    child: Image.memory(bytes, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: zoom,
                  min: 1,
                  max: 2,
                  divisions: 10,
                  label: zoom.toStringAsFixed(1),
                  onChanged: uploading ? null : (value) => setDialogState(() => zoom = value),
                ),
                Text(strings.photoZoom),
                if (uploading) ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: progress == 0 ? null : progress),
                  const SizedBox(height: 6),
                  Text('${strings.uploadProgress}: ${(progress * 100).round()}%'),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: uploading ? null : () => Navigator.pop(dialogContext),
              child: Text(strings.cancel),
            ),
            FilledButton(
              onPressed: uploading
                  ? null
                  : () async {
                      setDialogState(() => uploading = true);
                      try {
                        await repository.uploadMemberPhoto(
                          member.id,
                          bytes,
                          image.mimeType ?? 'image/jpeg',
                          photoZoom: zoom,
                          onProgress: (value) {
                            if (dialogContext.mounted) {
                              setDialogState(() => progress = value);
                            }
                          },
                        );
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (error) {
                        if (dialogContext.mounted) {
                          setDialogState(() => uploading = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      }
                    },
              child: Text(strings.save),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setPhotoLink(BuildContext context, FamilyMember member) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: member.photoUrl ?? '');
    var zoom = member.photoZoom.clamp(1, 2).toDouble();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          final previewUrl = normalizePhotoUrl(controller.text);
          return AlertDialog(
            title: Text('${strings.photoLink}: ${member.name}'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: familyMemberColor(member), width: 3),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: previewUrl.isEmpty
                        ? Center(
                            child: Icon(
                              Icons.person_rounded,
                              size: 72,
                              color: familyMemberColor(member),
                            ),
                          )
                        : Transform.scale(
                            scale: zoom,
                            child: Image.network(
                              previewUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  Icons.broken_image_rounded,
                                  size: 64,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: strings.photoLink,
                      helperText: strings.photoLinkHelp,
                      prefixIcon: const Icon(Icons.link_rounded),
                    ),
                    onChanged: (_) => setDialogState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Slider(
                    value: zoom,
                    min: 1,
                    max: 2,
                    divisions: 10,
                    label: zoom.toStringAsFixed(1),
                    onChanged: (value) => setDialogState(() => zoom = value),
                  ),
                  Text(strings.photoZoom),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(strings.cancel)),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(strings.save)),
            ],
          );
        },
      ),
    );
    if (saved != true) {
      return;
    }
    await repository.updateMemberPhotoUrl(
      member.id,
      controller.text.trim(),
      photoZoom: zoom,
    );
  }

  Future<void> _editMember(BuildContext context, FamilyMember? member) async {
    final strings = AppStrings.of(context);
    final name = TextEditingController(text: member?.name ?? '');
    final age = TextEditingController(text: member?.age.toString() ?? '');
    final email = TextEditingController(text: member?.email ?? '');
    final password = TextEditingController();
    final login = TextEditingController(text: member?.localLogin ?? '');
    final points = TextEditingController(text: (member?.points ?? 0).toString());
    final photoUrl = TextEditingController(text: member?.photoUrl ?? '');
    var role = member?.role ?? UserRole.member;
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(member == null ? strings.newMember : strings.editMember),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: name, decoration: InputDecoration(labelText: strings.name)),
                const SizedBox(height: 10),
                TextField(controller: age, decoration: InputDecoration(labelText: strings.age), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                TextField(controller: email, decoration: InputDecoration(labelText: strings.accountEmail)),
                const SizedBox(height: 10),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: strings.temporaryPassword,
                    helperText: strings.leavePasswordBlank,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(controller: login, decoration: InputDecoration(labelText: strings.familyLogin)),
                const SizedBox(height: 10),
                TextField(
                  controller: points,
                  decoration: InputDecoration(labelText: strings.pointsBalance),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: photoUrl,
                  decoration: InputDecoration(
                    labelText: strings.photoLink,
                    helperText: strings.photoLinkHelp,
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<UserRole>(
                  initialValue: role,
                  decoration: InputDecoration(labelText: strings.role),
                  items: [
                    DropdownMenuItem(value: UserRole.member, child: Text(strings.normalUser)),
                    DropdownMenuItem(value: UserRole.admin, child: Text(strings.administrator)),
                  ],
                  onChanged: (value) => setState(() => role = value ?? UserRole.member),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.save)),
          ],
        ),
      ),
    );
    if (saved != true) {
      return;
    }
    var authUid = member?.authUid;
    final cleanEmail = email.text.trim();
    final cleanPassword = password.text.trim();
    if (authUid == null && cleanEmail.isNotEmpty && cleanPassword.isNotEmpty) {
      try {
        authUid = await repository.createAuthAccount(
          email: cleanEmail,
          password: cleanPassword,
        );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
        return;
      }
    }
    await repository.saveMember(
      FamilyMember(
        id: member?.id ?? authUid ?? '',
        name: name.text.trim(),
        age: int.tryParse(age.text) ?? 0,
        role: role,
        completedTasks: member?.completedTasks ?? 0,
        missedTasks: member?.missedTasks ?? 0,
        points: int.tryParse(points.text.trim()) ?? member?.points ?? 0,
        authUid: authUid,
        email: cleanEmail.isEmpty ? null : cleanEmail,
        localLogin: login.text.trim().isEmpty ? null : login.text.trim().toLowerCase(),
        photoUrl: normalizePhotoUrl(photoUrl.text).isEmpty ? null : normalizePhotoUrl(photoUrl.text),
        photoZoom: member?.photoZoom ?? 1,
        themeMode: member?.themeMode ?? ThemeMode.system,
        soundEnabled: member?.soundEnabled ?? true,
        vibrationEnabled: member?.vibrationEnabled ?? true,
        createdAt: member?.createdAt,
      ),
    );
  }
}

class _PointValueCard extends StatelessWidget {
  const _PointValueCard({required this.repository});

  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return StreamBuilder<AppSettings>(
      stream: repository.watchAppSettings(),
      builder: (context, snapshot) {
        final controller = TextEditingController(text: (snapshot.data?.pointValueDkk ?? 1).toStringAsFixed(2));
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(strings.pointValueDkk, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.payments_rounded), labelText: strings.pointValueDkk),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () {
                    final value = double.tryParse(controller.text.replaceAll(',', '.'));
                    if (value != null && value >= 0) {
                      repository.savePointValueDkk(value);
                    }
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: Text(strings.savePointValue),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TasksAdmin extends StatelessWidget {
  const _TasksAdmin({
    required this.repository,
    required this.currentMember,
  });

  final FamilyRepository repository;
  final FamilyMember? currentMember;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return StreamBuilder<List<FamilyMember>>(
      stream: repository.watchMembers(),
      builder: (context, memberSnapshot) {
        final members = memberSnapshot.data ?? [];
        final membersById = {for (final member in members) member.id: member};
        return StreamBuilder<List<TaskItem>>(
          stream: repository.watchTasks(),
          builder: (context, taskSnapshot) {
            final tasks = taskSnapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                FilledButton.icon(
                  onPressed: members.isEmpty ? null : () => _editTask(context, members, null),
                  icon: const Icon(Icons.add_task_rounded),
                  label: Text(strings.createTask),
                ),
                const SizedBox(height: 12),
                for (final task in tasks)
                  Card(
                    child: ListTile(
                      leading: Icon(task.status.icon, color: task.priority.color),
                      title: Text(task.title),
                      subtitle: Text(
                        '${membersById[task.assignedToId]?.name ?? strings.noAssignee} - '
                        '${dateFormat.format(task.dueAt)} ${timeFormat.format(task.dueAt)}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: strings.edit,
                            onPressed: () => _editTask(context, members, task),
                            icon: const Icon(Icons.edit_rounded),
                          ),
                          IconButton(
                            tooltip: strings.delete,
                            onPressed: () => repository.deleteTask(task.id),
                            icon: const Icon(Icons.delete_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _editTask(BuildContext context, List<FamilyMember> members, TaskItem? task) async {
    final strings = AppStrings.of(context);
    final title = TextEditingController(text: task?.title ?? '');
    final description = TextEditingController(text: task?.description ?? '');
    final points = TextEditingController(text: (task?.points ?? 5).toString());
    final selectedAssigneeIds = <String>{task?.assignedToId ?? members.first.id};
    var priority = task?.priority ?? TaskPriority.normal;
    var recurrence = task?.recurrence ?? TaskRecurrence.once;
    var status = task?.status ?? TaskStatus.pending;
    var dueAt = task?.dueAt ?? DateTime.now().add(const Duration(hours: 2));
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(task == null ? strings.newTask : strings.editTask),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: title, decoration: InputDecoration(labelText: strings.title)),
                const SizedBox(height: 10),
                TextField(controller: description, decoration: InputDecoration(labelText: strings.description)),
                const SizedBox(height: 10),
                TextField(controller: points, decoration: InputDecoration(labelText: strings.points), keyboardType: TextInputType.number),
                const SizedBox(height: 10),
                _AssigneeSelector(
                  members: members,
                  selectedIds: selectedAssigneeIds,
                  onChanged: (memberId, selected) {
                    setState(() {
                      if (selected) {
                        selectedAssigneeIds.add(memberId);
                      } else if (selectedAssigneeIds.length > 1) {
                        selectedAssigneeIds.remove(memberId);
                      }
                    });
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskPriority>(
                  initialValue: priority,
                  decoration: InputDecoration(labelText: strings.priority),
                  items: [
                    for (final item in TaskPriority.values) DropdownMenuItem(value: item, child: Text(strings.taskPriority(item))),
                  ],
                  onChanged: (value) => setState(() => priority = value ?? priority),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskRecurrence>(
                  initialValue: recurrence,
                  decoration: InputDecoration(labelText: strings.recurrence),
                  items: [
                    for (final item in TaskRecurrence.values) DropdownMenuItem(value: item, child: Text(strings.taskRecurrence(item))),
                  ],
                  onChanged: (value) => setState(() => recurrence = value ?? recurrence),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<TaskStatus>(
                  initialValue: status,
                  decoration: InputDecoration(labelText: strings.status),
                  items: [
                    for (final item in TaskStatus.values) DropdownMenuItem(value: item, child: Text(strings.taskStatus(item))),
                  ],
                  onChanged: (value) => setState(() => status = value ?? status),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dueAt,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (date == null || !context.mounted) {
                      return;
                    }
                    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(dueAt));
                    if (time == null) {
                      return;
                    }
                    setState(() {
                      dueAt = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                    });
                  },
                  icon: const Icon(Icons.event_rounded),
                  label: Text('${dateFormat.format(dueAt)} ${timeFormat.format(dueAt)}'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.save)),
          ],
        ),
      ),
    );
    if (saved != true) {
      return;
    }
    final assigneeIds = selectedAssigneeIds.toList();
    for (var index = 0; index < assigneeIds.length; index++) {
      await repository.saveTask(
        TaskItem(
          id: index == 0 ? task?.id ?? '' : '',
          title: title.text.trim(),
          description: description.text.trim(),
          assignedToId: assigneeIds[index],
          priority: priority,
          dueAt: dueAt,
          recurrence: recurrence,
          status: status,
          points: int.tryParse(points.text) ?? 5,
          createdBy: task?.createdBy ?? currentMember?.id,
          createdAt: index == 0 ? task?.createdAt : null,
        ),
      );
    }
  }
}

class _AssigneeSelector extends StatelessWidget {
  const _AssigneeSelector({
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

class _AnnouncementsAdmin extends StatelessWidget {
  const _AnnouncementsAdmin({required this.repository});

  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return StreamBuilder<List<Announcement>>(
      stream: repository.watchAnnouncements(),
      builder: (context, snapshot) {
        final announcements = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _editAnnouncement(context, null),
              icon: const Icon(Icons.campaign_rounded),
              label: Text(strings.newAnnouncement),
            ),
            const SizedBox(height: 12),
            if (announcements.isEmpty)
              EmptyState(icon: Icons.campaign_rounded, title: strings.noAnnouncements)
            else
              for (final announcement in announcements)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.campaign_rounded),
                    title: Text(announcement.title),
                    subtitle: Text(
                      '${announcement.body}\n${dateFormat.format(announcement.createdAt)} ${timeFormat.format(announcement.createdAt)}',
                    ),
                    isThreeLine: true,
                    trailing: Wrap(
                      children: [
                        IconButton(
                          tooltip: strings.edit,
                          onPressed: () => _editAnnouncement(context, announcement),
                          icon: const Icon(Icons.edit_rounded),
                        ),
                        IconButton(
                          tooltip: strings.delete,
                          onPressed: () => repository.deleteAnnouncement(announcement.id),
                          icon: const Icon(Icons.delete_rounded),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  Future<void> _editAnnouncement(BuildContext context, Announcement? announcement) async {
    final strings = AppStrings.of(context);
    final title = TextEditingController(text: announcement?.title ?? '');
    final body = TextEditingController(text: announcement?.body ?? '');
    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(announcement == null ? strings.newAnnouncement : strings.editAnnouncement),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: title, decoration: InputDecoration(labelText: strings.title)),
              const SizedBox(height: 10),
              TextField(
                controller: body,
                decoration: InputDecoration(labelText: strings.message),
                minLines: 3,
                maxLines: 6,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(strings.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(strings.save)),
        ],
      ),
    );
    if (saved != true || title.text.trim().isEmpty || body.text.trim().isEmpty) {
      return;
    }
    await repository.saveAnnouncement(
      Announcement(
        id: announcement?.id ?? '',
        title: title.text.trim(),
        body: body.text.trim(),
        createdBy: announcement?.createdBy,
        createdAt: announcement?.createdAt ?? DateTime.now(),
        updatedAt: announcement?.updatedAt,
      ),
    );
  }
}

class _HistoryAdmin extends StatelessWidget {
  const _HistoryAdmin({required this.repository});

  final FamilyRepository repository;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return StreamBuilder<List<HistoryEntry>>(
      stream: repository.watchHistory(),
      builder: (context, snapshot) {
        final entries = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            FilledButton.icon(
              onPressed: () => _showBackup(context),
              icon: const Icon(Icons.backup_rounded),
              label: Text(strings.createJsonBackup),
            ),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              EmptyState(icon: Icons.history_rounded, title: strings.historyEmpty)
            else
              ...[
                for (final entry in entries)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.history_rounded),
                      title: Text('${entry.action} - ${entry.entity}'),
                      subtitle:
                          Text('${entry.details ?? ''}\n${dateFormat.format(entry.createdAt)} ${timeFormat.format(entry.createdAt)}'),
                      isThreeLine: true,
                    ),
                  ),
              ],
          ],
        );
      },
    );
  }

  Future<void> _showBackup(BuildContext context) async {
    final backup = await repository.exportBackup();
    if (!context.mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppStrings.of(context).backup),
        content: SizedBox(
          width: 700,
          child: SingleChildScrollView(
            child: SelectableText(const JsonEncoder.withIndent('  ').convert(backup)),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppStrings.of(context).close),
          ),
        ],
      ),
    );
  }
}
