import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'design/components.dart';
import 'design/palette.dart';
import 'design/theme.dart';
import 'ui/style_gallery.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const VitaApp());
}

class VitaApp extends StatefulWidget {
  const VitaApp({super.key});

  @override
  State<VitaApp> createState() => _VitaAppState();
}

class _VitaAppState extends State<VitaApp> {
  // P2'de shared_preferences'a taşınacak.
  bool _dark = true;
  bool _motion = true;

  @override
  Widget build(BuildContext context) {
    return Motion(
      enabled: _motion,
      child: MaterialApp(
        title: 'vita',
        debugShowCheckedModeBanner: false,
        theme: buildVitaTheme(VitaPalette.light),
        darkTheme: buildVitaTheme(VitaPalette.dark),
        themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
        home: StyleGallery(
          dark: _dark,
          motion: _motion,
          onDarkChanged: (v) => setState(() => _dark = v),
          onMotionChanged: (v) => setState(() => _motion = v),
        ),
      ),
    );
  }
}
