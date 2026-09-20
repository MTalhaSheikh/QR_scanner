import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/scan_record.dart';
import '../services/content_parser.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/layout_constants.dart';
import '../widgets/banner_ad_card.dart';
import '../widgets/scan_frame_overlay.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  /// Whether this tab is the one currently visible. RootShell keeps every
  /// tab mounted (via IndexedStack) so switching tabs is instant and state
  /// isn't lost — but that means the camera would otherwise keep running
  /// in the background on other tabs unless we explicitly pause it here.
  final bool isActive;

  const ScanScreen({super.key, required this.isActive});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.qrCode,
      BarcodeFormat.aztec,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.code128,
      BarcodeFormat.dataMatrix,
      BarcodeFormat.ean8,
      BarcodeFormat.ean13,
      BarcodeFormat.itf,
      BarcodeFormat.pdf417,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
    ],
  );

  bool _torchOn = false;
  bool _isProcessing = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  Future<void> _playScanFeedback() async {
    // HapticFeedback.vibrate() triggers a real, short device buzz on both
    // platforms; the "impact" style constants are tuned for iOS's Taptic
    // Engine and are inconsistent-to-silent on a lot of Android hardware.
    HapticFeedback.vibrate();
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/beep.wav'), volume: 1.0);
    } catch (_) {
      // Never let a missing audio focus / muted device crash the scan flow.
    }
  }

  @override
  void initState() {
    super.initState();
    // MobileScanner auto-starts the camera as soon as it's mounted. If this
    // tab isn't the visible one on first build, stop it right away.
    if (!widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _controller.stop());
    }
  }

  @override
  void didUpdateWidget(covariant ScanScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive == oldWidget.isActive) return;
    if (widget.isActive) {
      _controller.start();
    } else {
      _controller.stop();
      if (_torchOn) setState(() => _torchOn = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final value = barcode?.rawValue;
    if (barcode == null || value == null || value.isEmpty) return;

    // Confirm the catch with a real device buzz + an actual beep tone —
    // more reliable than the OS "system click" sound, which is inaudible
    // on a lot of Android devices.
    _playScanFeedback();

    setState(() => _isProcessing = true);
    await _controller.stop();

    final parsed = ContentParser.parse(value, symbology: barcode.format.name);
    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      source: RecordSource.scanned,
      symbology: barcode.format.name,
      contentType: parsed.type,
      rawValue: value,
      displayLabel: parsed.title,
      timestamp: DateTime.now(),
    );
    await HistoryService.instance.add(record);

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);
    await _controller.start();
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery);
    if (photo == null) return;

    setState(() => _isProcessing = true);
    final capture = await _controller.analyzeImage(photo.path);
    setState(() => _isProcessing = false);

    if (capture == null || capture.barcodes.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No QR code or barcode found in that image')),
      );
      return;
    }

    final value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    _playScanFeedback();

    final parsed = ContentParser.parse(value, symbology: capture.barcodes.first.format.name);
    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      source: RecordSource.scanned,
      symbology: capture.barcodes.first.format.name,
      contentType: parsed.type,
      rawValue: value,
      displayLabel: parsed.title,
      timestamp: DateTime.now(),
    );
    await HistoryService.instance.add(record);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ResultScreen(record: record)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      // No explicit backgroundColor — inherits the same themed scaffold
      // background as Create/History, unlike the old always-dark version.
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 12),
            // The camera preview now lives inside a themed card, matching
            // the QR preview card on the Create screen, instead of taking
            // over the whole screen behind a dark scrim.
            Expanded(child: _buildCameraCard(isDark)),
            const SizedBox(height: 18),
            _buildHint(isDark),
            const SizedBox(height: 20),
            _buildControls(isDark),
            const SizedBox(height: 16),
            const Center(child: BannerAdCard()),
            SizedBox(height: kNavBarClearance),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Scan', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              SizedBox(height: 2),
              Text(
                'Point your camera at a QR or barcode',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
            ],
          ),
          _actionButton(
            icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            active: _torchOn,
            isDark: isDark,
            onTap: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCameraCard(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: _handleDetect,
            ),
            // Confined to this card's bounds by construction (it fills
            // whatever box its parent gives it) — it can't bleed over the
            // header or footer the way the old full-screen version could.
            const ScanFrameOverlay(),
            if (_isProcessing)
              Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHint(bool isDark) {
    return Text(
      'Align the code within the frame',
      style: TextStyle(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildControls(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _actionButton(
          icon: Icons.cameraswitch_rounded,
          isDark: isDark,
          onTap: () => _controller.switchCamera(),
        ),
        const SizedBox(width: 18),
        _actionButton(
          icon: Icons.image_outlined,
          isDark: isDark,
          onTap: _pickFromGallery,
          tooltip: 'Scan from a photo',
        ),
      ],
    );
  }

  /// Same visual language as the Save/Share header buttons on the Create
  /// screen: a neutral card-grey circle normally, and the brand gradient
  /// when active — so Scan finally looks like part of the same app.
  Widget _actionButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
    bool active = false,
    String? tooltip,
  }) {
    final circle = Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: active ? AppColors.brandGradient : null,
        color: active ? null : (isDark ? AppColors.darkCard : const Color(0xFFF0F1F8)),
        boxShadow: active
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 22,
        color: active ? Colors.white : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
      ),
    );

    final button = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: circle),
    );

    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
  }
}
