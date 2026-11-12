enum WindowSize {
  compact,
  medium,
  expanded,
  large,
  extraLarge;

  static WindowSize fromWidth(double width) {
    if (width < 600) return WindowSize.compact;
    if (width < 840) return WindowSize.medium;
    if (width < 1200) return WindowSize.expanded;
    if (width < 1600) return WindowSize.large;
    return WindowSize.extraLarge;
  }

  bool get showsTwoPanes => index >= WindowSize.expanded.index;
}
