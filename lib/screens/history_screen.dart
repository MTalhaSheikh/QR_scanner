import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scan_record.dart';
import '../services/history_service.dart';
import '../services/rating_service.dart';
import '../theme/app_colors.dart';
import '../theme/layout_constants.dart';
import 'result_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<ScanRecord> _records = [];
  String _filter = 'all'; // all, scanned, generated, favorites
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final records = await HistoryService.instance.load();
    if (!mounted) return;
    setState(() {
      _records = records;
      _loading = false;
    });
  }

  List<ScanRecord> get _filtered {
    var list = _records;
    if (_filter == 'scanned') list = list.where((r) => r.source == RecordSource.scanned).toList();
    if (_filter == 'generated') list = list.where((r) => r.source == RecordSource.generated).toList();
    if (_filter == 'favorites') list = list.where((r) => r.favorite).toList();
    if (_query.isNotEmpty) {
      list = list
          .where((r) =>
              r.rawValue.toLowerCase().contains(_query.toLowerCase()) ||
              r.displayLabel.toLowerCase().contains(_query.toLowerCase()))
          .toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildSearch(context),
            _buildFilters(context),
            const SizedBox(height: 4),
            Expanded(child: _buildList(context)),
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
          const Text('History', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          Row(
            children: [
              IconButton(
                onPressed: RatingService.openStoreListing,
                icon: const Icon(Icons.star_border_rounded),
                tooltip: 'Rate this app',
              ),
              if (_records.isNotEmpty)
                TextButton.icon(
                  onPressed: _confirmClearAll,
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.coral),
                  label: const Text('Clear', style: TextStyle(color: AppColors.coral)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v),
        decoration: const InputDecoration(
          hintText: 'Search history',
          prefixIcon: Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    final filters = {'all': 'All', 'scanned': 'Scanned', 'generated': 'Created', 'favorites': 'Favorites'};
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: filters.entries.map((e) {
          final selected = _filter == e.key;
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                e.value,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _filter = e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    final list = _filtered;
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('Nothing here yet', style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, kScrollBottomPadding),
      itemCount: list.length,
      itemBuilder: (context, index) => _historyTile(context, list[index]),
    );
  }

  Widget _historyTile(BuildContext context, ScanRecord record) {
    final color = AppColors.typeColors[record.contentType] ?? AppColors.primary;
    final icon = record.source == RecordSource.generated
        ? Icons.auto_awesome_rounded
        : _iconFor(record.contentType);

    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        await HistoryService.instance.remove(record.id);
        _refresh();
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.darkCard
              : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => ResultScreen(record: record)))
                .then((_) => _refresh()),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(color: color.withOpacity(0.14), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.displayLabel.isEmpty ? record.rawValue : record.displayLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${record.source == RecordSource.generated ? "Created" : "Scanned"} · ${DateFormat.MMMd().add_jm().format(record.timestamp)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      await HistoryService.instance.toggleFavorite(record.id);
                      _refresh();
                    },
                    icon: Icon(
                      record.favorite ? Icons.star_rounded : Icons.star_border_rounded,
                      color: record.favorite ? AppColors.amber : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
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
      case 'barcode':
        return Icons.view_week_rounded;
      default:
        return Icons.text_snippet_rounded;
    }
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear all history?'),
        content: const Text('This will permanently remove every scanned and created code.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear', style: TextStyle(color: AppColors.coral)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await HistoryService.instance.clearAll();
      _refresh();
    }
  }
}
