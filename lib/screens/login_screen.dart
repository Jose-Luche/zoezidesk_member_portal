// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  bool   _loading        = false;
  String? _error;

  Future<void> _requestOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      setState(() => _error = 'Please enter your phone number');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final data = await ApiClient.post('/member/otp/request', {
        'phone': phone,
      });

      if (data['success'] == true && mounted) {
        context.push('/otp', extra: phone);
      }

    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Could not connect. Check your internet.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Logo
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.brandLight, AppTheme.brand],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.bolt_rounded,
                    color: AppTheme.onBrand, size: 28),
              ),

              const SizedBox(height: 28),

              Text('Welcome back',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  )),

              const SizedBox(height: 6),

              Text('Enter your phone number to sign in',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  )),

              const SizedBox(height: 36),

              // Error message
              if (_error != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.danger.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppTheme.danger.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: AppTheme.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: TextStyle(
                                color: AppTheme.danger, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Phone input
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                onFieldSubmitted: (_) => _requestOtp(),
                decoration: const InputDecoration(
                  labelText: 'Phone number',
                  hintText: '07XX XXX XXX',
                  prefixIcon: Icon(Icons.phone_outlined,
                      color: AppTheme.textFaint),
                ),
              ),

              const SizedBox(height: 8),

              Text('We\'ll send a WhatsApp verification code',
                  style: TextStyle(
                      fontSize: 12, color: AppTheme.textFaint)),

              const SizedBox(height: 24),

              // Submit button
              ElevatedButton(
                onPressed: _loading ? null : _requestOtp,
                child: _loading
                    ? const SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                      color: AppTheme.onBrand, strokeWidth: 2.5),
                )
                    : const Text('Send Code'),
              ),

              const SizedBox(height: 48),

              // Footer
              Center(
                child: Text(
                  'GymDesk Member Portal',
                  style: TextStyle(fontSize: 12, color: AppTheme.textFaint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}