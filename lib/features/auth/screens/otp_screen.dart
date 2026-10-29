import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../shared/widgets/surfaces.dart';
import '../state/otp_controllers.dart';
import '../widgets/auth_scaffold.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.args});

  final OtpArgs args;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  static const _resendSeconds = 60;

  final _code = TextEditingController();
  Timer? _timer;
  int _resendIn = _resendSeconds;
  String? _debugCode;
  String? _info;

  @override
  void initState() {
    super.initState();
    _debugCode = widget.args.debugCode;
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _code.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendIn <= 1) t.cancel();
      setState(() => _resendIn--);
    });
  }

  Future<void> _verify() async {
    if (_code.text.length != 6) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(otpVerifyControllerProvider.notifier)
        .verify(phone: widget.args.phone, code: _code.text);
    // Wrong code: clear the field so the member can type the next attempt.
    if (mounted && ref.read(otpVerifyControllerProvider).hasError) {
      _code.clear();
    }
  }

  Future<void> _resend() async {
    final result =
        await ref.read(otpVerifyControllerProvider.notifier).resend(widget.args.phone);
    if (result == null || !mounted) return;
    _code.clear();
    setState(() {
      _debugCode = result.debugCode;
      _info = 'A new code is on its way.';
    });
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    final verify = ref.watch(otpVerifyControllerProvider);
    final error = verify.error;
    final busy = verify.isLoading;
    final text = Theme.of(context).textTheme;

    return AuthScaffold(
      showBack: true,
      title: 'Enter your code',
      subtitle: 'We sent a 6-digit code to WhatsApp for ${widget.args.phone}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LabeledField(
            label: '6-digit code',
            child: TextField(
              controller: _code,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              textAlign: TextAlign.center,
              style: text.headlineSmall?.copyWith(letterSpacing: AppSpace.sm),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: 12),
              ),
              onChanged: (v) {
                if (v.length == 6) _verify();
              },
              onSubmitted: (_) => _verify(),
            ),
          ),
          if (kDebugMode && _debugCode != null) ...[
            const SizedBox(height: AppSpace.sm),
            Text('Local backend code: $_debugCode', style: text.bodySmall),
          ],
          if (error is AppFailure) ...[
            const SizedBox(height: AppSpace.md),
            FormErrorText(error.message),
          ] else if (_info != null) ...[
            const SizedBox(height: AppSpace.md),
            Text(_info!, style: text.bodySmall),
          ],
          const SizedBox(height: AppSpace.lg),
          ListenableBuilder(
            listenable: _code,
            builder: (context, _) => FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(AppSizes.sheetButton)),
              onPressed: busy || _code.text.length != 6 ? null : _verify,
              child: Text(busy ? 'Checking…' : 'Verify'),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: busy || _resendIn > 0 ? null : _resend,
            child: Text(
              _resendIn > 0 ? 'Resend code in ${_resendIn}s' : 'Resend code',
            ),
          ),
        ],
      ),
    );
  }
}
