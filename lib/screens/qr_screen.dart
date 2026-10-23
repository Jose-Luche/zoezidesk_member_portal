// lib/screens/qr_screen.dart

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class QrScreen extends StatefulWidget {
  const QrScreen({super.key});

  @override
  State<QrScreen> createState() => _QrScreenState();
}

class _QrScreenState extends State<QrScreen> {
  Map<String, dynamic>? _data;
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQr();
  }

  Future<void> _loadQr() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.get('/member/qr');
      setState(() { _data = data; _loading = false; });
    } catch (e) {
      setState(() {
        _error   = 'Could not load QR code.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Check-in QR Code'),
        backgroundColor: AppTheme.background,
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(
            color: AppTheme.brand))
            : _error != null
            ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_error!),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _loadQr,
                  child: const Text('Retry'),
                ),
              ],
            ))
            : _buildQr(),
      ),
    );
  }

  Widget _buildQr() {
    final qrCode       = _data!['qr_code']       as String;
    final memberNumber = _data!['member_number'] as String;
    final name         = _data!['name']          as String;
    final gymName      = _data!['gym_name']      as String;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Gym name
        Text(gymName,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textFaint)),

        const SizedBox(height: 24),

        // QR code
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: QrImageView(
            data: qrCode,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
            // embed logo in center
            embeddedImage: const AssetImage('assets/icon.png'),
            embeddedImageStyle: const QrEmbeddedImageStyle(
              size: Size(40, 40),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Member number
        Text(memberNumber,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700,
                letterSpacing: 3, color: AppTheme.textPrimary,
                fontFamily: 'monospace')),

        const SizedBox(height: 4),

        Text(name,
            style: const TextStyle(
                fontSize: 14, color: AppTheme.textSecondary)),

        const SizedBox(height: 32),

        // Instruction
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline,
                    size: 16, color: AppTheme.textFaint),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                      'Show this QR code at the front desk to check in',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textFaint,
                          height: 1.4)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}