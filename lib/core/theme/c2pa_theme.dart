import 'package:flutter/material.dart';

import 'package:c2pa_view/domain/models/validation_result.dart';

/// Theme data for C2PA manifest viewer widgets.
///
/// Provides colors, text styles, and other visual properties that
/// can be customized by wrapping your widget tree with [C2paViewerTheme].
class C2paViewerThemeData {
  final Color validColor;
  final Color invalidColor;
  final Color unrecognizedColor;
  final Color noCredentialColor;

  final Color surfaceColor;
  final Color surfaceVariantColor;
  final Color borderColor;
  final Color textPrimaryColor;
  final Color textSecondaryColor;
  final Color iconColor;

  final Color selectedNodeBorderColor;
  final Color pathNodeBorderColor;
  final Color defaultNodeBorderColor;
  final Color edgeColor;

  final TextStyle titleLargeStyle;
  final TextStyle titleMediumStyle;
  final TextStyle titleSmallStyle;
  final TextStyle bodyStyle;
  final TextStyle bodySmallStyle;
  final TextStyle labelStyle;

  final double sidebarWidth;
  final double thumbnailSize;
  final double nodeWidth;
  final double nodeHeight;
  final double nodeSpacingX;
  final double nodeSpacingY;
  final BorderRadius cardRadius;
  final BorderRadius sectionRadius;

  const C2paViewerThemeData({
    this.validColor = const Color(0xFF1B8D3E),
    this.invalidColor = const Color(0xFFD93025),
    this.unrecognizedColor = const Color(0xFFE8710A),
    this.noCredentialColor = const Color(0xFF9E9E9E),
    this.surfaceColor = const Color(0xFFFFFFFF),
    this.surfaceVariantColor = const Color(0xFFF5F5F5),
    this.borderColor = const Color(0xFFE0E0E0),
    this.textPrimaryColor = const Color(0xFF1A1A1A),
    this.textSecondaryColor = const Color(0xFF6B6B6B),
    this.iconColor = const Color(0xFF6B6B6B),
    this.selectedNodeBorderColor = const Color(0xFF1A73E8),
    this.pathNodeBorderColor = const Color(0xFF5F6368),
    this.defaultNodeBorderColor = const Color(0xFFDADCE0),
    this.edgeColor = const Color(0xFFDADCE0),
    this.titleLargeStyle = const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    this.titleMediumStyle = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    this.titleSmallStyle = const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    this.bodyStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    this.bodySmallStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    this.labelStyle = const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.3,
    ),
    this.sidebarWidth = 360,
    this.thumbnailSize = 280,
    this.nodeWidth = 200,
    this.nodeHeight = 100,
    this.nodeSpacingX = 60,
    this.nodeSpacingY = 80,
    this.cardRadius = const BorderRadius.all(Radius.circular(12)),
    this.sectionRadius = const BorderRadius.all(Radius.circular(8)),
  });

  static const C2paViewerThemeData defaults = C2paViewerThemeData();

  factory C2paViewerThemeData.dark() => const C2paViewerThemeData(
        surfaceColor: Color(0xFF1E1E1E),
        surfaceVariantColor: Color(0xFF2D2D2D),
        borderColor: Color(0xFF424242),
        textPrimaryColor: Color(0xFFE0E0E0),
        textSecondaryColor: Color(0xFF9E9E9E),
        iconColor: Color(0xFF9E9E9E),
        selectedNodeBorderColor: Color(0xFF8AB4F8),
        pathNodeBorderColor: Color(0xFF9AA0A6),
        defaultNodeBorderColor: Color(0xFF5F6368),
        edgeColor: Color(0xFF5F6368),
        titleLargeStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: Color(0xFFE0E0E0),
        ),
        titleMediumStyle: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: Color(0xFFE0E0E0),
        ),
        titleSmallStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.3,
          color: Color(0xFFE0E0E0),
        ),
        bodyStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          height: 1.5,
          color: Color(0xFFE0E0E0),
        ),
        bodySmallStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          height: 1.4,
          color: Color(0xFF9E9E9E),
        ),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          height: 1.3,
          color: Color(0xFF9E9E9E),
        ),
      );

  Color colorForStatus(ValidationStatus status) {
    switch (status) {
      case ValidationStatus.valid:
        return validColor;
      case ValidationStatus.invalid:
        return invalidColor;
      case ValidationStatus.untrusted:
        return unrecognizedColor;
      case ValidationStatus.unrecognized:
        return unrecognizedColor;
      case ValidationStatus.noCredential:
        return noCredentialColor;
    }
  }
}

/// InheritedWidget providing [C2paViewerThemeData] to descendant widgets.
class C2paViewerTheme extends InheritedWidget {
  final C2paViewerThemeData data;

  const C2paViewerTheme({
    super.key,
    required this.data,
    required super.child,
  });

  static C2paViewerThemeData of(BuildContext context) {
    final theme =
        context.dependOnInheritedWidgetOfExactType<C2paViewerTheme>();
    return theme?.data ?? C2paViewerThemeData.defaults;
  }

  @override
  bool updateShouldNotify(C2paViewerTheme oldWidget) => data != oldWidget.data;
}
