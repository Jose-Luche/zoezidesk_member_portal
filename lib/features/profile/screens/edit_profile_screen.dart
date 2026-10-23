import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/clock.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_badge.dart';
import '../../../shared/widgets/info_banner.dart';
import '../../../shared/widgets/state_message.dart';
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
        appBar: AppBar(title: const Text('Edit profile')),
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
      appBar: AppBar(title: const Text('Edit profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.md),
          children: [
            InfoBanner(
              message: 'Name, phone number and photo can only be changed at the front desk.',
              icon: Icons.storefront_rounded,
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Contact', style: text.titleLarge),
            const SizedBox(height: AppSpace.sm),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Icons.mail_rounded),
                errorText: fieldErrors['email'],
              ),
              validator: (v) => v != null && v.trim().isNotEmpty && !_emailPattern.hasMatch(v.trim())
                  ? 'Enter a valid email address.'
                  : null,
            ),
            const SizedBox(height: AppSpace.lg),
            Text('Personal', style: text.titleLarge),
            const SizedBox(height: AppSpace.sm),
            // A field-styled button so the label stays visible like the inputs.
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of birth',
                  prefixIcon: const Icon(Icons.cake_rounded),
                  suffixIcon: const Icon(Icons.calendar_month_rounded),
                  errorText: fieldErrors['date_of_birth'],
                ),
                child: Text(dob == null ? 'Not set' : formatDate(dob), style: text.bodyLarge),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            Text('Gender', style: text.bodySmall),
            const SizedBox(height: AppSpace.sm),
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
            Text('Emergency contact', style: text.titleLarge),
            const SizedBox(height: AppSpace.sm),
            TextFormField(
              controller: _emergencyName,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.contact_emergency_rounded),
                errorText: fieldErrors['emergency_contact_name'],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            TextFormField(
              controller: _emergencyPhone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: '0712 345 678',
                prefixIcon: const Icon(Icons.phone_in_talk_rounded),
                errorText: fieldErrors['emergency_contact_phone'],
              ),
              validator: (v) => v != null && v.trim().isNotEmpty && !_phonePattern.hasMatch(v.trim())
                  ? 'Enter a valid phone number.'
                  : null,
            ),
            if (error is AppFailure && error is! ValidationFailure) ...[
              const SizedBox(height: AppSpace.lg),
              InfoBanner(
                tone: BadgeTone.danger,
                icon: error is NetworkFailure ? Icons.cloud_off_rounded : null,
                message: error is NetworkFailure
                    ? 'You are offline. Connect to the internet to save your changes.'
                    : error.message,
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: save.isLoading ? null : _save,
              child: Text(save.isLoading ? 'Saving…' : 'Save changes'),
            ),
            const SizedBox(height: AppSpace.lg),
          ],
        ),
      ),
    );
  }
}
