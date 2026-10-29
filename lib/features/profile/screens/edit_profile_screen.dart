import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/app_top_bar.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/state_message.dart';
import '../../../shared/widgets/surfaces.dart';
import '../../auth/widgets/auth_scaffold.dart';
import '../state/edit_profile_controller.dart';
import '../state/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _emergencyName = TextEditingController();
  final _emergencyPhone = TextEditingController();
  String? _gender;
  String? _dateOfBirth;
  ProfileForm? _original;

  static final _isoDate = DateFormat('yyyy-MM-dd');
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phonePattern = RegExp(r'^\+?[0-9 ]{9,20}$');

  @override
  void dispose() {
    _email.dispose();
    _emergencyName.dispose();
    _emergencyPhone.dispose();
    super.dispose();
  }

  void _fill(ProfileForm form) {
    _original = form;
    _email.text = form.email ?? '';
    _emergencyName.text = form.emergencyContactName ?? '';
    _emergencyPhone.text = form.emergencyContactPhone ?? '';
    _gender = form.gender;
    _dateOfBirth = form.dateOfBirth;
  }

  ProfileForm get _edited => ProfileForm(
        email: _email.text,
        gender: _gender,
        dateOfBirth: _dateOfBirth,
        emergencyContactName: _emergencyName.text,
        emergencyContactPhone: _emergencyPhone.text,
      );

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final current = DateTime.tryParse(_dateOfBirth ?? '');
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now.subtract(const Duration(days: 1)),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      helpText: 'Date of birth',
    );
    if (picked != null) setState(() => _dateOfBirth = _isoDate.format(picked));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final saved = await ref
        .read(editProfileControllerProvider.notifier)
        .save(original: _original!, edited: _edited);
    if (!saved || !mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Profile updated')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileCacheProvider).value?.data;
    final save = ref.watch(editProfileControllerProvider);
    final error = save.error;
    final fieldErrors = error is ValidationFailure ? error.fieldErrors : const <String, String>{};
    final text = Theme.of(context).textTheme;

    if (profile == null) {
      return Scaffold(
        appBar: const AppTopBar(title: 'Edit profile'),
        body: StateMessage.offline(
          title: 'Profile not loaded',
          message: 'Open your profile with an internet connection first.',
          actionLabel: 'Back',
          onAction: () => Navigator.of(context).maybePop(),
        ),
      );
    }
    if (_original == null) _fill(ProfileForm.from(profile.member));

    final dob = DateTime.tryParse(_dateOfBirth ?? '');

    return Scaffold(
      appBar: const AppTopBar(title: 'Edit profile'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.lg),
          children: [
            const InfoBanner(
              message: 'Name, phone number and photo can only be changed at the front desk.',
              icon: AppIcons.store,
            ),
            const SizedBox(height: AppSpace.lg),
            const SectionHeader('Contact'),
            LabeledField(
              label: 'Email',
              child: TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const FieldIcon(AppIcons.mail),
                  errorText: fieldErrors['email'],
                ),
                validator: (v) => v != null && v.trim().isNotEmpty && !_emailPattern.hasMatch(v.trim())
                    ? 'Enter a valid email address.'
                    : null,
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            const SectionHeader('Personal'),
            LabeledField(
              label: 'Date of birth',
              child: PickerField(
                onTap: _pickDate,
                icon: AppIcons.cake,
                trailingIcon: AppIcons.calendar,
                errorText: fieldErrors['date_of_birth'],
                value: dob == null ? 'Not set' : formatDate(dob),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                'Gender',
                style: text.labelLarge?.copyWith(fontSize: 13, height: 1.3, color: context.palette.textSoft),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final (value, label) in const [
                  ('female', 'Female'),
                  ('male', 'Male'),
                  ('other', 'Other'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: _gender == value,
                    onSelected: (on) => setState(() => _gender = on ? value : null),
                  ),
              ],
            ),
            if (fieldErrors['gender'] != null) ...[
              const SizedBox(height: AppSpace.sm),
              FormErrorText(fieldErrors['gender']!),
            ],
            const SizedBox(height: AppSpace.lg),
            const SectionHeader('Emergency contact'),
            LabeledField(
              label: 'Name',
              child: TextFormField(
                controller: _emergencyName,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  prefixIcon: const FieldIcon(AppIcons.contact),
                  errorText: fieldErrors['emergency_contact_name'],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            LabeledField(
              label: 'Phone',
              child: TextFormField(
                controller: _emergencyPhone,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  hintText: '0712 345 678',
                  prefixIcon: const FieldIcon(AppIcons.phoneCall),
                  errorText: fieldErrors['emergency_contact_phone'],
                ),
                validator: (v) => v != null && v.trim().isNotEmpty && !_phonePattern.hasMatch(v.trim())
                    ? 'Enter a valid phone number.'
                    : null,
              ),
            ),
            if (error is AppFailure && error is! ValidationFailure) ...[
              const SizedBox(height: AppSpace.lg),
              InfoBanner(
                tone: BadgeTone.danger,
                icon: error is NetworkFailure ? AppIcons.cloudOff : null,
                message: error is NetworkFailure
                    ? 'You are offline. Connect to the internet to save your changes.'
                    : error.message,
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
              onPressed: save.isLoading ? null : _save,
              child: Text(save.isLoading ? 'Saving…' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
