import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Member photo, falling back to initials (also while offline with no
/// cached image).
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({super.key, required this.name, this.photoUrl, this.size = AppSizes.avatar});

  final String name;
  final String? photoUrl;
  final double size;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: p.cardFill, shape: BoxShape.circle),
      child: Text(
        _initials,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: p.onCard),
      ),
    );

    return Semantics(
      label: 'Photo of $name',
      image: true,
      child: photoUrl == null
          ? fallback
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: photoUrl!,
                width: size,
                height: size,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                fadeInDuration: AppMotion.fast,
                placeholder: (_, _) => fallback,
                errorWidget: (_, _, _) => fallback,
              ),
            ),
    );
  }
}
