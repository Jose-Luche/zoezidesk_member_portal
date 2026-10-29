import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/dto/builder_dto.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../state/builder_providers.dart';
import '../widgets/builder_steps.dart';

/// Guided workout builder: the web portal's 7-step form. The server builds
/// the workout, so building is online only. (The web's free-text "describe
/// it" mode is left out: it needs a paid Claude API key.)
class BuilderScreen extends ConsumerStatefulWidget {
  const BuilderScreen({super.key});

  @override
  ConsumerState<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends ConsumerState<BuilderScreen> {
  @override
  void initState() {
    super.initState();
    // Apply the member's last answers as soon as options are available,
    // including when they are already cached.
    ref.listenManual(builderOptionsProvider, (_, next) {
      final o = next.value?.data;
      if (o != null) ref.read(builderFormProvider.notifier).seed(o.lastInputs);
    }, fireImmediately: true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(builderActionsProvider.notifier).loadOptions(),
    );
  }

  void _openWorkout() => context.push(Routes.builderWorkout);

  Future<void> _build() async {
    final inputs = ref.read(builderFormProvider).inputs;
    final workout = await ref.read(builderActionsProvider.notifier).generate(inputs);
    if (workout != null && mounted) _openWorkout();
  }

  @override
  Widget build(BuildContext context) {
    final options = ref.watch(builderOptionsProvider).value?.data;
    final actions = ref.watch(builderActionsProvider);
    // Keeps the answers alive while the workout screen is open on top.
    ref.watch(builderFormProvider);

    final Widget body;
    if (options == null) {
      final error = actions.error;
      body = error == null
          ? const SkeletonList(itemCount: 5)
          : error is NetworkFailure
              ? StateMessage.offline(
                  message: 'Building a workout needs an internet connection.',
                  onAction: () => ref.read(builderActionsProvider.notifier).loadOptions(),
                )
              : StateMessage.error(
                  onAction: () => ref.read(builderActionsProvider.notifier).loadOptions(),
                );
    } else {
      body = _StepView(options: options, onBuild: _build);
    }

    return Scaffold(
      appBar: const AppTopBar(title: 'Workout builder'),
      body: body,
    );
  }
}

class _LastWorkoutCard extends ConsumerWidget {
  const _LastWorkoutCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workout = ref.watch(builderWorkoutProvider).value?.data;
    if (workout == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: ListCard(
        children: [
          ListRow(
            icon: AppIcons.history,
            title: 'Your last workout',
            subtitle: '${workout.exercises.length} exercises'
                '${workout.estimatedDurationMinutes == null ? '' : ' · ${workout.estimatedDurationMinutes} min'}',
            onTap: () => context.push(Routes.builderWorkout),
          ),
        ],
      ),
    );
  }
}

class _StepView extends ConsumerWidget {
  const _StepView({required this.options, required this.onBuild});

  final BuilderOptions options;
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(builderFormProvider);
    final actions = ref.watch(builderActionsProvider);
    final controller = ref.read(builderFormProvider.notifier);
    final copy = stepCopy(form.step);
    final text = Theme.of(context).textTheme;
    final error = actions.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, 0),
          child: Semantics(
            label: 'Step ${form.number} of ${BuilderFormState.count}',
            excludeSemantics: true,
            child: Row(
              children: [
                Text(
                  'Step ${form.number} of ${BuilderFormState.count}',
                  style: text.titleSmall?.copyWith(color: context.palette.accentText),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: form.number / BuilderFormState.count),
                    duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : AppMotion.medium,
                    curve: AppMotion.curve,
                    builder: (_, v, _) => LinearProgressIndicator(value: v),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, AppSpace.lg),
            children: [
              if (form.step == BuilderStep.energy) const _LastWorkoutCard(),
              Semantics(header: true, child: Text(copy.title, style: text.headlineMedium)),
              if (copy.help != null) ...[
                const SizedBox(height: AppSpace.sm),
                Text(copy.help!, style: text.bodyMedium?.copyWith(color: context.palette.textMuted)),
              ],
              const SizedBox(height: AppSpace.lg),
              BuilderStepBody(options: options),
              if (error is AppFailure) ...[
                const SizedBox(height: AppSpace.lg),
                _BuildError(error),
              ],
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.md),
            child: Row(
              children: [
                if (form.step.index > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
                      onPressed: actions.isLoading ? null : controller.back,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
                    onPressed: !form.canAdvance || actions.isLoading
                        ? null
                        : form.isLast
                            ? onBuild
                            : controller.next,
                    child: Text(
                      actions.isLoading
                          ? 'Building…'
                          : form.isLast
                              ? 'Build my workout'
                              : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BuildError extends StatelessWidget {
  const _BuildError(this.error);

  final AppFailure error;

  @override
  Widget build(BuildContext context) => InfoBanner(
        tone: BadgeTone.danger,
        icon: error is NetworkFailure ? AppIcons.cloudOff : null,
        message: error is NetworkFailure
            ? 'You are offline. Building a workout needs an internet connection.'
            : error.message,
      );
}
