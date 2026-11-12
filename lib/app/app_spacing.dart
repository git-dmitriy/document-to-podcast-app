import 'dart:ui';

import 'package:flutter/material.dart';

import 'window_size.dart';

@immutable
class AppSpacing extends ThemeExtension<AppSpacing> {
  const AppSpacing({
    required this.pagePadding,
    required this.sectionGap,
    required this.readingMaxWidth,
  });

  final double pagePadding;
  final double sectionGap;
  final double readingMaxWidth;

  static AppSpacing forWidth(double width) {
    final size = WindowSize.fromWidth(width);
    return switch (size) {
      WindowSize.compact => const AppSpacing(
        pagePadding: 16,
        sectionGap: 12,
        readingMaxWidth: 760,
      ),
      WindowSize.medium => const AppSpacing(
        pagePadding: 24,
        sectionGap: 16,
        readingMaxWidth: 760,
      ),
      _ => const AppSpacing(
        pagePadding: 32,
        sectionGap: 24,
        readingMaxWidth: 760,
      ),
    };
  }

  static AppSpacing of(BuildContext context) {
    final existing = Theme.of(context).extension<AppSpacing>();
    if (existing != null) return existing;
    return AppSpacing.forWidth(MediaQuery.sizeOf(context).width);
  }

  @override
  AppSpacing copyWith({
    double? pagePadding,
    double? sectionGap,
    double? readingMaxWidth,
  }) {
    return AppSpacing(
      pagePadding: pagePadding ?? this.pagePadding,
      sectionGap: sectionGap ?? this.sectionGap,
      readingMaxWidth: readingMaxWidth ?? this.readingMaxWidth,
    );
  }

  @override
  AppSpacing lerp(ThemeExtension<AppSpacing>? other, double t) {
    if (other is! AppSpacing) return this;
    return AppSpacing(
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t) ?? pagePadding,
      sectionGap: lerpDouble(sectionGap, other.sectionGap, t) ?? sectionGap,
      readingMaxWidth:
          lerpDouble(readingMaxWidth, other.readingMaxWidth, t) ??
          readingMaxWidth,
    );
  }
}
