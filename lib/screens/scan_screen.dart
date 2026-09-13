import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../models/scan_record.dart';
import '../services/content_parser.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/layout_constants.dart';
import '../widgets/scan_frame_overlay.dart';
import 'result_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final barcode = capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final value = barcode?.rawValue;
    if (barcode == null || value == null || value.isEmpty) return;

    setState(() => _isProcessing = true);
    await _controller.stop();

    final parsed = ContentParser.parse(value);
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

    final parsed = ContentParser.parse(value);
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
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleDetect,
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                // The scan frame is placed inside this Expanded, so Flutter's
                // layout system guarantees it only ever occupies the space
                // left over between the header and the controls below —
                // it structurally cannot overlap either one, on any device.
                const Expanded(child: ScanFrameOverlay()),
                _buildHint(),
                const SizedBox(height: 28),
                _buildControls(),
                const SizedBox(height: kNavBarClearance),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.35),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Scan',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
              ),
              Text(
                'Point your camera at a QR or barcode',
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
          _circleButton(
            icon: _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
            active: _torchOn,
            onTap: () async {
              await _controller.toggleTorch();
              setState(() => _torchOn = !_torchOn);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(30),
      ),
      child: const Text(
        'Align the code within the frame',
        style: TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _circleButton(
          icon: Icons.cameraswitch_rounded,
          onTap: () => _controller.switchCamera(),
        ),
        const SizedBox(width: 18),
        _circleButton(
          icon: Icons.image_outlined,
          onTap: _pickFromGallery,
          tooltip: 'Scan from a photo',
        ),
      ],
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback onTap,
    bool active = false,
    String? tooltip,
  }) {
    final button = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: active ? AppColors.brandGradient : null,
          color: active ? null : Colors.white.withOpacity(0.12),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
  }
}
