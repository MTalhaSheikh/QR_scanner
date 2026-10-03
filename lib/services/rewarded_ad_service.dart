import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ad_config.dart';

/// Shows a rewarded ad before a Save/Share action — but only on every
/// *other* attempt: 1st time → no ad, 2nd time → ad, 3rd → no ad, 4th →
/// ad, and so on, forever. The count is persisted (SharedPreferences), so
/// it keeps alternating correctly across app restarts rather than
/// resetting to "1st time" every time the app reopens.
///
/// USAGE: wrap whatever your Save/Share button actually does:
/// ```dart
/// onPressed: () => RewardedAdService.instance.runGated(_shareCode),
/// ```
/// `_shareCode` only runs once the ad (if this was an "ad" turn) has been
/// shown and closed, or immediately if this was a "skip" turn, or
/// immediately if no ad could be loaded in time (never blocks the actual
/// feature just because an ad failed to load — see the comment on
/// [runGated] for the exact fallback behavior).
class RewardedAdService {
  RewardedAdService._();
  static final RewardedAdService instance = RewardedAdService._();

  static const _countKey = 'rewarded_ad_save_share_count_v1';

  RewardedAd? _preloadedAd;
  bool _isLoading = false;

  /// Call once at app startup (or lazily before the first Save/Share) to
  /// have an ad ready and waiting instead of loading one right when the
  /// user taps Save/Share, which would add a visible delay.
  void preload() {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_preloadedAd != null || _isLoading) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: AdConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _preloadedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          if (kDebugMode) debugPrint('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  /// Runs [action] — showing a rewarded ad first if this is one of the
  /// "show" turns in the 1-skip/2-show alternating pattern. [action] is
  /// always eventually called exactly once, whether or not an ad was
  /// actually shown (no ad ready in time / failed to load / unsupported
  /// platform all just fall through to running the action directly,
  /// rather than blocking Save/Share because of an ad problem).
  Future<void> runGated(Future<void> Function() action) async {
    final shouldShowAd = await _incrementAndCheckIfAdTurn();

    if (!shouldShowAd || (!Platform.isAndroid && !Platform.isIOS)) {
      await action();
      return;
    }

    final ad = _preloadedAd;
    _preloadedAd = null; // each loaded ad is single-use

    if (ad == null) {
      // Nothing preloaded in time — don't make the user wait on a cold
      // load just to Save/Share; run the action and try to have one
      // ready for next time.
      preload();
      await action();
      return;
    }

    final completer = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Whether or not the user actually watches to completion and "earns"
    // the reward, Save/Share proceeds once the ad is dismissed — this
    // app doesn't gate the feature on reward completion, just on the ad
    // having been shown.
    await ad.show(onUserEarnedReward: (ad, reward) {});
    await completer.future;

    preload(); // line up the next one
    await action();
  }

  Future<bool> _incrementAndCheckIfAdTurn() async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt(_countKey) ?? 0) + 1;
    await prefs.setInt(_countKey, count);
    return count % 2 == 0; // 2nd, 4th, 6th, ... turn shows the ad
  }
}
