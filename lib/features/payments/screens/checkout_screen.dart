import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/checkout_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
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
          icon: Icons.storefront_rounded,
          title: 'Pay at the front desk',
          message: 'Your gym does not take M-Pesa in the app yet. The front desk can renew your membership.',
        ),
      AsyncData(:final value) when value.plans.isEmpty => const StateMessage(
          icon: Icons.storefront_rounded,
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
      appBar: AppBar(title: const Text('Renew membership')),
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
      padding: const EdgeInsets.all(AppSpace.md),
      children: [
        if (options.currentPlanName != null && current != null) ...[
          InfoBanner(
            icon: Icons.card_membership_rounded,
            message: 'Your ${options.currentPlanName} plan runs to ${formatDate(current)}. '
                'A renewal starts the day after.',
          ),
          const SizedBox(height: AppSpace.md),
        ],
        Text('Choose a plan', style: text.titleLarge),
        const SizedBox(height: AppSpace.sm),
        for (final p in options.plans)
          _PlanCard(
            plan: p,
            selected: p.id == state.planId,
            isCurrent: p.id == options.currentPlanId,
            onTap: sending ? null : () => controller.selectPlan(p.id),
          ),
        const SizedBox(height: AppSpace.md),
        TextField(
          controller: phone,
          enabled: !sending,
          keyboardType: TextInputType.phone,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]'))],
          onChanged: controller.setPhone,
          decoration: InputDecoration(
            labelText: 'M-Pesa number',
            helperText: 'The payment request is sent to this number.',
            errorText: state.phoneError,
            prefixIcon: const Icon(Icons.phone_android_rounded),
          ),
        ),
        if (plan != null) ...[
          const SizedBox(height: AppSpace.md),
          Text(
            'Membership from ${formatDate(starts)} to '
            '${formatDate(starts.add(Duration(days: plan.durationDays)))}.',
            style: text.bodyMedium,
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(tone: BadgeTone.danger, message: state.error!),
        ],
        const SizedBox(height: AppSpace.lg),
        FilledButton(
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
          textAlign: TextAlign.center,
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
      child: Card(
        margin: const EdgeInsets.only(bottom: AppSpace.sm),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: selected ? p.accentText : p.border, width: selected ? 2 : 1),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: selected ? p.accentText : p.textMuted,
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(plan.name, style: text.titleSmall)),
                          if (isCurrent) ...[
                            const SizedBox(width: AppSpace.sm),
                            const AppBadge(label: 'Your plan', tone: BadgeTone.neutral),
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
          Icons.check_circle_rounded,
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
          Icons.error_outline_rounded,
          BadgeTone.danger,
          'Payment not completed',
          '${_sentence(result?.failureReason ?? 'M-Pesa did not complete the payment')} You have not been charged.',
        ),
      CheckoutPhase.timedOut => (
          Icons.hourglass_bottom_rounded,
          BadgeTone.warning,
          'Still waiting for M-Pesa',
          'If you entered your PIN, the payment will show in your payments once M-Pesa confirms it. '
              'You will not be charged twice.',
        ),
      _ => (
          Icons.phone_android_rounded,
          BadgeTone.highlight,
          'Check your phone',
          'Enter your M-Pesa PIN on the prompt sent to $phone'
              '${amount != null ? ' to pay ${formatKes(amount)}' : ''}. '
              'This page updates when M-Pesa confirms.',
        ),
    };

    final p = context.palette;
    final color = switch (tone) {
      BadgeTone.success => p.success,
      BadgeTone.danger => p.danger,
      BadgeTone.warning => p.warning,
      _ => p.accentText,
    };
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpace.lg),
      children: [
        const SizedBox(height: AppSpace.xl),
        Icon(icon, size: AppSizes.avatar, color: color),
        const SizedBox(height: AppSpace.md),
        Semantics(
          liveRegion: true,
          child: Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(message, style: text.bodyMedium, textAlign: TextAlign.center),
        const SizedBox(height: AppSpace.xl),
        ...switch (state.phase) {
          CheckoutPhase.completed => [
              FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Done')),
            ],
          CheckoutPhase.failed => [
              FilledButton(onPressed: controller.startOver, child: const Text('Try again')),
            ],
          CheckoutPhase.timedOut => [
              FilledButton(
                onPressed: state.checking ? null : controller.checkAgain,
                child: Text(state.checking ? 'Checking…' : 'Check again'),
              ),
              const SizedBox(height: AppSpace.sm),
              OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
            ],
          _ => [
              OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                'Closing does not cancel the request. The payment will show in your payments.',
                style: text.bodySmall,
                textAlign: TextAlign.center,
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
    padding: EdgeInsets.all(AppSpace.md),
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
