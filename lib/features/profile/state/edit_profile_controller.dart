import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../data/dto/profile_dto.dart';
import '../../../data/repositories/profile_repository.dart';

/// The fields a member may edit. Name, phone and photo stay with the front
/// desk (phone is the OTP login identity).
class ProfileForm {
  const ProfileForm({
    this.email,
    this.gender,
    this.dateOfBirth,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory ProfileForm.from(ProfileMember m) => ProfileForm(
        email: m.email,
        gender: m.gender,
        dateOfBirth: m.dateOfBirth,
        emergencyContactName: m.emergencyContactName,
        emergencyContactPhone: m.emergencyContactPhone,
      );

  final String? email;
  final String? gender;

  /// `yyyy-MM-dd`.
  final String? dateOfBirth;
  final String? emergencyContactName;
  final String? emergencyContactPhone;

  Map<String, String?> _asJson() => {
        'email': email,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'emergency_contact_name': emergencyContactName,
        'emergency_contact_phone': emergencyContactPhone,
      };

  /// Only the fields that differ from [original]; blank strings become null.
  Map<String, Object?> changesFrom(ProfileForm original) {
    String? clean(String? v) => v == null || v.trim().isEmpty ? null : v.trim();
    final before = original._asJson();
    return {
      for (final e in _asJson().entries)
        if (clean(e.value) != clean(before[e.key])) e.key: clean(e.value),
    };
  }
}

/// Saves profile edits. Online only; the server's response replaces the
/// cached profile.
class EditProfileController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncData(null);

  /// Returns true when saved (or nothing changed).
  Future<bool> save({required ProfileForm original, required ProfileForm edited}) async {
    if (state.isLoading) return false;
    final changes = edited.changesFrom(original);
    if (changes.isEmpty) return true;

    state = const AsyncLoading();
    try {
      await ref.read(profileRepositoryProvider).update(changes);
      if (ref.mounted) state = const AsyncData(null);
      return true;
    } on AppFailure catch (e, st) {
      if (ref.mounted) state = AsyncError(e, st);
      return false;
    }
  }
}

final editProfileControllerProvider =
    NotifierProvider.autoDispose<EditProfileController, AsyncValue<void>>(
  EditProfileController.new,
);
