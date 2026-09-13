import 'dart:convert';

/// Where a record came from.
enum RecordSource { scanned, generated }

/// A single history entry — either something the user scanned with the
/// camera, or a code they generated inside the app.
class ScanRecord {
  final String id;
  final RecordSource source;
  final String symbology; // e.g. "QR_CODE", "CODE_128", "EAN_13"
  final String contentType; // url, wifi, contact, email, phone, sms, text, barcode
  final String rawValue;
  final String displayLabel;
  final DateTime timestamp;
  bool favorite;

  ScanRecord({
    required this.id,
    required this.source,
    required this.symbology,
    required this.contentType,
    required this.rawValue,
    required this.displayLabel,
    required this.timestamp,
    this.favorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'source': source.name,
        'symbology': symbology,
        'contentType': contentType,
        'rawValue': rawValue,
        'displayLabel': displayLabel,
        'timestamp': timestamp.toIso8601String(),
        'favorite': favorite,
      };

  factory ScanRecord.fromJson(Map<String, dynamic> json) => ScanRecord(
        id: json['id'] as String,
        source: RecordSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => RecordSource.scanned,
        ),
        symbology: json['symbology'] as String? ?? 'QR_CODE',
        contentType: json['contentType'] as String? ?? 'text',
        rawValue: json['rawValue'] as String? ?? '',
        displayLabel: json['displayLabel'] as String? ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
        favorite: json['favorite'] as bool? ?? false,
      );

  static String encodeList(List<ScanRecord> records) =>
      jsonEncode(records.map((r) => r.toJson()).toList());

  static List<ScanRecord> decodeList(String raw) {
    if (raw.isEmpty) return [];
    final list = jsonDecode(raw) as List;
    return list.map((e) => ScanRecord.fromJson(e as Map<String, dynamic>)).toList();
  }
}
