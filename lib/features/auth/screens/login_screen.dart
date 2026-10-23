import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../state/otp_controllers.dart';
import '../state/session_controller.dart';
import '../widgets/auth_scaffold.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final phone = _phone.text.trim();
    final sent =
        await ref.read(otpRequestControllerProvider.notifier).submit(phone);
    if (!sent || !mounted) return;
    final debugCode = ref.read(otpRequestControllerProvider).value?.debugCode;
    context.push(Routes.otp, extra: OtpArgs(phone: phone, debugCode: debugCode));
  }

  @override
  Widget build(BuildContext context) {
    final request = ref.watch(otpRequestControllerProvider);
    final session = ref.watch(sessionControllerProvider);
    final reason = session is SignedOut ? session.reason : null;
    final error = request.error;

    return AuthScaffold(
      title: 'Member login',
      subtitle: 'Enter the phone number registered at your gym. '
          'We will send a 6-digit code to WhatsApp.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reason != null) ...[
              FormErrorText(reason),
              const SizedBox(height: AppSpace.md),
            ],
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '0712 345 678',
                prefixIcon: Icon(Icons.phone_rounded),
              ),
              validator: (v) => v == null || !isPlausiblePhone(v)
                  ? 'Enter a valid phone number.'
                  : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (error is AppFailure) ...[
              const SizedBox(height: AppSpace.md),
              FormErrorText(error.message),
            ],
            const SizedBox(height: AppSpace.lg),
            FilledButton(
              onPressed: request.isLoading ? null : _submit,
              child: Text(request.isLoading ? 'Sending code…' : 'Send code'),
            ),
          ],
        ),
      ),
    );
  }
}
