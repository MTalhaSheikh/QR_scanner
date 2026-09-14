import 'dart:io';
import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/scan_record.dart';
import '../services/history_service.dart';
import '../theme/app_colors.dart';
import '../theme/layout_constants.dart';

enum QrContentType { text, url, wifi, contact, email, phone, sms }

class GenerateScreen extends StatefulWidget {
  const GenerateScreen({super.key});

  @override
  State<GenerateScreen> createState() => _GenerateScreenState();
}

class _GenerateScreenState extends State<GenerateScreen> {
  bool _isQr = true;
  QrContentType _qrType = QrContentType.text;
  Barcode _barcodeType = Barcode.code128();
  Color _qrColor = AppColors.primary;
  File? _logoImage;

  final _screenshotController = ScreenshotController();

  // Field controllers
  final _text = TextEditingController(text: 'Hello, ScanCraft!');
  final _url = TextEditingController(text: 'https://example.com');
  final _wifiSsid = TextEditingController();
  final _wifiPassword = TextEditingController();
  bool _wifiHidden = false;
  final _contactName = TextEditingController();
  final _contactPhone = TextEditingController();
  final _contactEmail = TextEditingController();
  final _emailAddress = TextEditingController();
  final _emailSubject = TextEditingController();
  final _phone = TextEditingController();
  final _smsNumber = TextEditingController();
  final _smsMessage = TextEditingController();
  final _barcodeText = TextEditingController(text: '1234567890');

  @override
  void dispose() {
    for (final c in [
      _text,
      _url,
      _wifiSsid,
      _wifiPassword,
      _contactName,
      _contactPhone,
      _contactEmail,
      _emailAddress,
      _emailSubject,
      _phone,
      _smsNumber,
      _smsMessage,
      _barcodeText,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _qrData {
    switch (_qrType) {
      case QrContentType.text:
        return _text.text;
      case QrContentType.url:
        final v = _url.text.trim();
        return v.startsWith('http') ? v : 'https://$v';
      case QrContentType.wifi:
        return 'WIFI:T:WPA;S:${_wifiSsid.text};P:${_wifiPassword.text};H:${_wifiHidden ? 'true' : 'false'};;';
      case QrContentType.contact:
        return 'BEGIN:VCARD\nVERSION:3.0\nFN:${_contactName.text}\nTEL:${_contactPhone.text}\nEMAIL:${_contactEmail.text}\nEND:VCARD';
      case QrContentType.email:
        return 'mailto:${_emailAddress.text}?subject=${Uri.encodeComponent(_emailSubject.text)}';
      case QrContentType.phone:
        return 'tel:${_phone.text}';
      case QrContentType.sms:
        return 'SMSTO:${_smsNumber.text}:${_smsMessage.text}';
    }
  }

  bool get _hasContent {
    if (!_isQr) return _barcodeText.text.trim().isNotEmpty;
    switch (_qrType) {
      case QrContentType.text:
        return _text.text.trim().isNotEmpty;
      case QrContentType.url:
        return _url.text.trim().isNotEmpty;
      case QrContentType.wifi:
        return _wifiSsid.text.trim().isNotEmpty;
      case QrContentType.contact:
        return _contactName.text.trim().isNotEmpty;
      case QrContentType.email:
        return _emailAddress.text.trim().isNotEmpty;
      case QrContentType.phone:
        return _phone.text.trim().isNotEmpty;
      case QrContentType.sms:
        return _smsNumber.text.trim().isNotEmpty;
    }
  }

  Future<File> _captureImage() async {
    // Give an embedded logo file image a brief moment to finish decoding
    // before capturing, so it isn't missing from the exported PNG.
    if (_isQr && _logoImage != null) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
    final bytes = await _screenshotController.capture(pixelRatio: 3.0);
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/scancraft_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes!);
    return file;
  }

  Future<void> _saveToHistory() async {
    final label = _isQr ? _qrType.name : _barcodeType.runtimeType.toString();
    final record = ScanRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      source: RecordSource.generated,
      symbology: _isQr ? 'QR_CODE' : _barcodeSymbologyName,
      contentType: _isQr ? _qrType.name : 'barcode',
      rawValue: _isQr ? _qrData : _barcodeText.text,
      displayLabel: _isQr ? _previewTitle : _barcodeText.text,
      timestamp: DateTime.now(),
    );
    await HistoryService.instance.add(record);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved to history · $label')),
    );
  }

  String get _barcodeSymbologyName {
    final t = _barcodeType.runtimeType.toString();
    return t.replaceAll('Barcode', '').toUpperCase();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (photo == null) return;
    setState(() => _logoImage = File(photo.path));
  }

  void _removeLogo() => setState(() => _logoImage = null);

  Future<void> _shareCode() async {
    final file = await _captureImage();
    await Share.shareXFiles([XFile(file.path)],
        text: _isQr ? _qrData : _barcodeText.text);
    await _saveToHistory();
  }

  String get _previewTitle {
    switch (_qrType) {
      case QrContentType.text:
        return _text.text;
      case QrContentType.url:
        return _url.text;
      case QrContentType.wifi:
        return _wifiSsid.text;
      case QrContentType.contact:
        return _contactName.text;
      case QrContentType.email:
        return _emailAddress.text;
      case QrContentType.phone:
        return _phone.text;
      case QrContentType.sms:
        return _smsNumber.text;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildPreviewCard(context)),
            SliverToBoxAdapter(child: _buildModeSwitch(context)),
            SliverToBoxAdapter(
              child: _isQr ? _buildQrTypeSelector(context) : _buildBarcodeTypeSelector(context),
            ),
            if (_isQr) SliverToBoxAdapter(child: _buildColorPicker(context)),
            if (_isQr) SliverToBoxAdapter(child: _buildLogoPicker(context)),
            SliverPadding(
              // Bottom padding clears the root floating nav bar, since this
              // screen no longer pins its own action bar above it.
              padding: const EdgeInsets.fromLTRB(20, 8, 20, kNavBarClearance + 24),
              sliver: SliverToBoxAdapter(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _isQr ? _buildQrForm() : _buildBarcodeForm(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Create', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Row(
            children: [
              _headerActionButton(
                context: context,
                icon: Icons.bookmark_outline_rounded,
                onTap: _hasContent ? _saveToHistory : null,
                tooltip: 'Save to history',
              ),
              const SizedBox(width: 10),
              _headerActionButton(
                context: context,
                icon: Icons.ios_share_rounded,
                onTap: _hasContent ? _shareCode : null,
                tooltip: 'Share',
                filled: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback? onTap,
    required String tooltip,
    bool filled = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = onTap != null;
    final active = filled && enabled;

    final circle = Container(
      width: 42,
      height: 42,
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
        size: 19,
        color: active
            ? Colors.white
            : (enabled
                ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)
                : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
      ),
    );

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: circle),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(isDark ? 0.35 : 0.25),
              blurRadius: 30,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        child: Center(
          child: Screenshot(
            controller: _screenshotController,
            child: Container(
              padding: const EdgeInsets.all(20),
              // Deliberately NOT rounded: this exact container is what gets
              // captured for Save/Share. A rounded corner here means the
              // four corner triangles are genuinely transparent in the
              // exported PNG — which viewers like WhatsApp's dark media
              // preview render as solid black instead of "no background".
              // A plain rectangle has no transparent pixels at all, so
              // there's nothing for any viewer to render incorrectly. The
              // rounded look in the app itself still comes from the
              // gradient card framing it.
              decoration: const BoxDecoration(color: Colors.white),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: _hasContent
                    ? (_isQr
                        ? Stack(
                            key: const ValueKey('qr'),
                            alignment: Alignment.center,
                            children: [
                              QrImageView(
                                data: _qrData,
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                // A logo sitting on top of the code blocks
                                // some of its data modules — bumping error
                                // correction to the highest level (H, ~30%
                                // recoverable) keeps it reliably scannable
                                // with a logo on it.
                                errorCorrectionLevel: _logoImage != null
                                    ? QrErrorCorrectLevel.H
                                    : QrErrorCorrectLevel.M,
                                eyeStyle: QrEyeStyle(eyeShape: QrEyeShape.square, color: _qrColor),
                                dataModuleStyle: QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square, color: _qrColor),
                              ),
                              // Drawn separately (rather than via qr_flutter's
                              // built-in embeddedImage, which paints it as a
                              // plain square) so the logo can be clipped to a
                              // circle with a clean white badge behind it.
                              if (_logoImage != null)
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(3),
                                  child: ClipOval(
                                    child: Image.file(
                                      _logoImage!,
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : BarcodeWidget(
                            key: const ValueKey('bc'),
                            barcode: _barcodeType,
                            data: _barcodeText.text,
                            width: 240,
                            height: 120,
                            drawText: true,
                            errorBuilder: (context, error) => SizedBox(
                              width: 240,
                              height: 120,
                              child: Center(
                                child: Text(
                                  'Invalid data for this barcode type',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red.shade400, fontSize: 12),
                                ),
                              ),
                            ),
                          ))
                    : const SizedBox(
                        key: ValueKey('empty'),
                        width: 200,
                        height: 200,
                        child: Center(
                          child: Icon(Icons.qr_code_2_rounded, size: 64, color: Color(0xFFE0E0EE)),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1F1F38)
              : const Color(0xFFF0F1F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(child: _modeTab('QR Code', _isQr, () => setState(() => _isQr = true))),
            Expanded(child: _modeTab('Barcode', !_isQr, () => setState(() => _isQr = false))),
          ],
        ),
      ),
    );
  }

  Widget _modeTab(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildQrTypeSelector(BuildContext context) {
    final options = {
      QrContentType.text: ('Text', Icons.notes_rounded),
      QrContentType.url: ('URL', Icons.link_rounded),
      QrContentType.wifi: ('Wi-Fi', Icons.wifi_rounded),
      QrContentType.contact: ('Contact', Icons.person_rounded),
      QrContentType.email: ('Email', Icons.email_rounded),
      QrContentType.phone: ('Phone', Icons.phone_rounded),
      QrContentType.sms: ('SMS', Icons.sms_rounded),
    };
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: options.entries.map((e) {
          final selected = _qrType == e.key;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final unselectedColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(e.value.$2, size: 16, color: selected ? Colors.white : unselectedColor),
              label: Text(
                e.value.$1,
                style: TextStyle(color: selected ? Colors.white : unselectedColor),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _qrType = e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarcodeTypeSelector(BuildContext context) {
    final options = <String, Barcode>{
      'Code 128': Barcode.code128(),
      'Code 39': Barcode.code39(),
      'EAN-13': Barcode.ean13(),
      'UPC-A': Barcode.upcA(),
      'ITF': Barcode.itf(),
    };
    return SizedBox(
      height: 46,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: options.entries.map((e) {
          final selected = _barcodeType.runtimeType == e.value.runtimeType;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                e.key,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _barcodeType = e.value),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildColorPicker(BuildContext context) {
    const colors = [
      AppColors.primary,
      Color(0xFF1B1B2E),
      AppColors.coral,
      AppColors.success,
      AppColors.amber,
      Color(0xFF0E7C86),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: SizedBox(
        height: 40,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: colors.map((c) {
            final selected = c.value == _qrColor.value;
            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: GestureDetector(
                onTap: () => setState(() => _qrColor = c),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: selected ? Border.all(color: Colors.grey.shade400, width: 3) : null,
                  ),
                  child: selected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLogoPicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickLogo,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? AppColors.darkCard : const Color(0xFFF0F1F8),
                image: _logoImage != null
                    ? DecorationImage(image: FileImage(_logoImage!), fit: BoxFit.cover)
                    : null,
                border: Border.all(
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  width: 1,
                ),
              ),
              child: _logoImage == null
                  ? Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 18,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _logoImage == null ? 'Add a logo to the center' : 'Logo added',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
          if (_logoImage != null) ...[
            const Spacer(),
            TextButton(
              onPressed: _removeLogo,
              child: const Text('Remove', style: TextStyle(color: AppColors.coral)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQrForm() {
    switch (_qrType) {
      case QrContentType.text:
        return _fieldGroup([_field(_text, 'Enter your text', maxLines: 4)]);
      case QrContentType.url:
        return _fieldGroup([_field(_url, 'https://your-link.com')]);
      case QrContentType.wifi:
        return _fieldGroup([
          _field(_wifiSsid, 'Network name (SSID)'),
          const SizedBox(height: 12),
          _field(_wifiPassword, 'Password', obscure: true),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _wifiHidden,
            title: const Text('Hidden network'),
            onChanged: (v) => setState(() => _wifiHidden = v),
          ),
        ]);
      case QrContentType.contact:
        return _fieldGroup([
          _field(_contactName, 'Full name'),
          const SizedBox(height: 12),
          _field(_contactPhone, 'Phone number'),
          const SizedBox(height: 12),
          _field(_contactEmail, 'Email address'),
        ]);
      case QrContentType.email:
        return _fieldGroup([
          _field(_emailAddress, 'Recipient email'),
          const SizedBox(height: 12),
          _field(_emailSubject, 'Subject (optional)'),
        ]);
      case QrContentType.phone:
        return _fieldGroup([_field(_phone, 'Phone number')]);
      case QrContentType.sms:
        return _fieldGroup([
          _field(_smsNumber, 'Phone number'),
          const SizedBox(height: 12),
          _field(_smsMessage, 'Message (optional)', maxLines: 3),
        ]);
    }
  }

  Widget _buildBarcodeForm() {
    return _fieldGroup([
      _field(_barcodeText, 'Data to encode'),
      const SizedBox(height: 8),
      Text(
        'Tip: EAN-13 and UPC-A require the exact digit length for that standard.',
        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
      ),
    ]);
  }

  Widget _fieldGroup(List<Widget> children) {
    return Column(
      key: ValueKey(_isQr ? _qrType : _barcodeType.runtimeType),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  Widget _field(TextEditingController controller, String hint,
      {int maxLines = 1, bool obscure = false}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      obscureText: obscure,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(hintText: hint),
    );
  }
}
