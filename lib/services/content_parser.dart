/// Inspects a raw decoded string (from a QR code or barcode) and figures
/// out what "kind" of content it represents, so the UI can offer the
/// right quick actions (open link, connect wifi, call, save contact...).
class ParsedContent {
  final String type; // url, wifi, contact, email, phone, sms, text
  final String title;
  final String subtitle;
  final Map<String, String> fields;

  ParsedContent({
    required this.type,
    required this.title,
    required this.subtitle,
    this.fields = const {},
  });
}

class ContentParser {
  ContentParser._();

  /// Linear/1D symbologies almost always used for retail product barcodes
  /// (mobile_scanner's `BarcodeFormat.name` values). These encode a bare
  /// reference number, not a phone number — even though the digits alone
  /// can look exactly like one.
  static const _productBarcodeFormats = {
    'upcA', 'upcE', 'ean8', 'ean13', 'code39', 'code93', 'code128', 'itf', 'codabar',
  };

  static ParsedContent parse(String raw, {String? symbology}) {
    final trimmed = raw.trim();

    if (RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)) {
      return ParsedContent(type: 'url', title: 'Website Link', subtitle: trimmed);
    }

    if (trimmed.toUpperCase().startsWith('WIFI:')) {
      final ssid = RegExp(r'S:([^;]*);').firstMatch(trimmed)?.group(1) ?? 'Unknown network';
      final pass = RegExp(r'P:([^;]*);').firstMatch(trimmed)?.group(1) ?? '';
      final type = RegExp(r'T:([^;]*);').firstMatch(trimmed)?.group(1) ?? 'WPA';
      return ParsedContent(
        type: 'wifi',
        title: ssid,
        subtitle: 'Wi-Fi network',
        fields: {'ssid': ssid, 'password': pass, 'security': type},
      );
    }

    if (trimmed.toUpperCase().startsWith('BEGIN:VCARD')) {
      final name = RegExp(r'FN:(.*)').firstMatch(trimmed)?.group(1)?.trim() ?? 'Contact';
      final tel = RegExp(r'TEL[^:]*:(.*)').firstMatch(trimmed)?.group(1)?.trim() ?? '';
      final email = RegExp(r'EMAIL[^:]*:(.*)').firstMatch(trimmed)?.group(1)?.trim() ?? '';
      return ParsedContent(
        type: 'contact',
        title: name,
        subtitle: 'Contact card',
        fields: {'name': name, 'phone': tel, 'email': email},
      );
    }

    if (trimmed.toUpperCase().startsWith('MAILTO:')) {
      final address = trimmed.substring(7).split('?').first;
      return ParsedContent(type: 'email', title: address, subtitle: 'Email address');
    }

    if (trimmed.toUpperCase().startsWith('TEL:')) {
      return ParsedContent(type: 'phone', title: trimmed.substring(4), subtitle: 'Phone number');
    }

    if (trimmed.toUpperCase().startsWith('SMSTO:') || trimmed.toUpperCase().startsWith('SMS:')) {
      final parts = trimmed.split(':');
      final number = parts.length > 1 ? parts[1].split(':').first : '';
      return ParsedContent(type: 'sms', title: number, subtitle: 'SMS message');
    }

    // A product barcode's digits can easily match the phone-number pattern
    // below (e.g. a 12-digit UPC), so branch on the actual symbology first
    // rather than guessing from the digits alone.
    if (symbology != null && _productBarcodeFormats.contains(symbology)) {
      return ParsedContent(type: 'barcode', title: trimmed, subtitle: 'Product barcode');
    }

    if (RegExp(r'^[\d+\-\s()]{6,}$').hasMatch(trimmed)) {
      return ParsedContent(type: 'phone', title: trimmed, subtitle: 'Phone number');
    }

    return ParsedContent(
      type: 'text',
      title: trimmed.length > 40 ? '${trimmed.substring(0, 40)}…' : trimmed,
      subtitle: 'Plain text',
    );
  }
}
