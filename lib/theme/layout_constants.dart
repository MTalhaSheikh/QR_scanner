/// The floating bottom nav bar (see widgets/floating_nav_bar.dart) is ~64px
/// tall plus 8px internal padding and a 32px+ outer margin (it also adds
/// the device's own bottom safe-area inset on top of that). Screens whose
/// content or fixed action bars sit above it should reserve at least this
/// much space so nothing is ever hidden underneath it.
const double kNavBarClearance = 128.0;

/// Extra breathing room used for scrollable list/grid bottom padding, so
/// the last item never sits flush against the nav bar.
const double kScrollBottomPadding = 170.0;
