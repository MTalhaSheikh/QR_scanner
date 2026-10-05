import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob setup.
///
/// ANDROID — real IDs are now wired in below (from your AdMob "QR code
/// scanner" app, created Oct 2026).
///
/// IOS — still Google's *test* IDs below (placeholders). You haven't set
/// up an iOS app in AdMob yet, so there's nothing real to put here. These
/// test IDs are completely safe to ship as-is in the meantime: they're
/// Google's official public sample ad units, so they'll never error or
/// crash, they just always serve a harmless "Test Ad" placeholder — i.e.
/// no iOS ad revenue until you repeat the AdMob setup for iOS and swap
/// these two for real ones.
///
/// Using someone else's real IDs, or clicking your own real ads to "test"
/// them, violates AdMob policy and can get an account banned — never do
/// either of those.
class AdConfig {
  AdConfig._();

  /// Real Android IDs are in place, so this is off. Flip back to `true`
  /// only if you ever want to temporarily force test ads again (e.g. to
  /// debug something) without touching the IDs below.
  static const bool useTestAds = false;

  // ---- App IDs (also required in AndroidManifest.xml / Info.plist) ----
  static const String androidAppId = 'ca-app-pub-6613460832066685~5550783455';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511'; // TODO: set up iOS in AdMob

  // ---- Banner ad unit IDs ----
  static const String _androidTestBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';

  static const String _androidRealBanner = 'ca-app-pub-6613460832066685/6480721740';
  static const String _iosRealBanner = 'ca-app-pub-3940256099942544/2934735716'; // TODO: real iOS banner ID

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return useTestAds ? _androidTestBanner : _androidRealBanner;
    if (Platform.isIOS) return useTestAds ? _iosTestBanner : _iosRealBanner;
    return _androidTestBanner;
  }

  // ---- Rewarded ad unit IDs (shown before Save/Share, every other time —
  // see services/rewarded_ad_service.dart) ----
  static const String _androidTestRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const String _iosTestRewarded = 'ca-app-pub-3940256099942544/1712485313';

  static const String _androidRealRewarded = 'ca-app-pub-6613460832066685/1280365952';
  static const String _iosRealRewarded = 'ca-app-pub-3940256099942544/1712485313'; // TODO: real iOS rewarded ID

  static String get rewardedAdUnitId {
    if (Platform.isAndroid) return useTestAds ? _androidTestRewarded : _androidRealRewarded;
    if (Platform.isIOS) return useTestAds ? _iosTestRewarded : _iosRealRewarded;
    return _androidTestRewarded;
  }

  static Future<void> init() async {
    // Ads aren't supported on the web/desktop targets this project doesn't
    // ship to, but guard anyway so a stray platform never crashes startup.
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await MobileAds.instance.initialize();
  }
}
