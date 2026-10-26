import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import '../game/state.dart';
import '../game/text.dart';
import 'game_controller.dart';
import 'shell.dart';

/// Ana ekran: hikâye → karar → sonuç → hikâye. Oyun sonunda final sayfası.
class StoryScreen extends StatefulWidget {
  const StoryScreen({super.key, required this.game});
  final GameController game;

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final _scroll = ScrollController();
  int _tab = 0;

  GameController get game => widget.game;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _toTop() {
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _choose(String id) {
    game.choose(id);
    _toTop();
  }

  void _continue() {
    game.continueStory();
    _toTop();
  }

  void _newAge() {
    final r = game.newAge();
    if (!r.success) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(r.message), behavior: SnackBarBehavior.floating));
    } else {
      HapticFeedback.mediumImpact();
      _toTop();
    }
  }

  Future<bool> _confirmExit() async {
    final p = context.vita;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.surface,
        title: Text('Çıkmak istiyor musun?', style: VitaType.cardTitle(p)),
        content: Text('Hayatın kaydedildi; kaldığın yerden devam edebilirsin.', style: VitaType.body(p)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Kal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Çık')),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return ListenableBuilder(
      listenable: game,
      builder: (context, _) {
        final s = game.state;
        if (s == null) return const SizedBox.shrink();
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            if (_tab != 0) return setState(() => _tab = 0);
            if (await _confirmExit()) SystemNavigator.pop();
          },
          child: AnnotatedRegion<SystemUiOverlayStyle>(
            value: (p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
                .copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: p.groundBottom),
            child: Scaffold(
              backgroundColor: p.background,
              extendBody: true,
              body: Backdrop(
                child: SafeArea(
                  bottom: false,
                  child: Column(children: [
                    VitaKunye(name: s.playerName, detail: '${s.ageText} · ${s.profile.birthplace}', money: formatMoney(s.money)),
                    Expanded(child: _tab == 0 ? _story(s) : _comingSoon()),
                  ]),
                ),
              ),
              bottomNavigationBar: s.isGameOver
                  ? null
                  : VitaTabBar(index: _tab, onSelect: (i) => setState(() => _tab = i), onNewAge: _newAge),
            ),
          ),
        );
      },
    );
  }

  Widget _story(GameState s) {
    final Widget page;
    final String key;
    if (s.isGameOver && s.pendingMoment == null) {
      page = _GameOver(game: game);
      key = 'end';
    } else if (s.pendingMoment != null) {
      page = _ResultPage(moment: s.pendingMoment!, gameOver: s.isGameOver, onContinue: _continue, onEnd: game.acknowledgeMoment);
      key = 'm${s.day}';
    } else if (game.event != null) {
      page = _EventPage(game: game, onChoose: _choose);
      key = 'e${game.event!.id}${s.day}';
    } else {
      page = Center(child: VitaButton(label: 'Hikâyeye devam et', onPressed: _continue));
      key = 'idle';
    }
    final stage = s.age < 6 ? 0 : s.age < 18 ? 1 : s.age < 65 ? 2 : 3;
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
      children: [
        AtmosphereStrip(stage: stage, numeral: '${s.age}'),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: Motion.of(context, const Duration(milliseconds: 300)),
          child: KeyedSubtree(key: ValueKey(key), child: EnterAnimation(child: page)),
        ),
      ],
    );
  }

  Widget _comingSoon() {
    final p = context.vita;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text('Bu sekme bir sonraki aşamada (P3) açılacak.', textAlign: TextAlign.center, style: VitaType.body(p).copyWith(color: p.muted)),
      ),
    );
  }
}

class _EventPage extends StatelessWidget {
  const _EventPage({required this.game, required this.onChoose});
  final GameController game;
  final ValueChanged<String> onChoose;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final s = game.state!, ev = game.event!;
    final scene = s.simulation.currentSceneId == ev.id && ev.managedByDirector ? s.simulation.currentSceneReason : '';
    final choices = game.choices;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('${s.lifeStage} · ${_categoryLabel(ev.category)}'.toUpperCase(), style: VitaType.overline(p)),
      const SizedBox(height: 6),
      Semantics(header: true, child: Text(ev.title, style: VitaType.title(p))),
      const SizedBox(height: 12),
      Typewriter(text: game.eventText, style: VitaType.prose(p)),
      if (scene.isNotEmpty) ...[const SizedBox(height: 10), Text(scene, style: VitaType.caption(p))],
      const SectionHeader('Ne yaparsın?'),
      for (final (i, c) in choices.indexed) ...[
        EnterAnimation(
          index: i + 1,
          child: DecisionCard(
            index: i,
            text: c.text,
            hint: c.hint.isEmpty ? null : c.hint,
            cost: c.cost > 0 ? formatMoney(c.cost) : null,
            lockedReason: c.isAvailable ? null : (c.unmetReasons.isEmpty ? 'Şu an uygun değil' : c.unmetReasons.join(' · ')),
            onTap: () => onChoose(c.id),
          ),
        ),
        const SizedBox(height: 10),
      ],
    ]);
  }

  static String _categoryLabel(EventCategory c) => categoryDisplay(c);
}

class _ResultPage extends StatelessWidget {
  const _ResultPage({required this.moment, required this.gameOver, required this.onContinue, required this.onEnd});
  final SavedMoment moment;
  final bool gameOver;
  final VoidCallback onContinue, onEnd;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final changes = moment.changes.where((c) => c.applied != 0).toList();
    final t = moment.turn;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('SONUÇ', style: VitaType.overline(p)),
      const SizedBox(height: 6),
      Semantics(header: true, child: Text(moment.title, style: VitaType.title(p))),
      const SizedBox(height: 12),
      Text(moment.text, style: VitaType.prose(p)),
      if (changes.isNotEmpty) ...[
        const SizedBox(height: 16),
        Wrap(spacing: 14, runSpacing: 6, children: [
          for (final c in changes)
            c.stat == Stat.money
                ? Text(formatChange(c), style: VitaType.body(p).copyWith(color: c.applied >= 0 ? p.positive : p.negative, fontSize: 13.5))
                : StatDelta(label: statDisplay(c.stat), delta: c.applied),
        ]),
      ],
      if (t.notes.isNotEmpty) ...[
        const SectionHeader('Bu dönemde'),
        for (final n in t.notes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('✦  ', style: TextStyle(color: p.accent, fontSize: 12)),
              Expanded(child: Text(n, style: VitaType.body(p))),
            ]),
          ),
      ],
      const SizedBox(height: 14),
      Text(_elapsed(t), style: VitaType.caption(p)),
      const SizedBox(height: 18),
      VitaButton(label: gameOver ? 'Hayatın sonu' : 'Hikâyeye devam et', onPressed: gameOver ? onEnd : onContinue),
    ]);
  }

  static String _elapsed(TurnReport t) {
    final when = t.days >= 330
        ? '${(t.days / 365).round()} yıl geçti'
        : t.days >= 28
            ? '${(t.days / 30).round()} ay geçti'
            : t.days >= 7
                ? '${t.days ~/ 7} hafta geçti'
                : '${t.days} gün geçti';
    final money = [
      if (t.income > 0) '+${formatMoney(t.income)} gelir',
      if (t.expenses > 0) '−${formatMoney(t.expenses)} gider',
    ];
    return [when, ...money].join(' · ');
  }
}

class _GameOver extends StatelessWidget {
  const _GameOver({required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final s = game.state!;
    final ending = game.session.ending;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('HAYATIN SONU', style: VitaType.overline(p)),
      const SizedBox(height: 6),
      Text(ending?.title ?? 'Bir Hayat', style: VitaType.display(p).copyWith(fontSize: 32)),
      const SizedBox(height: 12),
      if (s.gameOverReason != null) Text(gameOverDisplay(s.gameOverReason!), style: VitaType.body(p).copyWith(color: p.muted)),
      const SizedBox(height: 12),
      if ((ending?.text ?? '').isNotEmpty) Text(ending!.text, style: VitaType.prose(p)),
      const SectionHeader('Son durum'),
      VitaCard(
        child: Column(children: [
          StatBar(label: 'Sağlık', value: s.health, color: p.health),
          StatBar(label: 'Mutluluk', value: s.happiness, color: p.happiness),
          StatBar(label: 'Eğitim', value: s.education, color: p.education),
          StatBar(label: 'Sosyal', value: s.social, color: p.social),
        ]),
      ),
      const SizedBox(height: 10),
      Text('${s.age} yıl · ${s.totalChoices} karar · ${formatMoney(s.money)}', style: VitaType.caption(p)),
      const SizedBox(height: 20),
      VitaButton(label: 'Yeni bir hayat', onPressed: game.leaveToTitle),
    ]);
  }
}

/// Hikâye metni için 0.7 sn daktilo etkisi. Animasyon kapalıysa anında; dokununca tamamlanır.
class Typewriter extends StatefulWidget {
  const Typewriter({super.key, required this.text, required this.style});
  final String text;
  final TextStyle style;

  @override
  State<Typewriter> createState() => _TypewriterState();
}

class _TypewriterState extends State<Typewriter> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final d = Motion.of(context, const Duration(milliseconds: 700));
    if (d == Duration.zero) {
      _c.value = 1;
    } else if (!_c.isAnimating && !_c.isCompleted) {
      _c
        ..duration = d
        ..forward();
    }
  }

  @override
  void didUpdateWidget(Typewriter old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text && _c.duration != null) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.text,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _c.value = 1,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final n = (widget.text.length * _c.value).round();
            // Görünmeyen kısım saydam çizilir ki satırlar ve yükseklik baştan sabit kalsın.
            return Text.rich(TextSpan(style: widget.style, children: [
              TextSpan(text: widget.text.substring(0, n)),
              TextSpan(text: widget.text.substring(n), style: const TextStyle(color: Colors.transparent)),
            ]));
          },
        ),
      ),
    );
  }
}
