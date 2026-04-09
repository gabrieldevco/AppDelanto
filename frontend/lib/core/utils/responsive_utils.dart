import 'package:flutter/material.dart';

class ResponsiveUtils {
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= 360 && width < 400;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 400;
  }

  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static double getPadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 12;
    if (width < 400) return 16;
    return 24;
  }

  static double getHorizontalPadding(BuildContext context) {
    final width = getScreenWidth(context);
    if (width < 360) return 12;
    if (width < 400) return 16;
    return 24;
  }

  static double getFontSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    final scaleFactor = width < 360 ? 0.85 : (width < 400 ? 0.92 : 1.0);
    return baseSize * scaleFactor;
  }

  static double getIconSize(BuildContext context, double baseSize) {
    final width = getScreenWidth(context);
    final scaleFactor = width < 360 ? 0.85 : (width < 400 ? 0.92 : 1.0);
    return baseSize * scaleFactor;
  }

  static double getSpacing(BuildContext context, double baseSpacing) {
    final width = getScreenWidth(context);
    final scaleFactor = width < 360 ? 0.8 : (width < 400 ? 0.9 : 1.0);
    return baseSpacing * scaleFactor;
  }

  static double getCardWidth(BuildContext context) {
    final width = getScreenWidth(context);
    final padding = getPadding(context);
    return width - (padding * 2);
  }

  static int getCrossAxisCount(BuildContext context, {int baseCount = 2}) {
    final width = getScreenWidth(context);
    if (width < 360) return baseCount;
    if (width < 600) return baseCount;
    return baseCount + 1;
  }

  static double getBottomNavHeight(BuildContext context) {
    final height = getScreenHeight(context);
    if (height < 700) return 70;
    if (height < 800) return 80;
    return 90;
  }

  static double getHeaderHeight(BuildContext context) {
    final height = getScreenHeight(context);
    if (height < 700) return 50;
    if (height < 800) return 60;
    return 70;
  }
}

extension ResponsiveBuildContext on BuildContext {
  double get responsivePadding => ResponsiveUtils.getPadding(this);
  double get responsiveHPadding => ResponsiveUtils.getHorizontalPadding(this);
  double responsiveFont(double size) => ResponsiveUtils.getFontSize(this, size);
  double responsiveIcon(double size) => ResponsiveUtils.getIconSize(this, size);
  double responsiveSpacing(double spacing) => ResponsiveUtils.getSpacing(this, spacing);
  bool get isSmallScreen => ResponsiveUtils.isSmallScreen(this);
  bool get isMediumScreen => ResponsiveUtils.isMediumScreen(this);
  bool get isLargeScreen => ResponsiveUtils.isLargeScreen(this);
}
