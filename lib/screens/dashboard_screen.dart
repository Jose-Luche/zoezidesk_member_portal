// lib/screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_client.dart';
import '../core/storage.dart';
import '../core/theme.dart';


class DashboardScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _data;
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiClient.get('/member/dashboard');
      setState(() { _data = data; _loading = false; });
    } on ApiException catch (e) {
      setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      setState(() {
        _error = 'Could not load dashboard. Pull to refresh.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.brand,
          onRefresh: _loadDashboard,
          child: _loading
              ? const Center(child: CircularProgressIndicator(
              color: AppTheme.brand))
              : _error != null
              ? _buildError()
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_outlined,
                size: 48, color: AppTheme.textFaint),
            const SizedBox(height: 16),
            Text(_error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboard,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final member     = _data!['member']     as Map<String, dynamic>;
    final membership = _data!['membership'] as Map<String, dynamic>?;
    final payments   = (_data!['recent_payments'] as List)
        .cast<Map<String, dynamic>>();
    final attendance = _data!['attendance_month'] as int;
    final firstName  = (member['name'] as String).split(' ').first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [

        // ── Greeting ────────────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hi, $firstName 👋',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary)),
                Text(DateFormat('EEEE, d MMM y').format(DateTime.now()),
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.textFaint)),
              ],
            ),
            // Avatar
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppTheme.brandSoft,
                borderRadius: BorderRadius.circular(21),
              ),
              child: Center(
                child: Text(
                  (member['name'] as String)
                      .split(' ')
                      .take(2)
                      .map((w) => w[0].toUpperCase())
                      .join(),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: AppTheme.brand),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Membership card ──────────────────────────────────────────
        _MembershipCard(membership: membership),

        const SizedBox(height: 16),

        // ── Quick stat ───────────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.directions_run,
                      color: AppTheme.success, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$attendance',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary)),
                    const Text('Visits this month',
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textFaint)),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Recent payments ──────────────────────────────────────────
        if (payments.isNotEmpty) ...[
          const Text('Recent Payments',
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: payments.asMap().entries.map((entry) {
                final i       = entry.key;
                final payment = entry.value;
                return Column(
                  children: [
                    _PaymentTile(payment: payment),
                    if (i < payments.length - 1)
                      const Divider(height: 1, indent: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
        // ── Journal teaser
        const SizedBox(height: 4),
        const Text('Journal',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            // Switch to journal tab (index 3)
            widget.onSwitchTab?.call(3);
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Text('📝', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Fitness Journal',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textPrimary,
                            )),
                        Text('Log workouts, track progress, set goals',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textFaint,
                            )),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios,
                      size: 14, color: AppTheme.textFaint),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Membership Card Widget ───────────────────────────────────────────
class _MembershipCard extends StatelessWidget {
  final Map<String, dynamic>? membership;
  const _MembershipCard({required this.membership});

  @override
  Widget build(BuildContext context) {
    if (membership == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.danger.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppTheme.danger, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('No active membership.\nVisit the front desk to get started.',
                  style: TextStyle(fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      );
    }

    final daysLeft  = membership!['days_left'] as int;
    final planName  = membership!['plan_name'] as String;
    final expiresAt = membership!['expires_at'] as String;
    final isExpiring= daysLeft <= 7;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isExpiring
              ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
              : [AppTheme.brandLight, AppTheme.brand],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(planName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700,
                      color: AppTheme.onBrand)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.onBrand.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: const Text('✓ Active',
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        color: AppTheme.onBrand)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Days remaining
          Row(
            children: [
              Text('$daysLeft',
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w800,
                      color: AppTheme.onBrand, height: 1)),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('day${daysLeft == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.onBrand.withOpacity(0.8))),
                  Text('remaining',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.onBrand.withOpacity(0.6))),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Expiry bar
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: daysLeft / 30.0,
              backgroundColor: AppTheme.onBrand.withOpacity(0.25),
              valueColor: const AlwaysStoppedAnimation(AppTheme.onBrand),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 12),

          Text('Expires $expiresAt',
              style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.onBrand.withOpacity(0.7))),

          if (isExpiring) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.onBrand.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.access_time, color: AppTheme.onBrand, size: 14),
                  SizedBox(width: 6),
                  Text('Expiring soon — contact the front desk to renew',
                      style: TextStyle(fontSize: 11, color: AppTheme.onBrand)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Payment Tile Widget ──────────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final Map<String, dynamic> payment;
  const _PaymentTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    final method  = payment['method'] as String;
    final isMpesa = method == 'mpesa';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 4),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: AppTheme.success.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
            isMpesa ? Icons.phone_android_outlined : Icons.money_outlined,
            color: AppTheme.success, size: 18),
      ),
      title: Text(
          payment['plan'] ?? 'Membership',
          style: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary)),
      subtitle: Text(
          '${payment['date']} · ${isMpesa ? payment['receipt'] ?? method : method}',
          style: const TextStyle(
              fontSize: 11, color: AppTheme.textFaint)),
      trailing: Text(
          'KES ${NumberFormat('#,###').format(payment['amount'])}',
          style: const TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary)),
    );
  }
}