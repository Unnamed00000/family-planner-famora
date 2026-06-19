import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_models.dart';
import '../l10n/app_strings.dart';

final dateFormat = DateFormat('dd.MM.yyyy');
final timeFormat = DateFormat('HH:mm');

Color familyMemberColor(FamilyMember member) {
  final namedColor = _namedMemberColor(member.name);
  return namedColor ?? memberColor('${member.id}:${member.name}');
}

Color? _namedMemberColor(String name) {
  final lower = name.trim().toLowerCase();
  if (lower == 'адам' || lower == 'adam') {
    return const Color(0xFFC62828);
  }
  if (lower == 'самира' || lower == 'samira') {
    return const Color(0xFFE91E63);
  }
  if (lower == 'марьям' || lower == 'mariam' || lower == 'maryam') {
    return const Color(0xFFF9A825);
  }
  if (lower == 'мухаммед' || lower == 'muhammed' || lower == 'muhammad' || lower == 'mohammed') {
    return const Color(0xFF2E7D32);
  }
  if (lower == 'анас' || lower == 'anas') {
    return const Color(0xFF795548);
  }
  if (lower == 'иман' || lower == 'iman') {
    return const Color(0xFF03A9F4);
  }
  return null;
}

Color memberColor(String id) {
  const palette = [
    Color(0xFF00796B),
    Color(0xFFC62828),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFEF6C00),
    Color(0xFF2E7D32),
    Color(0xFFAD1457),
    Color(0xFF00838F),
    Color(0xFF4527A0),
    Color(0xFF9E9D24),
    Color(0xFFB71C1C),
    Color(0xFF0277BD),
    Color(0xFF558B2F),
    Color(0xFF8D6E63),
    Color(0xFF6D4C41),
    Color(0xFF455A64),
  ];
  var hash = 2166136261;
  for (final unit in id.codeUnits) {
    hash ^= unit;
    hash = (hash * 16777619) & 0x7fffffff;
  }
  return palette[hash % palette.length];
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 42, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(subtitle!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}

class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    required this.member,
    this.radius = 24,
    super.key,
  });

  final FamilyMember member;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final color = familyMemberColor(member);
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: member.photoUrl == null
          ? Center(
              child: Text(
                member.name.characters.first.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.w800),
              ),
            )
          : Transform.scale(
              scale: member.photoZoom.clamp(1, 2),
              child: Image.network(
                member.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Center(
                  child: Text(
                    member.name.characters.first.toUpperCase(),
                    style: TextStyle(color: color, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
    );
  }
}

class StatPill extends StatelessWidget {
  const StatPill({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colors.onSecondaryContainer),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: colors.onSecondaryContainer)),
          Text(value, style: TextStyle(color: colors.onSecondaryContainer, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class PointsRewardCard extends StatelessWidget {
  const PointsRewardCard({
    required this.points,
    required this.pointValue,
    required this.label,
    this.color,
    this.compact = false,
    super.key,
  });

  final int points;
  final double pointValue;
  final String label;
  final Color? color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = color ?? colors.tertiary;
    final money = strings.moneyForPoints(points, pointValue);
    return Container(
      width: compact ? null : double.infinity,
      padding: EdgeInsets.all(compact ? 10 : 14),
      decoration: BoxDecoration(
        color: Color.alphaBlend(accent.withValues(alpha: 0.10), colors.surface),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Container(
            width: compact ? 38 : 48,
            height: compact ? 38 : 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.stars_rounded, color: accent, size: compact ? 22 : 30),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  strings.pointsCount(points),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (compact ? theme.textTheme.titleMedium : theme.textTheme.headlineSmall)?.copyWith(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.payments_rounded, size: 15, color: colors.onPrimaryContainer),
                      const SizedBox(width: 5),
                      Text(
                        money,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AppFooter extends StatelessWidget {
  const AppFooter({
    this.compact = false,
    super.key,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 12, vertical: 6),
      child: Text(
        compact ? '${strings.creatorLine}\n${strings.appVersion}' : '${strings.creatorLine} · ${strings.appVersion}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colors.onSurfaceVariant,
              letterSpacing: 0,
            ),
      ),
    );
  }
}

class PageHelpAction extends StatelessWidget {
  const PageHelpAction({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return IconButton(
      tooltip: strings.help,
      icon: const Icon(Icons.help_outline_rounded),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (dialogContext) {
          final theme = Theme.of(dialogContext);
          final colors = theme.colorScheme;
          return AlertDialog(
            icon: CircleAvatar(
              backgroundColor: colors.primaryContainer,
              child: Icon(Icons.help_outline_rounded, color: colors.onPrimaryContainer),
            ),
            title: Text(title, textAlign: TextAlign.center),
            content: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                body,
                textAlign: TextAlign.start,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.35),
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(strings.close),
              ),
            ],
          );
        },
      ),
    );
  }
}

class TaskStatusChip extends StatelessWidget {
  const TaskStatusChip({required this.status, super.key});

  final TaskStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = switch (status) {
      TaskStatus.done => Colors.green,
      TaskStatus.overdue => Colors.red,
      TaskStatus.awaitingApproval => Colors.purple,
      TaskStatus.inProgress => Colors.orange,
      TaskStatus.pending => colors.primary,
    };
    return Chip(
      avatar: Icon(status.icon, size: 16, color: color),
      label: Text(AppStrings.of(context).taskStatus(status)),
      visualDensity: VisualDensity.compact,
    );
  }
}
