import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../state/checkout_controller.dart';

/// Renew or buy a plan by M-Pesa: pick a plan, confirm the number, then
/// enter the PIN on the prompt. Online only.
class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(checkoutControllerProvider.notifier).load(),
    );
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(checkoutControllerProvider.select((s) => s.phase), (_, phase) {
      if (phase == CheckoutPhase.completed) HapticFeedback.mediumImpact();
    });
    ref.listen(checkoutControllerProvider.select((s) => s.phone), (_, phone) {
      if (_phone.text != phone) _phone.text = phone;
    });

    final state = ref.watch(checkoutControllerProvider);
    final controller = ref.read(checkoutControllerProvider.notifier);

    final Widget body = switch (state.options) {
      AsyncError(:final error) => error is NetworkFailure
          ? StateMessage.offline(
              message: 'Paying needs an internet connection. Connect and try again.',
              onAction: controller.load,
            )
          : StateMessage.error(onAction: controller.load),
      AsyncData(:final value) when !value.mpesaEnabled => const StateMessage(
          icon: AppIcons.store,
          title: 'Pay at the front desk',
          message: 'Your gym does not take M-Pesa in the app yet. The front desk can renew your membership.',
        ),
      AsyncData(:final value) when value.plans.isEmpty => const StateMessage(
          icon: AppIcons.store,
          title: 'No plans to buy here',
          message: 'Ask the front desk about plans for your membership.',
        ),
      AsyncData(:final value) => switch (state.phase) {
          CheckoutPhase.choosing || CheckoutPhase.sending => _Choose(
              options: value,
              state: state,
              phone: _phone,
            ),
          _ => _Progress(state: state),
        },
      _ => const _ChooseSkeleton(),
    };

    return Scaffold(
      appBar: const AppTopBar(title: 'Renew membership'),
      body: SafeArea(child: body),
    );
  }
}

class _Choose extends ConsumerWidget {
  const _Choose({required this.options, required this.state, required this.phone});

  final CheckoutOptions options;
  final CheckoutState state;
  final TextEditingController phone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final controller = ref.read(checkoutControllerProvider.notifier);
    final plan = state.plan;
    final today = DateUtils.dateOnly(ref.watch(clockProvider)());
    final current = options.currentExpiresAt;
    // Same rule as the server: a renewal starts the day after the current
    // membership ends; otherwise today.
    final starts = current != null && !current.isBefore(today)
        ? current.add(const Duration(days: 1))
        : today;
    final sending = state.phase == CheckoutPhase.sending;

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
      children: [
        if (options.currentPlanName != null && current != null) ...[
          InfoBanner(
            icon: AppIcons.idCard,
            message: 'Your ${options.currentPlanName} plan runs to ${formatDate(current)}. '
                'A renewal starts the day after.',
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        const SectionHeader('Choose a plan'),
        for (final p in options.plans)
          _PlanCard(
            plan: p,
            selected: p.id == state.planId,
            isCurrent: p.id == options.currentPlanId,
            onTap: sending ? null : () => controller.selectPlan(p.id),
          ),
        const SizedBox(height: AppSpace.lg),
        LabeledField(
          label: 'M-Pesa number',
          child: TextField(
            controller: phone,
            enabled: !sending,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
            onChanged: controller.setPhone,
            decoration: InputDecoration(
              helperText: 'The payment request is sent to this number.',
              errorText: state.phoneError,
              prefixIcon: const FieldIcon(AppIcons.smartphone),
            ),
          ),
        ),
        if (plan != null) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(
            icon: AppIcons.calendarDays,
            message: 'Membership from ${formatDate(starts)} to '
                '${formatDate(starts.add(Duration(days: plan.durationDays)))}.',
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(tone: BadgeTone.danger, message: state.error!),
        ],
        const SizedBox(height: AppSpace.lg),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
          onPressed: plan == null || sending ? null : controller.pay,
          child: Text(
            sending
                ? 'Sending request…'
                : plan == null
                ? 'Choose a plan'
                : 'Pay ${formatKes(plan.price)}',
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(
          'You will get an M-Pesa prompt on your phone. Enter your PIN to pay.',
          style: text.bodySmall,
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.isCurrent,
    this.onTap,
  });

  final PlanOption plan;
  final bool selected;
  final bool isCurrent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpace.sm),
        child: SelectableSurface(
          selected: selected,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.md),
            child: Row(
              children: [
                AppIcon(
                  selected ? AppIcons.circleDot : AppIcons.circle,
                  size: AppSizes.iconRow,
                  color: selected ? p.accentText : p.textMuted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(plan.name, style: text.titleSmall)),
                          if (isCurrent) ...[
                            const SizedBox(width: AppSpace.sm),
                            const AppBadge(label: 'Your plan', tone: BadgeTone.success, icon: AppIcons.circleCheck),
                          ],
                        ],
                      ),
                      if (plan.description != null) ...[
                        const SizedBox(height: AppSpace.xs),
                        Text(plan.description!, style: text.bodySmall),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(formatKes(plan.price), style: text.titleSmall),
                    Text(plan.durationLabel, style: text.bodySmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Waiting for the PIN, then the outcome.
class _Progress extends ConsumerWidget {
  const _Progress({required this.state});

  final CheckoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(checkoutControllerProvider.notifier);
    // Non-breaking spaces keep the number on one line.
    final phone = state.phone.isEmpty
        ? 'your phone'
        : formatLocalPhone(state.phone).replaceAll(' ', ' ');
    final amount = state.plan?.price ?? state.result?.amount;
    final result = state.result;

    final (icon, tone, title, message) = switch (state.phase) {
      CheckoutPhase.completed => (
          AppIcons.circleCheck,
          BadgeTone.success,
          'Payment received',
          [
            if (result?.receipt != null) 'M-Pesa receipt ${result!.receipt}.',
            if (result?.membershipExpiresAt != null)
              'Your ${result!.plan == null ? 'membership' : '${result.plan} plan'} runs from ${formatDate(result.membershipStartsAt!)} '
                  'to ${formatDate(result.membershipExpiresAt!)}.',
          ].join(' '),
        ),
      CheckoutPhase.failed => (
          AppIcons.circleAlert,
          BadgeTone.danger,
          'Payment not completed',
          '${_sentence(result?.failureReason ?? 'M-Pesa did not complete the payment')} You have not been charged.',
        ),
      CheckoutPhase.timedOut => (
          AppIcons.hourglass,
          BadgeTone.warning,
          'Still waiting for M-Pesa',
          'If you entered your PIN, the payment will show in your payments once M-Pesa confirms it. '
              'You will not be charged twice.',
        ),
      _ => (
          AppIcons.smartphone,
          BadgeTone.highlight,
          'Check your phone',
          'Enter your M-Pesa PIN on the prompt sent to $phone'
              '${amount != null ? ' to pay ${formatKes(amount)}' : ''}. '
              'This page updates when M-Pesa confirms.',
        ),
    };

    final p = context.palette;
    final (color, fill) = tone.badgeColors(p);
    final text = Theme.of(context).textTheme;
    const big = Size.fromHeight(AppSizes.sheetButton);

    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.lg),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: fill, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: AppIcon(icon, size: 32, color: color),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Semantics(
          liveRegion: true,
          child: Text(title, style: text.headlineMedium),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(message, style: text.bodyLarge),
        const SizedBox(height: AppSpace.xl),
        ...switch (state.phase) {
          CheckoutPhase.completed => [
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: big),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Done'),
              ),
            ],
          CheckoutPhase.failed => [
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: big),
                onPressed: controller.startOver,
                child: const Text('Try again'),
              ),
            ],
          CheckoutPhase.timedOut => [
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: big),
                onPressed: state.checking ? null : controller.checkAgain,
                child: Text(state.checking ? 'Checking…' : 'Check again'),
              ),
              const SizedBox(height: AppSpace.sm),
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: big),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          _ => [
              OutlinedButton(
                style: OutlinedButton.styleFrom(minimumSize: big),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Closing does not cancel the request. The payment will show in your payments.',
                style: text.bodySmall,
              ),
            ],
        },
      ],
    );
  }
}

class _ChooseSkeleton extends StatelessWidget {
  const _ChooseSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.md),
    child: Column(
      children: [
        SkeletonListTile(),
        SizedBox(height: AppSpace.sm),
        SkeletonListTile(),
        SizedBox(height: AppSpace.sm),
        SkeletonListTile(),
      ],
    ),
  );
}

/// Safaricom's reasons come without a full stop ("Request cancelled by user").
String _sentence(String s) {
  final t = s.trim();
  return t.endsWith('.') ? t : '$t.';
}
