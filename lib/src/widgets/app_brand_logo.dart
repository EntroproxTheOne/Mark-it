import 'package:flutter/material.dart';

/// Central Mark-it mark (`assets/branding/app_logo.png`).
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.height = 48,
    this.width,
    this.opacity = 1,
  });

  final double height;
  final double? width;
  final double opacity;

  static const assetPath = 'assets/branding/app_logo.png';

  @override
  Widget build(BuildContext context) {
    Widget img = Image.asset(
      assetPath,
      height: height,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
    );
    if (opacity < 1) {
      img = Opacity(opacity: opacity, child: img);
    }
    return img;
  }
}
