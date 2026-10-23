import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../state/membership_status.dart';

/// Gradient membership card. Compact on the dashboard (hero element) and
/// [expanded] on the full-screen card, sharing a Hero tag between the two.
/// The QR encodes the exact `qr_code` string the front-desk scanner matches.
class MembershipCard extends StatelessWidget {
  const MembershipCard({
    super.key,
    required this.name,
    required this.status,
    this.memberNumber,
    this.gymName,
    this.qrCode,
    this.onTap,
    this.expanded = false,
  });

  static const heroTag = 'membership-card';

  final String name;
  final MembershipStatus status;
  final String? memberNumber;
  final String? gymName;
  final String? qrCode;
  final VoidCallback? onTap;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final on = p.onCardGradient;
    final radius = BorderRadius.circular(AppRadius.card);

    final header = Row(
      children: [
        Expanded(
          child: Text(
            gymName ?? 'ZoeziDesk',
            style: text.labelLarge?.copyWith(color: on),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _StatusChip(status: status, color: on),
      ],
    );
    final details = _Details(name: name, memberNumber: memberNumber, status: status, color: on);
    final progress = status.expiryPercent != null && status.state != MembershipState.none
        ? Semantics(
            label: '${status.expiryPercent}% of membership used',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.control),
              child: LinearProgressIndicator(
                value: status.expiryPercent! / 100,
                minHeight: AppSpace.sm,
                color: on,
                backgroundColor: on.withValues(alpha: 0.2),
              ),
            ),
          )
        : null;

    final List<Widget> children = expanded
        ? [
            header,
            const SizedBox(height: AppSpace.lg),
            Center(child: _QrTile(qrCode: qrCode, size: AppSizes.qrFullScreen)),
            const SizedBox(height: AppSpace.lg),
            details,
            if (progress != null) ...[const SizedBox(height: AppSpace.md), progress],
          ]
        : [
            header,
            const SizedBox(height: AppSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: details),
                const SizedBox(width: AppSpace.md),
                _QrTile(qrCode: qrCode, size: AppSizes.qrOnCard),
              ],
            ),
            if (progress != null) ...[const SizedBox(height: AppSpace.md), progress],
          ];

    return Hero(
      tag: heroTag,
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: p.cardGradient,
            ),
            borderRadius: radius,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: children,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.name,
    required this.memberNumber,
    required this.status,
    required this.color,
  });

  final String name;
  final String? memberNumber;
  final MembershipStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final expires = status.expiresOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: text.headlineMedium?.copyWith(color: color),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (memberNumber != null)
          Text(memberNumber!, style: text.bodyMedium?.copyWith(color: color)),
        const SizedBox(height: AppSpace.md),
        if (status.state == MembershipState.none)
          Text(
            'Visit the front desk to get started',
            style: text.bodyMedium?.copyWith(color: color),
          )
        else ...[
          Text(
            status.planName ?? 'Membership',
            style: text.titleSmall?.copyWith(color: color),
          ),
          if (expires != null)
            Text(
              status.state == MembershipState.expired
                  ? 'Expired ${formatDate(expires)}'
                  : 'Valid until ${formatDate(expires)}',
              style: text.bodyMedium?.copyWith(color: color),
            ),
        ],
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.color});

  final MembershipStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = switch (status.state) {
      MembershipState.active => Icons.check_circle_rounded,
      MembershipState.expiring => Icons.schedule_rounded,
      MembershipState.expired || MembershipState.none => Icons.cancel_rounded,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSpace.md, color: color),
          const SizedBox(width: AppSpace.xs),
          Text(
            status.state == MembershipState.none ? 'Inactive' : status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _QrTile extends StatelessWidget {
  const _QrTile({required this.qrCode, required this.size});

  final String? qrCode;
  final double size;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(size > AppSizes.qrOnCard ? AppSpace.md : AppSpace.sm),
      decoration: BoxDecoration(
        color: p.qrBackground,
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
      child: qrCode == null
          ? Icon(Icons.qr_code_2_rounded, size: AppSpace.xxl, color: p.onCardGradient)
          : Semantics(
              label: 'Membership QR code',
              image: true,
              child: QrImageView(
                data: qrCode!,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                padding: EdgeInsets.zero,
                // Scanners need dark modules on a light background.
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.onCardGradient),
                dataModuleStyle: QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: p.onCardGradient,
                ),
              ),
            ),
    );
  }
}
