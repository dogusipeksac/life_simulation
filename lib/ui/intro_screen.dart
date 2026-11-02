// Uygulama tanıtımı ve "Yenilikler": sayfalar assets/intro/intro.json'dan gelir.
// Her sayfanın "Since" değeri eklendiği tanıtım sürümüdür. İlk açılışta bütün sayfalar,
// güncellemeden sonra yalnızca oyuncunun henüz görmediği yeni sayfalar gösterilir.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/preferences.dart';
import '../design/theme.dart';

class IntroPage {
  IntroPage.fromJson(Map<String, Object?> j)
      : id = j['Id'] as String? ?? '',
        since = j['Since'] as int? ?? 1,
        icon = j['Icon'] as String? ?? '',
        kicker = j['Kicker'] as String? ?? '',
        title = j['Title'] as String? ?? '',
        body = j['Body'] as String? ?? '',
        points = [for (final p in (j['Points'] as List? ?? const [])) p as String];

  final String id, icon, kicker, title, body;
  final int since;
  final List<String> points;
}

class IntroDeck {
  IntroDeck(this.pages);
  final List<IntroPage> pages;

  /// Uygulamanın yüklediği tanıtım; testlerde boş kalır, tanıtım gösterilmez.
  static IntroDeck current = IntroDeck(const []);

  static Future<IntroDeck> load([AssetBundle? bundle]) async {
    final raw = jsonDecode(await (bundle ?? rootBundle).loadString('assets/intro/intro.json')) as Map<String, Object?>;
    return IntroDeck([
      for (final p in raw['Pages'] as List) IntroPage.fromJson((p as Map).cast<String, Object?>()),
    ]);
  }

  int get latest => pages.fold(0, (v, p) => p.since > v ? p.since : v);

  /// [seen] sürümünden sonra eklenen sayfalar; hiç görülmediyse hepsi.
  List<IntroPage> pendingFor(int seen) => [for (final p in pages) if (p.since > seen) p];
}

/// Simge adları JSON'da metin olarak durur; yeni sayfa yeni simge isterse buraya eklenir.
const _icons = <String, IconData>{
  'auto_stories': Icons.auto_stories_outlined,
  'casino': Icons.casino_outlined,
  'touch_app': Icons.touch_app_outlined,
  'gesture': Icons.gesture,
  'work_outline': Icons.work_outline,
  'people_outline': Icons.people_outline,
  'library_books_outlined': Icons.library_books_outlined,
  'card_giftcard': Icons.card_giftcard,
  'new_releases': Icons.new_releases_outlined,
  'star': Icons.star_outline,
};

Future<void> openIntro(BuildContext context) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IntroScreen(
          pages: IntroDeck.current.pages,
          onDone: () => Navigator.of(context).pop(),
        ),
      ),
    );

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key, required this.pages, required this.onDone, this.whatsNew = false});
  final List<IntroPage> pages;
  final VoidCallback onDone;

  /// Güncelleme sonrası yalnızca yeni sayfalar: başlık "Yenilikler" olur.
  final bool whatsNew;

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _pager = PageController();
  int _index = 0;

  bool get _last => _index >= widget.pages.length - 1;

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  void _next() {
    preferences.feedback();
    if (_last) return widget.onDone();
    _pager.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Scaffold(
      backgroundColor: p.background,
      body: Backdrop(
        child: SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(children: [
                Text(widget.whatsNew ? 'Yenilikler' : 'Hayat Simülasyonu',
                    style: VitaType.serif(17, p.accent, weight: FontWeight.w600)),
                const Spacer(),
                if (!_last) TextButton(onPressed: widget.onDone, child: const Text('Geç')),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pager,
                itemCount: widget.pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _page(p, widget.pages[i]),
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < widget.pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: i == _index ? 22 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: i == _index ? p.accent : p.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: VitaButton(label: _last ? 'Başla' : 'Devam', onPressed: _next),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _page(VitaPalette p, IntroPage page) => ListView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
        children: [
          Center(
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.accent.withValues(alpha: .14),
                border: Border.all(color: p.accent.withValues(alpha: .4)),
              ),
              child: Icon(_icons[page.icon] ?? Icons.auto_stories_outlined, size: 52, color: p.accent),
            ),
          ),
          const SizedBox(height: 28),
          if (page.kicker.isNotEmpty) ...[
            Text(page.kicker, textAlign: TextAlign.center, style: VitaType.overline(p, color: p.accent)),
            const SizedBox(height: 8),
          ],
          Text(page.title, textAlign: TextAlign.center, style: VitaType.title(p)),
          const SizedBox(height: 14),
          Text(page.body, textAlign: TextAlign.center, style: VitaType.prose(p)),
          if (page.points.isNotEmpty) ...[
            const SizedBox(height: 22),
            LifeSimulationCard(
              child: Column(children: [
                for (final (i, point) in page.points.indexed)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.check_circle_outline, size: 18, color: p.positive),
                      const SizedBox(width: 10),
                      Expanded(child: Text(point, style: VitaType.body(p))),
                    ]),
                  ),
              ]),
            ),
          ],
        ],
      );
}
