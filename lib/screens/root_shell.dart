import 'package:flutter/material.dart';
import '../widgets/floating_nav_bar.dart';
import 'scan_screen.dart';
import 'generate_screen.dart';
import 'history_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  final _screens = const [
    ScanScreen(),
    GenerateScreen(),
    HistoryScreen(),
  ];

  final _items = const [
    NavItemData(icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner_rounded, label: 'Scan'),
    NavItemData(icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome_rounded, label: 'Create'),
    NavItemData(icon: Icons.history_outlined, activeIcon: Icons.history_rounded, label: 'History'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: FloatingNavBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        items: _items,
      ),
    );
  }
}
