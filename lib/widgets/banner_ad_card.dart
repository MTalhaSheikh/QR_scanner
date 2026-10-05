import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/ad_config.dart';
import '../theme/app_colors.dart';

/// A banner ad that fits itself into the layout cleanly:
/// - reserves no space at all until an ad has actually loaded (so there's
///   never an awkward empty gray box while waiting on the network)
/// - collapses back to nothing if the ad fails to load, instead of
///   leaving a dead placeholder
/// - disposes the underlying [BannerAd] correctly when removed
class BannerAdCard extends StatefulWidget {
  const BannerAdCard({super.key});

  @override
  State<BannerAdCard> createState() => _BannerAdCardState();
}

class _BannerAdCardState extends State<BannerAdCard> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    final banner = BannerAd(
      adUnitId: AdConfig.bannerAdUnitId,
      // Standard banner (320x50), not largeBanner (320x100) — it's the
      // most universally-requested size across the whole ad network, so
      // it typically has noticeably better fill rate, especially useful
      // while a brand-new ad unit is still "warming up" with advertisers.
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Logged (debug builds only) so a silently-collapsing ad slot
          // doesn't look identical to "the code is broken" — check this
          // line in your console before assuming it's a bug. Error code 3
          // ("no fill") is expected and harmless for a brand-new ad unit
          // on an unapproved AdMob app; codes 0/1/2 point at an actual
          // config problem (invalid ad unit ID, no network, malformed
          // request) worth investigating.
          if (kDebugMode) {
            debugPrint('Banner ad failed to load: code=${error.code} message=${error.message}');
          }
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    );
    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
