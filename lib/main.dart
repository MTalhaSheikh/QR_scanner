import 'package:flutter/material.dart';
import 'services/ad_config.dart';
import 'services/rewarded_ad_service.dart';
import 'theme/app_theme.dart';
import 'screens/root_shell.dart';

/// Global theme-mode notifier so any screen (e.g. a settings toggle) can
/// flip between light and dark without a state-management package.
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdConfig.init();
  RewardedAdService.instance.preload(); // have one ready before Save/Share is tapped
  runApp(const ScanCraftApp());
}

class ScanCraftApp extends StatelessWidget {
  const ScanCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'QR Code Scanner',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          home: const RootShell(),
        );
      },
    );
  }
}

