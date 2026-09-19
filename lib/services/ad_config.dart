import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Centralized AdMob setup.
///
/// IMPORTANT — before you publish this app, replace every ID below with
/// your own real AdMob App ID / Ad Unit IDs from https://apps.admob.com.
/// The IDs here are Google's official *test* IDs — they always serve a
/// placeholder "Test Ad" and are safe to leave in during development, but
/// using test IDs (or your real IDs without real traffic) in a published
/// app is fine; using someone else's real IDs, or clicking your own real
/// ads to test them, violates AdMob policy and can get an account banned.
class AdConfig {
  AdConfig._();

  /// Set this to `false` once you've dropped in your real AdMob IDs below.
  static const bool useTestAds = true;

  // ---- App IDs (also required in AndroidManifest.xml / Info.plist) ----
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppId = 'ca-app-pub-3940256099942544~1458002511';

  // ---- Banner ad unit IDs ----
  static const String _androidTestBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBanner = 'ca-app-pub-3940256099942544/2934735716';

  // TODO: put your real banner ad unit IDs here, then set useTestAds = false.
  static const String _androidRealBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosRealBanner = 'ca-app-pub-3940256099942544/2934735716';

  static String get bannerAdUnitId {
    if (Platform.isAndroid) return useTestAds ? _androidTestBanner : _androidRealBanner;
    if (Platform.isIOS) return useTestAds ? _iosTestBanner : _iosRealBanner;
    return _androidTestBanner;
  }

  static Future<void> init() async {
    // Ads aren't supported on the web/desktop targets this project doesn't
    // ship to, but guard anyway so a stray platform never crashes startup.
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    await MobileAds.instance.initialize();
  }
}
