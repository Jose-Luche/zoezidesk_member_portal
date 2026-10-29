import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/db/encrypted_cache.dart';
import '../../../data/dto/profile_dto.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../../shared/widgets/sync_status.dart';
import '../state/profile_providers.dart';
import '../widgets/member_avatar.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() => ref.read(profileRefreshProvider.notifier).refresh();

  @override
  Widget build(BuildContext context) {
    final cached = ref.watch(profileCacheProvider).value;
    final refresh = ref.watch(profileRefreshProvider);
    final now = ref.watch(clockProvider)();

    final Widget body;
    if (cached != null) {
      body = _ProfileContent(
        cached: cached,
        now: now,
        refreshing: refresh.isLoading,
        refreshError: refresh.error,
        onRefresh: _refresh,
      );
    } else if (refresh.hasError) {
      body = refresh.error is NetworkFailure
          ? StateMessage.offline(
              message: 'Connect to the internet once to load your profile. '
                  'After that it is available offline.',
              onAction: _refresh,
            )
          : StateMessage.error(onAction: _refresh);
    } else {
      body = const _ProfileSkeleton();
    }

    return Scaffold(
      appBar: AppTopBar(
        title: 'Profile',
        actions: [
          if (cached != null)
            IconButton(
              tooltip: 'Edit profile',
              icon: const AppIcon(AppIcons.pencil),
              onPressed: () => context.push(Routes.editProfile),
            ),
        ],
      ),
      body: body,
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({
    required this.cached,
    required this.now,
    required this.refreshing,
    required this.refreshError,
    required this.onRefresh,
  });

  final Cached<ProfileDto> cached;
  final DateTime now;
  final bool refreshing;
  final Object? refreshError;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final profile = cached.data;
    final m = profile.member;
    final gym = profile.gym;
    final text = Theme.of(context).textTheme;

    String? date(String? iso) {
      final d = DateTime.tryParse(iso ?? '');
      return d == null ? null : formatDate(d);
    }

    final gender = switch (m.gender) {
      'male' => 'Male',
      'female' => 'Female',
      'other' => 'Other',
      _ => null,
    };

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
        children: [
          SyncStatus(
            fetchedAt: cached.fetchedAt,
            now: now,
            refreshing: refreshing,
            refreshError: refreshError,
            onRetry: onRefresh,
          ),
          const SizedBox(height: AppSpace.lg),
          Row(
            children: [
              MemberAvatar(name: m.name, photoUrl: m.photoUrl),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(m.name, style: text.headlineMedium),
                    if (m.memberNumber != null) Text(m.memberNumber!, style: text.bodyMedium?.copyWith(color: context.palette.textMuted)),
                    const SizedBox(height: AppSpace.sm),
                    _MemberStatusBadge(status: m.status),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          _Section(title: 'Contact', rows: [
            _Row(AppIcons.phone, 'Phone', m.phone),
            _Row(AppIcons.mail, 'Email', m.email),
          ]),
          _Section(title: 'Personal', rows: [
            _Row(AppIcons.cake, 'Date of birth', date(m.dateOfBirth)),
            _Row(AppIcons.user, 'Gender', gender),
            _Row(AppIcons.calendarDays, 'Member since', date(m.memberSince)),
          ]),
          _Section(title: 'Emergency contact', rows: [
            _Row(AppIcons.contact, 'Name', m.emergencyContactName),
            _Row(AppIcons.phoneCall, 'Phone', m.emergencyContactPhone),
          ]),
          if (profile.memberships.isNotEmpty)
            _Section(
              title: 'Membership history',
              children: [for (final r in profile.memberships) _MembershipRow(r)],
            ),
          if (gym != null)
            _Section(title: gym.name, rows: [
              _Row(AppIcons.phone, 'Phone', gym.phone),
              _Row(AppIcons.mail, 'Email', gym.email),
              _Row(
                AppIcons.mapPin,
                'Address',
                [gym.address, gym.town].whereType<String>().where((s) => s.isNotEmpty).join(', '),
              ),
            ]),
          const InfoBanner(
            message: 'Name, phone number and photo can only be changed at the front desk.',
            icon: AppIcons.store,
          ),
        ],
      ),
    );
  }
}

class _MemberStatusBadge extends StatelessWidget {
  const _MemberStatusBadge({required this.status});

  final String? status;

  @override
  Widget build(BuildContext context) => switch (status) {
        'active' => const AppBadge(label: 'Active member', tone: BadgeTone.success, icon: AppIcons.circleCheck),
        'suspended' => const AppBadge(label: 'Suspended', tone: BadgeTone.danger, icon: AppIcons.circleAlert),
        'inactive' => const AppBadge(label: 'Inactive', tone: BadgeTone.neutral, icon: AppIcons.clock),
        _ => const SizedBox.shrink(),
      };
}

class _Row {
  const _Row(this.icon, this.label, this.value);

  final LucideIcon icon;
  final String label;
  final String? value;
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.rows = const [], this.children = const []});

  final String title;
  final List<_Row> rows;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final visible = rows.where((r) => r.value != null && r.value!.isNotEmpty).toList();
    if (visible.isEmpty && children.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(title),
          ListCard(
            children: [
              for (final r in visible)
                ListRow(
                  icon: r.icon,
                  title: r.label,
                  titleStyle: text.bodySmall,
                  subtitle: r.value,
                  selectableSubtitle: true,
                ),
              ...children,
            ],
          ),
        ],
      ),
    );
  }
}

class _MembershipRow extends StatelessWidget {
  const _MembershipRow(this.record);

  final MembershipRecord record;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final start = DateTime.tryParse(record.startsAtIso);
    final end = DateTime.tryParse(record.expiresAtIso);
    final range = [start, end].whereType<DateTime>().map(formatDate).join(' – ');

    final (label, tone, icon) = switch (record.status) {
      'active' when !record.lapsed => ('Active', BadgeTone.success, AppIcons.circleCheck),
      'active' || 'expired' => ('Expired', BadgeTone.neutral, AppIcons.clock),
      'pending' => ('Pending', BadgeTone.warning, AppIcons.clock),
      'suspended' => ('Suspended', BadgeTone.danger, AppIcons.circleAlert),
      'cancelled' => ('Cancelled', BadgeTone.neutral, AppIcons.x),
      _ => (record.status ?? '', BadgeTone.neutral, AppIcons.info),
    };

    return ListRow(
      icon: AppIcons.idCard,
      iconColor: context.palette.rowIcon,
      title: record.planName ?? 'Membership',
      titleStyle: text.titleSmall,
      subtitle: range,
      trailing: label.isEmpty ? null : AppBadge(label: label, tone: tone, icon: icon),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading profile',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.md),
        children: const [
          SizedBox(height: AppSpace.lg),
          Row(
            children: [
              SkeletonBox(width: AppSizes.avatar, height: AppSizes.avatar, radius: AppSizes.avatar),
              SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(width: 180, height: AppSpace.lg),
                    SizedBox(height: AppSpace.sm),
                    SkeletonBox(width: 96),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpace.lg),
          SkeletonListTile(),
          SizedBox(height: AppSpace.sm),
          SkeletonListTile(),
          SizedBox(height: AppSpace.sm),
          SkeletonListTile(),
        ],
      ),
    );
  }
}
