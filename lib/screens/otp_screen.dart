// lib/screens/otp_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../core/api_client.dart';
import '../core/storage.dart';
import '../core/theme.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // Six separate controllers — one per digit
  final _controllers = List.generate(6, (_) => TextEditingController());
  final _focusNodes   = List.generate(6, (_) => FocusNode());

  bool    _loading    = false;
  String? _error;
  int     _countdown  = 60;
  Timer?  _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    // Focus first box on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_countdown == 0) {
        t.cancel();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  void _resendOtp() async {
    setState(() { _countdown = 60; _error = null; });
    _startCountdown();

    try {
      await ApiClient.post('/member/otp/request', {'phone': widget.phone});
    } catch (_) {}
  }

  // Handle digit input — auto-advance to next box.
  // Also handles the case where autofill/paste drops the whole
  // 6-digit code into a single box at once.
  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      // Whole code (or a chunk of it) landed in one box — e.g. SMS
      // autofill or a paste. Distribute the digits across the boxes
      // starting at `index`.
      final digits = value.replaceAll(RegExp(r'\D'), '');
      _controllers[index].clear();

      int cursor = index;
      for (final ch in digits.split('')) {
        if (cursor > 5) break;
        _controllers[cursor].text = ch;
        cursor++;
      }

      final lastFilled = (index + digits.length - 1).clamp(0, 5);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (lastFilled < 5) {
          _focusNodes[lastFilled + 1].requestFocus();
        } else {
          _focusNodes[lastFilled].unfocus();
        }
      });
    } else if (value.isNotEmpty && index < 5) {
      // Defer the focus change to the next frame so this field's own
      // internal setState (from the keystroke) finishes first. Doing
      // this synchronously inside onChanged is what causes focus to
      // snap back to the current box instead of advancing.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNodes[index + 1].requestFocus();
      });
    }

    final code = _controllers.map((c) => c.text).join();

    if (code.length == 6 && !_loading) {
      // Also defer verify slightly so the final box's UI updates first.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _verify();
      });
    }
  }

  // Handle backspace on an empty box — jump back and clear previous box.
  void _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verify() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final data = await ApiClient.post('/member/otp/verify', {
        'phone': widget.phone,
        'code':  code,
      });

      if (data['success'] == true) {
        await AppStorage.saveToken(data['token']);
        await AppStorage.saveMember(data['member']);

        if (mounted) context.go('/home');
      }

    } on ApiException catch (e) {
      setState(() => _error = e.message);
      // Clear all boxes on wrong code
      for (final c in _controllers) c.clear();
      _focusNodes[0].requestFocus();
    } catch (e) {
      setState(() => _error = 'Something went wrong. Try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes)   f.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Text('Enter verification code',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  )),

              const SizedBox(height: 8),

              RichText(
                text: TextSpan(
                  style: TextStyle(
                      fontSize: 14, color: AppTheme.textSecondary),
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: widget.phone,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                    ),
                    const TextSpan(text: ' via WhatsApp'),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // 6 digit boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: KeyboardListener(
                      focusNode: FocusNode(skipTraversal: true),
                      onKeyEvent: (event) => _handleKey(i, event),
                      child: TextFormField(
                        controller: _controllers[i],
                        focusNode: _focusNodes[i],
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        textAlign: TextAlign.center,
                        maxLength: 6, // allow paste/autofill to land here;
                        // _onDigitChanged distributes it
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        onChanged: (value) => _onDigitChanged(i, value),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                        decoration: InputDecoration(
                          counterText: '',
                          filled: true,
                          fillColor: AppTheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: AppTheme.brand,
                              width: 2,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Error
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Text(_error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppTheme.danger, fontSize: 13)),
                ),

              const SizedBox(height: 24),

              // Verify button
              ElevatedButton(
                onPressed: _loading ? null : _verify,
                child: _loading
                    ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: AppTheme.onBrand, strokeWidth: 2.5),
                )
                    : const Text('Verify'),
              ),

              const SizedBox(height: 20),

              // Resend
              Center(
                child: _countdown > 0
                    ? Text(
                  'Resend code in ${_countdown}s',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.textFaint),
                )
                    : TextButton(
                  onPressed: _resendOtp,
                  child: const Text('Resend code',
                      style: TextStyle(color: AppTheme.brand)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}