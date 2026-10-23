import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/dto/builder_dto.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_message.dart';
import '../state/builder_providers.dart';
import '../widgets/builder_steps.dart';

/// Guided workout builder: the web portal's 7-step form, or a free-text
/// description. The server builds the workout, so building is online only.
class BuilderScreen extends ConsumerStatefulWidget {
  const BuilderScreen({super.key});

  @override
  ConsumerState<BuilderScreen> createState() => _BuilderScreenState();
}

class _BuilderScreenState extends ConsumerState<BuilderScreen> {
  bool _describe = false;

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
    // Keeps the answers alive while the "Describe it" view is showing.
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
    } else if (_describe) {
      body = _DescribeView(onBuilt: _openWorkout, onReview: () => setState(() => _describe = false));
    } else {
      body = _StepView(options: options, onBuild: _build);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout builder'),
        actions: [
          if (options != null)
            TextButton.icon(
              onPressed: actions.isLoading ? null : () => setState(() => _describe = !_describe),
              icon: Icon(_describe ? Icons.checklist_rounded : Icons.edit_note_rounded),
              label: Text(_describe ? 'Step by step' : 'Describe it'),
            ),
        ],
      ),
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
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.history_rounded),
          title: const Text('Your last workout'),
          subtitle: Text(
            '${workout.exercises.length} exercises'
            '${workout.estimatedDurationMinutes == null ? '' : ' · ${workout.estimatedDurationMinutes} min'}',
          ),
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: () => context.push(Routes.builderWorkout),
        ),
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
          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.md, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Step ${form.number} of ${BuilderFormState.count}', style: text.bodySmall),
              const SizedBox(height: AppSpace.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.control),
                child: LinearProgressIndicator(
                  value: form.number / BuilderFormState.count,
                  minHeight: AppSpace.xs,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpace.md),
            children: [
              if (form.step == BuilderStep.energy) const _LastWorkoutCard(),
              if (form.reviewNotice != null) ...[
                InfoBanner(message: form.reviewNotice!, tone: BadgeTone.highlight),
                const SizedBox(height: AppSpace.md),
              ],
              Text(copy.title, style: text.headlineMedium),
              if (copy.help != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(copy.help!, style: text.bodySmall),
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
            padding: const EdgeInsets.all(AppSpace.md),
            child: Row(
              children: [
                if (form.step.index > 0) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: actions.isLoading ? null : controller.back,
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                ],
                Expanded(
                  flex: 2,
                  child: FilledButton(
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
        icon: error is NetworkFailure ? Icons.cloud_off_rounded : null,
        message: error is NetworkFailure
            ? 'You are offline. Building a workout needs an internet connection.'
            : error.message,
      );
}

class _DescribeView extends ConsumerStatefulWidget {
  const _DescribeView({required this.onBuilt, required this.onReview});

  final VoidCallback onBuilt;
  final VoidCallback onReview;

  @override
  ConsumerState<_DescribeView> createState() => _DescribeViewState();
}

class _DescribeViewState extends ConsumerState<_DescribeView> {
  final _prompt = TextEditingController();

  @override
  void dispose() {
    _prompt.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final outcome = await ref.read(builderActionsProvider.notifier).describe(_prompt.text);
    if (!mounted) return;
    switch (outcome) {
      case Built():
        widget.onBuilt();
      case NeedsReview(:final inputs):
        ref.read(builderFormProvider.notifier).review(inputs);
        widget.onReview();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final actions = ref.watch(builderActionsProvider);
    final error = actions.error;
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.all(AppSpace.md),
      children: [
        Text('Describe your workout', style: text.headlineMedium),
        const SizedBox(height: AppSpace.xs),
        Text(
          'Say what you want to train, how long you have and any equipment or injuries.',
          style: text.bodySmall,
        ),
        const SizedBox(height: AppSpace.lg),
        TextField(
          controller: _prompt,
          minLines: 4,
          maxLines: 8,
          maxLength: 1000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Your workout',
            hintText: 'Arms today with dumbbells, about 45 minutes. My left shoulder is sore.',
            alignLabelWithHint: true,
          ),
        ),
        if (error is AppFailure) ...[
          const SizedBox(height: AppSpace.md),
          _BuildError(error),
        ],
        const SizedBox(height: AppSpace.lg),
        FilledButton(
          onPressed: actions.isLoading ? null : _submit,
          child: Text(actions.isLoading ? 'Building…' : 'Build from description'),
        ),
      ],
    );
  }
}
