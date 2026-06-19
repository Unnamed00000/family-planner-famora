import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../models/app_models.dart';
import '../services/firebase_service.dart';
import '../utils/photo_url.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    required this.authRepository,
    required this.familyRepository,
    required this.currentMember,
    required this.locale,
    required this.onLocaleChanged,
    required this.onThemeModeChanged,
    super.key,
  });

  final AuthRepository authRepository;
  final FamilyRepository familyRepository;
  final FamilyMember? currentMember;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final ValueChanged<ThemeMode> onThemeModeChanged;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final member = currentMember;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.profile),
        actions: [
          PageHelpAction(title: strings.profile, body: strings.profileHelp),
          IconButton(
            tooltip: strings.logout,
            onPressed: authRepository.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: member == null
          ? _ClaimProfile(familyRepository: familyRepository)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Center(child: MemberAvatar(member: member, radius: 54)),
                const SizedBox(height: 12),
                Center(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _uploadOwnPhoto(context, member),
                        icon: const Icon(Icons.photo_camera_rounded),
                        label: Text(strings.uploadOwnPhoto),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _setPhotoLink(context, member),
                        icon: const Icon(Icons.link_rounded),
                        label: Text(strings.usePhotoLink),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  member.name,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  strings.yearsRole(member.age, member.role.isAdmin),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                StreamBuilder<AppSettings>(
                  stream: familyRepository.watchAppSettings(),
                  builder: (context, settingsSnapshot) {
                    final pointValue = settingsSnapshot.data?.pointValueDkk ?? 1;
                    return PointsRewardCard(
                      points: member.points,
                      pointValue: pointValue,
                      label: strings.totalPoints,
                      color: familyMemberColor(member),
                    );
                  },
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.appearance, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: Icon(
                            member.themeMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                          ),
                          title: Text(member.themeMode == ThemeMode.dark ? strings.darkTheme : strings.lightTheme),
                          value: member.themeMode == ThemeMode.dark,
                          onChanged: (value) {
                            final mode = value ? ThemeMode.dark : ThemeMode.light;
                            onThemeModeChanged(mode);
                            familyRepository.updateMemberPreferences(member.id, themeMode: mode);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.chooseLanguage, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<Locale>(
                          initialValue: locale,
                          decoration: InputDecoration(
                            labelText: strings.chooseLanguage,
                            prefixIcon: const Icon(Icons.language_rounded),
                          ),
                          items: [
                            for (final item in AppStrings.supportedLocales)
                              DropdownMenuItem(
                                value: item,
                                child: Text(AppStrings.languageNames[item.languageCode] ?? item.languageCode),
                              ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              onLocaleChanged(value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.soundAndVibration, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.volume_up_rounded),
                          title: Text(strings.notificationSound),
                          value: member.soundEnabled,
                          onChanged: (value) => familyRepository.updateMemberPreferences(member.id, soundEnabled: value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          secondary: const Icon(Icons.vibration_rounded),
                          title: Text(strings.notificationVibration),
                          value: member.vibrationEnabled,
                          onChanged: (value) => familyRepository.updateMemberPreferences(member.id, vibrationEnabled: value),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    StatPill(icon: Icons.check_circle_rounded, label: strings.completed, value: member.completedTasks.toString()),
                    StatPill(icon: Icons.cancel_rounded, label: strings.missed, value: member.missedTasks.toString()),
                    StatPill(icon: Icons.leaderboard_rounded, label: strings.rating, value: member.rating.toString()),
                  ],
                ),
                const SizedBox(height: 22),
                Text(strings.achievements, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                if (member.achievements.isEmpty)
                  Text(strings.noAchievements)
                else
                  for (final achievement in member.achievements)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.workspace_premium_rounded),
                        title: Text(strings.achievementLabel(achievement)),
                      ),
                    ),
              ],
            ),
    );
  }

  Future<void> _uploadOwnPhoto(BuildContext context, FamilyMember member) async {
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
                        await familyRepository.uploadMemberPhoto(
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
            title: Text(strings.photoLink),
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
    await familyRepository.updateMemberPhotoUrl(
      member.id,
      controller.text.trim(),
      photoZoom: zoom,
    );
  }
}

class _ClaimProfile extends StatelessWidget {
  const _ClaimProfile({required this.familyRepository});

  final FamilyRepository familyRepository;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FamilyMember>>(
      stream: familyRepository.watchMembers(),
      builder: (context, snapshot) {
        final unclaimed = (snapshot.data ?? []).where((member) => member.authUid == null || member.authUid!.isEmpty).toList();
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            EmptyState(
              icon: Icons.person_search_rounded,
              title: AppStrings.of(context).profileNotLinked,
              subtitle: AppStrings.of(context).chooseProfileToLink,
            ),
            for (final member in unclaimed)
              Card(
                child: ListTile(
                  leading: MemberAvatar(member: member),
                  title: Text(member.name),
                  subtitle: Text(member.localLogin ?? member.email ?? ''),
                  trailing: FilledButton(
                    onPressed: () => familyRepository.claimMemberProfile(member.id),
                    child: Text(AppStrings.of(context).thisIsMe),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
