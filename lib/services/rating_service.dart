import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps the native "rate this app" popup — Google Play's **In-App
/// Review** API on Android, `SKStoreReviewController` on iOS. Both show a
/// small popup right inside the app; the user rates without ever leaving
/// it or seeing a browser/store page.
///
/// WHY NOT JUST CALL IT WHENEVER YOU WANT: both platforms silently
/// enforce their own quota (roughly a handful of times per app per year)
/// regardless of how often your code asks — spamming the request doesn't
/// get you more prompts, it just risks asking at a bad moment for the one
/// or two chances you actually get. So this service:
/// - only asks after the person has done something that indicates a good
///   moment (a successful scan) — never on cold app open
/// - asks at most once per install of its own accord (tracked locally),
///   so even across the handful of times the OS *would* allow it, this
///   app doesn't hammer the same happy user repeatedly
/// - still gives you [openStoreListing] for a manual "Rate us" button
///   somewhere in your UI (e.g. a settings screen), which always works —
///   including on the small fraction of devices where the in-app popup
///   API isn't available at all (falls back to opening the store page)
class RatingService {
  RatingService._();

  static const _hasAskedKey = 'rating_service_has_asked_v1';
  static const _successfulScansKey = 'rating_service_scan_count_v1';

  /// Call this after something goes right (e.g. a successful scan). Once
  /// the count crosses [threshold] and we haven't asked before, this
  /// triggers the native review popup — otherwise it's a no-op.
  static Future<void> recordPositiveMomentAndMaybeAsk({int threshold = 5}) async {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool(_hasAskedKey) ?? false) return;

    final count = (prefs.getInt(_successfulScansKey) ?? 0) + 1;
    await prefs.setInt(_successfulScansKey, count);

    if (count < threshold) return;

    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await prefs.setBool(_hasAskedKey, true);
      await inAppReview.requestReview();
    }
  }

  /// For a manual "Rate us" button — always takes the user somewhere
  /// useful: the native popup if it's available, otherwise straight to
  /// the app's Play Store / App Store listing page.
  static Future<void> openStoreListing() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // TODO: replace with your real store IDs once published.
      await inAppReview.openStoreListing(
        appStoreId: 'YOUR_APPLE_APP_ID',
        microsoftStoreId: null,
      );
    }
  }
}
