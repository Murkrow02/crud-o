import 'dart:typed_data';
import 'package:crud_o/dashboard/data/crudo_navigation_config.dart';
import 'package:crud_o_core/auth/data/models/crudo_user.dart';
import 'package:flutter/material.dart';
import 'package:futuristic/futuristic.dart';

class CrudoNavHeader extends StatelessWidget {
  final CrudoNavigationConfig? config;

  /// Style knobs (optional)
  final double avatarRadius;
  final double fontSize;
  final EdgeInsets padding;

  const CrudoNavHeader({
    super.key,
    this.config,
    this.avatarRadius = 24,
    this.fontSize = 18,
    this.padding = const EdgeInsets.all(10),
  });

  @override
  Widget build(BuildContext context) {
    final cfg = config;

    return Container(
      padding: padding,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Column(
        children: [
          if (cfg?.getUserData != null)
            Futuristic<CrudoUser>(
              autoStart: true,
              futureBuilder: cfg!.getUserData!,
              busyBuilder: (context) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              ),
              dataBuilder: (context, user) {
                if (user == null) return const SizedBox();

                return Row(
                  children: [
                    SizedBox(
                      height: avatarRadius * 2 + 2,
                      width: avatarRadius * 2 + 2,
                      child: Futuristic<Uint8List?>(
                        autoStart: true,
                        futureBuilder: user.getAvatar,
                        dataBuilder: (context, data) {
                          if (data == null) return const SizedBox();
                          return CircleAvatar(
                            backgroundColor:
                            Theme.of(context).colorScheme.surface,
                            radius: avatarRadius,
                            backgroundImage: MemoryImage(data),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        user.getName(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: fontSize,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          if (cfg?.afterAvatar != null) cfg!.afterAvatar!,
        ],
      ),
    );
  }
}