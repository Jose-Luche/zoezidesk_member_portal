import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/theme_mode_controller.dart';
import '../../shared/widgets/app_badge.dart';
import '../../shared/widgets/app_sheet.dart';
import '../../shared/widgets/app_top_bar.dart';
import '../../shared/widgets/info_banner.dart';
import '../../shared/widgets/skeleton.dart';
import '../../shared/widgets/state_message.dart';
import '../../shared/widgets/surfaces.dart';

/// Debug-only review screen for the design system (see design.md).
class DesignGalleryScreen extends StatelessWidget {
  const DesignGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: const AppTopBar(title: 'Design system', actions: [_ThemeToggle()]),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.xxl),
        children: [
          const SectionHeader('Typography'),
          Text('Headline large 30', style: text.headlineLarge),
          Text('Headline small 23', style: text.headlineSmall),
          Text('Title large 21', style: text.titleLarge),
          Text('Title medium, Figtree 700', style: text.titleMedium),
          Text('Title small 600, in the accent', style: text.titleSmall?.copyWith(color: context.palette.accentText)),
          Text('Body medium 15, the default body size.', style: text.bodyMedium),
          Text('Body small 13, muted', style: text.bodySmall),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Buttons'),
          FilledButton(onPressed: () {}, child: const Text('Book class')),
          const SizedBox(height: AppSpace.sm),
          OutlinedButton(onPressed: () {}, child: const Text('View schedule')),
          const SizedBox(height: AppSpace.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: () {}, child: const Text('See all payments')),
          ),
          const SizedBox(height: AppSpace.sm),
          const FilledButton(onPressed: null, child: Text('Disabled')),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Badges and chips'),
          const Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppBadge(label: 'Booked', tone: BadgeTone.success, icon: AppIcons.circleCheck),
              AppBadge(label: '9 this month', icon: AppIcons.calendar),
              AppBadge(label: 'Pending', tone: BadgeTone.neutral, icon: AppIcons.clock),
              AppBadge(label: 'Failed', tone: BadgeTone.danger, icon: AppIcons.circleAlert),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              FilterChip(label: const Text('My bookings'), selected: true, onSelected: (_) {}),
              FilterChip(label: const Text('Chest'), selected: false, onSelected: (_) {}),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Banners'),
          const InfoBanner(icon: AppIcons.scanLine, message: 'Show this code at the front desk.'),
          const SizedBox(height: AppSpace.sm),
          const InfoBanner(tone: BadgeTone.warning, icon: AppIcons.refreshCw, message: '1 change is waiting to be sent.'),
          const SizedBox(height: AppSpace.sm),
          const InfoBanner(tone: BadgeTone.success, message: 'Checked in at 6:02 PM.'),
          const SizedBox(height: AppSpace.sm),
          InfoBanner(
            tone: BadgeTone.danger,
            message: 'Your membership has expired.',
            actionLabel: 'Renew',
            onAction: () {},
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Inputs'),
          const LabeledField(
            label: 'Phone number',
            child: TextField(
              decoration: InputDecoration(hintText: '0712 345 678', prefixIcon: FieldIcon(AppIcons.phone)),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const LabeledField(
            label: 'Code',
            child: TextField(decoration: InputDecoration(errorText: 'The code must be 6 digits.')),
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('List card'),
          ListCard(
            children: [
              ListRow(icon: AppIcons.dumbbell, title: 'HIIT Blast', subtitle: 'Mon 6:00 PM · 4 spots left', onTap: () {}),
              ListRow(icon: AppIcons.receipt, title: 'Payments', onTap: () {}),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Skeleton'),
          const SkeletonListTile(),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('States'),
          SurfaceCard(padding: EdgeInsets.zero, child: StateMessage.offline(onAction: () {})),
          const SizedBox(height: AppSpace.lg),
          const SectionHeader('Bottom sheet'),
          OutlinedButton(
            onPressed: () => showAppSheet<void>(
              context,
              builder: (sheet) => SheetLayout(
                title: 'Confirm booking',
                body: [Text('HIIT Blast, Monday 6:00 PM', style: Theme.of(sheet).textTheme.bodyLarge)],
                actions: [
                  FilledButton(onPressed: () => Navigator.pop(sheet), child: const Text('Confirm')),
                  OutlinedButton(onPressed: () => Navigator.pop(sheet), child: const Text('Not now')),
                ],
              ),
            ),
            child: const Text('Open bottom sheet'),
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      tooltip: isDark ? 'Switch to light theme' : 'Switch to dark theme',
      icon: AppIcon(isDark ? AppIcons.sun : AppIcons.moon),
      onPressed: () => ref
          .read(themeModeProvider.notifier)
          .set(isDark ? ThemeMode.light : ThemeMode.dark),
    );
  }
}
