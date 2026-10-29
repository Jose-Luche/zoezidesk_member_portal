import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/repositories/workouts_repository.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/surfaces.dart';

/// What the member chose in the set sheet.
sealed class SetSheetResult {
  const SetSheetResult();
}

class SaveSet extends SetSheetResult {
  const SaveSet(this.values);

  final SetValues values;
}

class DeleteSet extends SetSheetResult {
  const DeleteSet();
}

/// Log or edit one set. Strength exercises take weight and reps (with
/// steppers for quick changes between sets); cardio takes time and
/// distance. RPE is optional.
Future<SetSheetResult?> showSetSheet(
  BuildContext context, {
  required String exerciseName,
  required int setNumber,
  required bool cardio,
  SetValues? initial,
  bool editing = false,
}) =>
    showAppSheet<SetSheetResult>(
      context,
      builder: (_) => _SetSheet(
        exerciseName: exerciseName,
        setNumber: setNumber,
        cardio: cardio,
        initial: initial,
        editing: editing,
      ),
    );

class _SetSheet extends StatefulWidget {
  const _SetSheet({
    required this.exerciseName,
    required this.setNumber,
    required this.cardio,
    required this.editing,
    this.initial,
  });

  final String exerciseName;
  final int setNumber;
  final bool cardio;
  final bool editing;
  final SetValues? initial;

  @override
  State<_SetSheet> createState() => _SetSheetState();
}

class _SetSheetState extends State<_SetSheet> {
  static final _num = NumberFormat('0.##');

  late final _weight = TextEditingController(text: _text(widget.initial?.weight));
  late final _reps = TextEditingController(text: _text(widget.initial?.reps));
  late final _duration = TextEditingController(text: _text(widget.initial?.durationMinutes));
  late final _distance = TextEditingController(text: _text(widget.initial?.distanceKm));
  late final _rpe = TextEditingController(text: _text(widget.initial?.rpe));
  String? _error;

  static String _text(num? v) => v == null ? '' : _num.format(v);

  @override
  void dispose() {
    for (final c in [_weight, _reps, _duration, _distance, _rpe]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _double(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));
  int? _int(TextEditingController c) => int.tryParse(c.text.trim());

  void _step(TextEditingController c, num by, {num max = 1000}) {
    final current = double.tryParse(c.text.replaceAll(',', '.')) ?? 0;
    final next = (current + by).clamp(0, max);
    setState(() => c.text = _num.format(next));
  }

  void _save() {
    final v = SetValues(
      weight: widget.cardio ? null : _double(_weight),
      reps: widget.cardio ? null : _int(_reps),
      durationMinutes: widget.cardio ? _int(_duration) : null,
      distanceKm: widget.cardio ? _double(_distance) : null,
      rpe: _int(_rpe),
    );
    final error = switch (v) {
      _ when !widget.cardio && (v.reps == null || v.reps == 0) => 'Enter the reps you did.',
      _ when widget.cardio && v.durationMinutes == null && v.distanceKm == null => 'Enter the time or the distance.',
      _ when (v.weight ?? 0) > 1000 || (v.reps ?? 0) > 1000 => 'That number looks too big.',
      _ when (v.durationMinutes ?? 0) > 1440 || (v.distanceKm ?? 0) > 1000 => 'That number looks too big.',
      _ when v.rpe != null && v.rpe! > 10 => 'Effort (RPE) is from 0 to 10.',
      _ => null,
    };
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(context).pop(SaveSet(v));
  }

  @override
  Widget build(BuildContext context) {
    return SheetLayout(
      title: widget.exerciseName,
      subtitle: 'Set ${widget.setNumber}',
      body: [
        if (widget.cardio) ...[
          _NumberField(name: 'time', label: 'Time (minutes)', controller: _duration, decimals: false,
              onMinus: () => _step(_duration, -5, max: 1440), onPlus: () => _step(_duration, 5, max: 1440)),
          const SizedBox(height: AppSpace.md),
          _NumberField(name: 'distance', label: 'Distance (km)', controller: _distance, decimals: true,
              onMinus: () => _step(_distance, -0.5), onPlus: () => _step(_distance, 0.5)),
        ] else ...[
          _NumberField(name: 'weight', label: 'Weight (kg)', controller: _weight, decimals: true,
              helper: 'Leave empty for bodyweight.',
              onMinus: () => _step(_weight, -2.5), onPlus: () => _step(_weight, 2.5)),
          const SizedBox(height: AppSpace.md),
          _NumberField(name: 'reps', label: 'Reps', controller: _reps, decimals: false,
              onMinus: () => _step(_reps, -1), onPlus: () => _step(_reps, 1)),
        ],
        const SizedBox(height: AppSpace.md),
        _NumberField(name: 'effort', label: 'Effort, RPE 0–10 (optional)', controller: _rpe, decimals: false,
            onMinus: () => _step(_rpe, -1, max: 10), onPlus: () => _step(_rpe, 1, max: 10)),
        if (_error != null) ...[
          const SizedBox(height: AppSpace.md),
          InfoBanner(tone: BadgeTone.danger, message: _error!),
        ],
      ],
      actions: [
        FilledButton(onPressed: _save, child: Text(widget.editing ? 'Save changes' : 'Log set')),
        if (widget.editing)
          OutlinedButton(
            style: OutlinedButton.styleFrom(foregroundColor: context.palette.danger),
            onPressed: () => Navigator.of(context).pop(const DeleteSet()),
            child: const Text('Delete set'),
          ),
      ],
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.name,
    required this.label,
    required this.controller,
    required this.decimals,
    required this.onMinus,
    required this.onPlus,
    this.helper,
  });

  /// For the stepper buttons' labels, e.g. "Increase weight".
  final String name;
  final String label;
  final TextEditingController controller;
  final bool decimals;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final String? helper;

  static const _stepper = BoxConstraints.tightFor(width: AppSizes.input, height: AppSizes.input);

  @override
  Widget build(BuildContext context) => LabeledField(
        label: label,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconButton.outlined(
              onPressed: onMinus,
              tooltip: 'Decrease $name',
              icon: const AppIcon(AppIcons.minus),
              constraints: _stepper,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
                keyboardType: TextInputType.numberWithOptions(decimal: decimals),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(decimals ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]')),
                ],
                decoration: InputDecoration(helperText: helper),
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            IconButton.outlined(
              onPressed: onPlus,
              tooltip: 'Increase $name',
              icon: const AppIcon(AppIcons.plus),
              constraints: _stepper,
            ),
          ],
        ),
      );
}
