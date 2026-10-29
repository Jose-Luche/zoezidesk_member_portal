import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/formatters.dart';
import '../state/membership_status.dart';

/// The membership card: a solid sage fill with a soft circle bleeding off
/// one corner. Compact on the dashboard (hero element) and [expanded] on
/// the full-screen card, sharing a Hero tag between the two. The QR encodes
/// the exact `qr_code` string the front-desk scanner matches.
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
  static const _decorSize = 210.0;

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
    final on = p.onCard;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.hero));

    final header = Row(
      children: [
        Expanded(
          child: Text(
            gymName ?? 'ZoeziDesk',
            style: text.titleSmall?.copyWith(color: on, fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        _StatusChip(status: status),
      ],
    );
    final details = _Details(name: name, memberNumber: memberNumber, status: status, color: on);
    final progress = status.expiryPercent != null && status.state != MembershipState.none
        ? Semantics(
            label: '${status.expiryPercent}% of membership used',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                value: status.expiryPercent! / 100,
                minHeight: 8,
                color: on,
                backgroundColor: p.cardDecor,
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
            if (progress != null) ...[const SizedBox(height: 18), progress],
          ];

    // Top-right on the compact card, bottom-left on the full-screen one.
    final decor = Positioned(
      top: expanded ? null : -_decorSize * 0.42,
      right: expanded ? null : -_decorSize * 0.34,
      bottom: expanded ? -_decorSize * 0.42 : null,
      left: expanded ? -_decorSize * 0.34 : null,
      child: ExcludeSemantics(
        child: Container(
          width: _decorSize,
          height: _decorSize,
          decoration: BoxDecoration(color: p.cardDecor, shape: BoxShape.circle),
        ),
      ),
    );

    return Hero(
      tag: heroTag,
      child: Material(
        color: p.cardFill,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          highlightColor: AppColors.creamPressed,
          child: Stack(
            children: [
              decor,
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ],
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
    final body = text.bodyMedium?.copyWith(color: color);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: text.headlineMedium?.copyWith(color: color),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (memberNumber != null) ...[
          const SizedBox(height: 2),
          Text(memberNumber!, style: body),
        ],
        const SizedBox(height: 14),
        if (status.state == MembershipState.none)
          Text('Visit the front desk to get started', style: body)
        else ...[
          Text(status.planName ?? 'Membership', style: text.titleSmall?.copyWith(color: color)),
          if (expires != null)
            Text(
              status.state == MembershipState.expired
                  ? 'Expired ${formatDate(expires)}'
                  : 'Valid until ${formatDate(expires)}',
              style: body,
            ),
        ],
      ],
    );
  }
}

/// Outlined cream pill with an icon and words. Filled with the card color
/// so it stays readable where it overlaps the decorative circle.
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final MembershipStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final icon = switch (status.state) {
      MembershipState.active => AppIcons.circleCheck,
      MembershipState.expiring => AppIcons.clock,
      MembershipState.expired || MembershipState.none => AppIcons.circleAlert,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: ShapeDecoration(
        color: p.cardFill,
        shape: StadiumBorder(side: BorderSide(color: p.onCard, width: 1.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: AppSizes.iconBadge, color: p.onCard),
          const SizedBox(width: 5),
          Text(
            status.state == MembershipState.none ? 'Inactive' : status.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.onCard),
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
    final large = size > AppSizes.qrOnCard;
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(large ? 12 : AppSpace.sm),
      decoration: BoxDecoration(
        color: p.qrBackground,
        borderRadius: BorderRadius.circular(large ? AppSpace.lg : AppRadius.control),
      ),
      child: qrCode == null
          ? Center(child: AppIcon(AppIcons.qrCode, size: AppSpace.xxl * (large ? 1.5 : 0.75), color: p.qrInk))
          : Semantics(
              label: 'Membership QR code',
              image: true,
              child: QrImageView(
                data: qrCode!,
                errorCorrectionLevel: QrErrorCorrectLevel.H,
                padding: EdgeInsets.zero,
                // Scanners need dark modules on a light background.
                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: p.qrInk),
                dataModuleStyle: QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: p.qrInk),
              ),
            ),
    );
  }
}
