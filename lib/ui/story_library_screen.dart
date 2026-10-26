import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/palette.dart';
import '../design/preferences.dart';
import '../design/theme.dart';
import '../game/session.dart';
import '../design/illustrations.dart';
import 'game_controller.dart';

void openStoryLibrary(BuildContext context, GameController game) {
  game.save();
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => StoryLibraryScreen(game: game)),
  );
}

/// Ana hayat açık olmadan da okunabilen, ayrı kaydedilen hikâye kitaplığı.
class StoryLibraryScreen extends StatefulWidget {
  const StoryLibraryScreen({super.key, required this.game});
  final GameController game;
  @override
  State<StoryLibraryScreen> createState() => _StoryLibraryScreenState();
}

class _StoryLibraryScreenState extends State<StoryLibraryScreen> {
  final _scroll = ScrollController();
  String? _bookId;
  String _filter = 'Tümü', _message = '';
  bool _choosing = false;
  GameController get game => widget.game;
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _top() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
    // Yeni bölümün ölçüleri yerleşince de başa dön: önceki listenin kaydırma
    // düzeltmesi, uzun bir kitap kartından açılan okuyucuyu aşağıda bırakmasın.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
    });
  }

  void _open(String id) {
    game.openBook(id);
    setState(() {
      _bookId = id;
      _message = '';
    });
    _top();
  }

  void _back() {
    if (_bookId == null) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _bookId = null;
      _message = '';
    });
    _top();
  }

  Widget _text(String value, {bool caption = false}) => Text(
    value,
    style: caption
        ? VitaType.caption(context.vita)
        : VitaType.body(context.vita),
  );
  Widget _card(List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
  Widget _button(String title, VoidCallback? onTap, {bool secondary = false}) =>
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: VitaButton(label: title, onPressed: onTap, secondary: secondary),
      );
  Widget _cover(StoryBook b, {double height = 150}) => Semantics(
    label: '${b.title} kitap kapağı',
    image: true,
    child: SizedBox(
      height: height,
      child: SvgPicture.asset(
        'assets/stories/${b.id}.svg',
        fit: BoxFit.contain,
        excludeFromSemantics: true,
      ),
    ),
  );
  void _notice(ActionResult r) => setState(() => _message = r.message);
  void _choose(StoryBook b, int index, String expectedNode) {
    if (_choosing) return;
    _choosing = true;
    final r = game.chooseStory(b.id, index, expectedNode);
    setState(() => _message = r.success ? '' : r.message);
    _top();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _choosing = false;
    });
  }

  Future<void> _restart(StoryBook b) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bu hikâyeyi yeniden başlat?'),
        content: const Text(
          'Bu hikâyenin mevcut kararları sıfırlanır. Keşfettiğin sonlar, diğer hikâyeler, satın alımlar ve hayat kaydın korunur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Baştan başlat'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _notice(game.restartStory(b.id));
    _top();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([game, preferences]),
    builder: (context, _) {
      final p = context.vita, book = game.stories.books[_bookId];
      return PopScope(
        canPop: _bookId == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: p.background,
          appBar: AppBar(
            leading: IconButton(
              tooltip: book == null ? "Vita'ya dön" : 'Hikâye kütüphanesi',
              icon: const Icon(Icons.arrow_back),
              onPressed: _back,
            ),
            title: Text(book == null ? 'Hikâye kütüphanesi' : book.title),
          ),
          body: Backdrop(
            child: SafeArea(
              top: false,
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 32),
                children: [
                  if (_message.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Semantics(
                        liveRegion: true,
                        child: VitaCard(child: _text(_message)),
                      ),
                    ),
                  if (game.stories.loadNotice.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _text(game.stories.loadNotice),
                    ),
                  ...book == null ? _library() : _reader(book),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
  List<Widget> _library() {
    final books =
        game.stories.books.values
            .where((b) => _filter != 'Ücretsiz' || b.productId.isEmpty)
            .where(
              (b) =>
                  _filter != 'Kitaplığım' ||
                  b.productId.isEmpty ||
                  game.storyStore.owns(b.productId),
            )
            .toList()
          ..sort((a, b) {
            final paid = (a.productId.isEmpty ? 0 : 1).compareTo(
              b.productId.isEmpty ? 0 : 1,
            );
            return paid != 0 ? paid : a.title.compareTo(b.title);
          });
    return [
      const VitaChip('BİR UYGULAMA · BİRÇOK HİKÂYE'),
      const SizedBox(height: 12),
      Text('Başka bir ihtimal', style: VitaType.title(context.vita)),
      const SizedBox(height: 8),
      _text(
        'Sırları çöz. Bağlarını koru. Son sözü sen yaz. Kısa, dallanan hikâyeleri kendi hızında oku.',
        caption: true,
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final label in ['Tümü', 'Ücretsiz', 'Kitaplığım'])
            ChoiceChip(
              label: Text(label),
              selected: _filter == label,
              onSelected: (_) => setState(() => _filter = label),
            ),
        ],
      ),
      const SizedBox(height: 18),
      for (final b in books) _bookCard(b),
      _card([
        Text(
          'HİKÂYELERİN SENİNLE KALSIN',
          style: VitaType.overline(context.vita),
        ),
        const SizedBox(height: 10),
        _text(game.storyStore.status, caption: true),
        const SizedBox(height: 8),
        _text(
          'Ücretli hikâyeler tek seferlik açılır. Satın alma yapmadan önce başlangıç bölümünü okuyabilirsin. Ana hayat kaydın etkilenmez.',
          caption: true,
        ),
        _button(
          'Satın alımları geri yükle',
          () => _notice(game.restoreStories()),
          secondary: true,
        ),
      ]),
    ];
  }

  Widget _bookCard(StoryBook b) {
    final p = game.stories.progress[b.id];
    final endings = b.nodes.values.where((n) => n.ending.isNotEmpty).length;
    final owned = b.productId.isEmpty || game.storyStore.owns(b.productId);
    return _card([
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 88, child: _cover(b, height: 118)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _text(b.genre, caption: true),
                const SizedBox(height: 5),
                Text(b.title, style: VitaType.title(context.vita)),
                const SizedBox(height: 6),
                _text(b.subtitle, caption: true),
                const SizedBox(height: 6),
                _text(
                  '${b.chapters.length} bölüm · $endings farklı son',
                  caption: true,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _text(b.description),
      const SizedBox(height: 12),
      VitaChip(
        b.productId.isEmpty
            ? 'TAMAMI ÜCRETSİZ'
            : owned
            ? 'KİTAPLIĞINDA'
            : 'İLK BÖLÜM ÜCRETSİZ',
      ),
      if (b.contentNote.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _text(b.contentNote, caption: true),
        ),
      if (p != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: _text(
            '${p.decisions} karar · ${p.endings.length}/$endings son keşfedildi',
            caption: true,
          ),
        ),
      _button(
        p == null ? 'Hikâyeyi aç' : 'Okumaya devam et',
        () => _open(b.id),
      ),
    ]);
  }

  List<Widget> _reader(StoryBook b) {
    final p = game.stories.open(b.id),
        node = b.nodes[game.stories.open(b.id).nodeId]!;
    final expectedNode = p.nodeId;
    if (!game.stories.canRead(b, node)) return _paywall(b);
    return [
      VitaChip(b.title),
      const SizedBox(height: 12),
      _text(
        'BÖLÜM ${node.chapter} / ${b.chapters.length} · ${b.chapters[node.chapter - 1]}',
        caption: true,
      ),
      const SizedBox(height: 14),
      _card([
        Text(node.title, style: VitaType.title(context.vita)),
        if (p.lastResult.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: _text(p.lastResult),
          ),
        const SizedBox(height: 12),
        SelectableText(
          node.text,
          key: const ValueKey('story-prose'),
          style: VitaType.prose(context.vita)
              .copyWith(fontSize: 17.5 * preferences.readingSize / 38),
        ),
      ]),
      Row(
        children: [
          Expanded(
            child: Semantics(
              label: 'Hikâye yazısını küçült',
              child: _button(
                'A−',
                preferences.readingSize > 32
                    ? () => preferences.setReadingSize(
                        preferences.readingSize - 3,
                      )
                    : null,
                secondary: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Semantics(
              label: 'Hikâye yazısını büyüt',
              child: _button(
                'A+',
                preferences.readingSize < 50
                    ? () => preferences.setReadingSize(
                        preferences.readingSize + 3,
                      )
                    : null,
                secondary: true,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      for (final stat in b.statNames.entries)
        StatBar(
          label: stat.value,
          value: p.stats[stat.key] ?? 50,
          color: context.vita.social,
        ),
      if (node.ending.isNotEmpty) ...[
        const SizedBox(height: 18),
        VitaChip('KEŞFETTİĞİN SON · ${node.ending}'),
        const SizedBox(height: 12),
        _text(
          '${p.decisions} karar verdin. ${p.endings.length} / ${b.nodes.values.where((n) => n.ending.isNotEmpty).length} son keşfettin.',
          caption: true,
        ),
        _button('Başka bir yol dene', () => _restart(b)),
        const SectionHeader('Sonlar koleksiyonun'),
        for (final e in b.nodes.entries.where((e) => e.value.ending.isNotEmpty))
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: VitaChip(
              p.endings.contains(e.key)
                  ? '★ ${e.value.ending}'
                  : '◇ Henüz keşfedilmedi',
            ),
          ),
      ] else ...[
        const SectionHeader('Nasıl devam edeceksin?'),
        for (var i = 0; i < node.choices.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DecisionCard(
              key: ValueKey('story-choice-$i'),
              index: i,
              text: node.choices[i].text,
              lockedReason: game.stories.blocked(b, p, node.choices[i]),
              onTap: () => _choose(b, i, expectedNode),
            ),
          ),
        _button(
          'Bu hikâyeyi baştan başlat',
          () => _restart(b),
          secondary: true,
        ),
      ],
      const SizedBox(height: 16),
      _text(
        'Kararların otomatik kaydedilir. Kütüphaneden kaldığın yere dönebilirsin.',
        caption: true,
      ),
    ];
  }

  List<Widget> _paywall(StoryBook b) => [
    _cover(b, height: 240),
    const SizedBox(height: 20),
    Text('Hikâyen burada bitmiyor.', style: VitaType.title(context.vita)),
    const SizedBox(height: 12),
    _text(
      '${b.title} başlangıç bölümünü tamamladın. Kalan ${b.chapters.length - b.freeChapters} bölüm ve ${b.nodes.values.where((n) => n.ending.isNotEmpty).length} farklı son, tam hikâyede seni bekliyor. Seçimlerin korunuyor.',
    ),
    const SizedBox(height: 12),
    _text(
      'Tek seferlik satın alım · Abonelik yok · Diğer hikâyeler ayrı satılır',
      caption: true,
    ),
    _button(
      game.storyStore.price(b.productId).isNotEmpty
          ? 'Tam hikâyeyi aç · ${game.storyStore.price(b.productId)}'
          : 'Satış bu sürümde henüz açılmadı',
      game.storyStore.canPurchase(b.productId)
          ? () => _notice(game.purchaseStory(b.productId))
          : null,
    ),
    const SizedBox(height: 10),
    _text(game.storyStore.status, caption: true),
    _button(
      'Satın alımı geri yükle',
      () => _notice(game.restoreStories()),
      secondary: true,
    ),
    _button(
      'Ücretsiz başlangıcı yeniden oyna',
      () => _restart(b),
      secondary: true,
    ),
  ];
}
