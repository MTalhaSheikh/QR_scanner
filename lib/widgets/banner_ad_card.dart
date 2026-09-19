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
      size: AdSize.largeBanner,
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
