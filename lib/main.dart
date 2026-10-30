import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

import 'content/asset_content_loader.dart';
import 'design/components.dart';
import 'design/palette.dart';
import 'design/preferences.dart';
import 'design/theme.dart';
import 'game/save.dart';
import 'game/session.dart';
import 'platform/play_billing.dart';
import 'platform/google_ads.dart';
import 'ui/game_controller.dart';
import 'ui/start_screen.dart';
import 'ui/story_screen.dart';
import 'ui/style_gallery.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Noto Serif',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const LifeSimulationApp());
}

/// İçeriği ve kaydı hazırlayan kök. [loadGame] testlerde değiştirilir.
class LifeSimulationApp extends StatefulWidget {
  const LifeSimulationApp({super.key, this.loadGame = defaultLoadGame});

  final Future<GameController> Function() loadGame;

  static Future<GameController> defaultLoadGame() async {
    await preferences.load();
    final content = await loadBundledContent();
    final dir = await getApplicationSupportDirectory();
    final game = GameController(
      GameSession(content, SaveService('${dir.path}/savegame.json')),
      billing: PlayBilling(),
      ads: GoogleAds(),
    );
    unawaited(game.initializePlatformServices());
    return game;
  }

  @override
  State<LifeSimulationApp> createState() => _LifeSimulationAppState();
}

class _LifeSimulationAppState extends State<LifeSimulationApp> with WidgetsBindingObserver {
  late final Future<GameController> _game = widget.loadGame();
  GameController? _controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (widget.loadGame == LifeSimulationApp.defaultLoadGame) _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller?.onResume();
    // Mobilde arka plana atılan uygulama uyarısız öldürülebilir.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _controller?.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: preferences,
      builder: (context, _) => Motion(
        enabled: preferences.motion,
        child: MaterialApp(
          title: 'Hayat Simülasyonu',
          debugShowCheckedModeBanner: false,
          theme: buildVitaTheme(VitaPalette.light),
          darkTheme: buildVitaTheme(VitaPalette.dark),
          themeMode: preferences.dark ? ThemeMode.dark : ThemeMode.light,
          home: FutureBuilder<GameController>(
            future: _game,
            builder: (context, snap) {
              if (snap.hasError) return _Failure(error: snap.error!);
              final game = _controller = snap.data;
              if (game == null) return const _Splash();
              return ListenableBuilder(
                listenable: game,
                builder: (context, _) => game.inGame
                    ? StoryScreen(game: game)
                    : TitleScreen(
                        game: game,
                        onGallery: kDebugMode
                            ? () => _openGallery(context)
                            : null,
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _openGallery(BuildContext context) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => StatefulBuilder(
        builder: (context, set) => StyleGallery(
          dark: preferences.dark,
          motion: preferences.motion,
          onDarkChanged: (v) => preferences.set('dark', v),
          onMotionChanged: (v) => preferences.set('motion', v),
        ),
      ),
    ),
  );
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Scaffold(
      backgroundColor: p.background,
      body: Center(
        child: Text(
          'Hayat Simülasyonu',
          style: VitaType.display(p).copyWith(color: p.accent),
        ),
      ),
    );
  }
}

/// İçerik doğrulanamazsa geliştiriciye hata gösterilir; tanımsız bayrakla açılış yapılmaz.
class _Failure extends StatelessWidget {
  const _Failure({required this.error});
  final Object error;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Scaffold(
      backgroundColor: p.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: SelectableText(
            '$error',
            style: VitaType.body(p).copyWith(color: p.negative),
          ),
        ),
      ),
    );
  }
}
