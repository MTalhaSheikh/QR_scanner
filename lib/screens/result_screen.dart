import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/scan_record.dart';
import '../services/content_parser.dart';
import '../theme/app_colors.dart';

class ResultScreen extends StatelessWidget {
  final ScanRecord record;
  const ResultScreen({super.key, required this.record});

  Color get _color => AppColors.typeColors[record.contentType] ?? AppColors.primary;

  IconData get _icon {
    switch (record.contentType) {
      case 'url':
        return Icons.link_rounded;
      case 'wifi':
        return Icons.wifi_rounded;
      case 'contact':
        return Icons.person_rounded;
      case 'email':
        return Icons.email_rounded;
      case 'phone':
        return Icons.phone_rounded;
      case 'sms':
        return Icons.sms_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  Future<void> _launch(BuildContext context, String uri) async {
    final u = Uri.tryParse(uri);
    if (u == null) {
      _showLaunchError(context);
      return;
    }
    try {
      final launched = await launchUrl(u, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) _showLaunchError(context);
    } catch (_) {
      if (context.mounted) _showLaunchError(context);
    }
  }

  void _showLaunchError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Couldn't open that — no app found to handle it")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final parsed = ContentParser.parse(record.rawValue);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Share.share(record.rawValue),
                    icon: const Icon(Icons.ios_share_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 84,
                height: 84,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(_icon, color: _color, size: 38),
              ),
              const SizedBox(height: 18),
              Text(
                parsed.subtitle.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                record.symbology.replaceAll('_', ' '),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkCard
                              : AppColors.lightCard,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SelectableText(
                          record.rawValue,
                          style: const TextStyle(fontSize: 15, height: 1.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildActions(context, parsed),
                    ],
                  ),
                ),
              ),
              _primaryAction(context, parsed),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context, ParsedContent parsed) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        _actionChip(context, Icons.copy_rounded, 'Copy', () {
          Clipboard.setData(ClipboardData(text: record.rawValue));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
        }),
        _actionChip(context, Icons.ios_share_rounded, 'Share', () => Share.share(record.rawValue)),
        if (parsed.type == 'phone')
          _actionChip(context, Icons.call_rounded, 'Call', () => _launch(context, 'tel:${parsed.title}')),
        if (parsed.type == 'email')
          _actionChip(context, Icons.mail_outline_rounded, 'Email', () => _launch(context, 'mailto:${parsed.title}')),
        if (parsed.type == 'sms')
          _actionChip(context, Icons.message_outlined, 'Message', () => _launch(context, 'sms:${parsed.title}')),
      ],
    );
  }

  Widget _actionChip(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: _color),
      label: Text(label),
      onPressed: onTap,
    );
  }

  Widget _primaryAction(BuildContext context, ParsedContent parsed) {
    String label = 'Done';
    VoidCallback? onTap;

    switch (parsed.type) {
      case 'url':
        label = 'Open Link';
        onTap = () => _launch(context, record.rawValue);
        break;
      case 'wifi':
        label = 'Copy Wi-Fi Password';
        onTap = () {
          Clipboard.setData(ClipboardData(text: parsed.fields['password'] ?? ''));
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Password copied — open Wi-Fi settings to connect')));
        };
        break;
      case 'phone':
        label = 'Call ${parsed.title}';
        onTap = () => _launch(context, 'tel:${parsed.title}');
        break;
      case 'email':
        label = 'Compose Email';
        onTap = () => _launch(context, 'mailto:${parsed.title}');
        break;
      default:
        label = 'Close';
        onTap = () => Navigator.pop(context);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        height: 56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.brandGradient,
            borderRadius: BorderRadius.circular(18),
          ),
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }
}
