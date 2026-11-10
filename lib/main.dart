import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

import 'controllers/nav_controller.dart';
import 'controllers/player_controller.dart';
import 'controllers/radio_controller.dart';
import 'core/app_theme.dart';
import 'services/map_service.dart';
import 'services/player/mock_player_service.dart';
import 'services/player/player_service.dart';
import 'services/player/ytmd_player_service.dart';
import 'services/radio_service.dart';
import 'views/dashboard_view.dart';

const bool kMockPlayer = bool.fromEnvironment('MOCK_PLAYER');
const bool kFrameless = bool.fromEnvironment('FRAMELESS');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    final options = WindowOptions(
      size: const Size(1024, 600),
      minimumSize: const Size(1024, 600),
      center: true,
      title: 'Car HMI',
      titleBarStyle: kFrameless ? TitleBarStyle.hidden : TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final PlayerService playerService =
      kMockPlayer ? MockPlayerService() : YtmdPlayerService();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => PlayerController(playerService)..init()),
        ChangeNotifierProvider(
            create: (_) => RadioController(MockRadioService())),
        ChangeNotifierProvider(
            create: (_) => NavController(MockMapService())..init()),
      ],
      child: const CarHmiApp(),
    ),
  );
}

class CarHmiApp extends StatelessWidget {
  const CarHmiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Car HMI',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const DashboardView(),
      );
}
