class SprintBreakpoints {
  static const double compactMaxWidth = 599;
  static const double regularMaxWidth = 1023;

  static bool isCompact(double width) => width <= compactMaxWidth;

  static bool isRegular(double width) =>
      width > compactMaxWidth && width <= regularMaxWidth;

  static bool isWide(double width) => width > regularMaxWidth;
}
