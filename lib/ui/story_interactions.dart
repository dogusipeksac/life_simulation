// Hikâye okuyucusundaki metin dışı etkileşimler ve sahne görünümleri.
// Her etkileşim bir sonuç adıyla biter (success/fail/timeout/done); motor bunu sahnedeki
// seçeneğe çevirir. Ekran okuyucu açıkken süreler durur, zorluk düşer.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../content/models.dart';
import '../design/components.dart';
import '../design/palette.dart';
import '../design/preferences.dart';
import '../design/theme.dart';

typedef OutcomeCallback = void Function(
  String outcome, {
  Set<String> found,
  Set<int> indices,
});

/// Etkileşimi türüne göre kurar. [timer] türü seçenek kartlarıyla birlikte [TimedChoiceBar] kullanır.
Widget storyInteraction(
  StoryInteraction i, {
  required Key key,
  required OutcomeCallback onOutcome,
}) => switch (i.type) {
  'code' => CodeLock(key: key, interaction: i, onOutcome: onOutcome),
  'order' => OrderPuzzle(key: key, interaction: i, onOutcome: onOutcome),
  'tune' => TuneDial(key: key, interaction: i, onOutcome: onOutcome),
  'timing' => TimingBar(key: key, interaction: i, onOutcome: onOutcome),
  'search' => SearchScene(key: key, interaction: i, onOutcome: onOutcome),
  'memory' => MemoryPairs(key: key, interaction: i, onOutcome: onOutcome),
  'budget' => BudgetSplit(key: key, interaction: i, onOutcome: onOutcome),
  'hold' => HoldBreath(key: key, interaction: i, onOutcome: onOutcome),
  'quiz' => QuizCard(key: key, interaction: i, onOutcome: onOutcome),
  _ => const SizedBox.shrink(),
};

bool _easyMode(BuildContext context) =>
    MediaQuery.accessibleNavigationOf(context);

void _announce(BuildContext context, String message) =>
    SemanticsService.sendAnnouncement(
      View.of(context),
      message,
      Directionality.of(context),
    );

class _Frame extends StatelessWidget {
  const _Frame({
    required this.label,
    required this.prompt,
    required this.children,
    this.status,
  });
  final String label, prompt;
  final String? status;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return LifeSimulationCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(upperTr(label), style: VitaType.overline(p)),
              ),
              if (status != null)
                Semantics(
                  liveRegion: true,
                  child: Text(status!, style: VitaType.caption(p)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(prompt, style: VitaType.body(p)),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Şifre kilidi

class CodeLock extends StatefulWidget {
  const CodeLock({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<CodeLock> createState() => _CodeLockState();
}

class _CodeLockState extends State<CodeLock> {
  late final List<int> _digits = List.filled(
    widget.interaction.answer.length,
    0,
  );
  late int _left = widget.interaction.attempts;
  bool _wrong = false;

  void _spin(int i, int d) {
    preferences.feedback();
    setState(() {
      _digits[i] = (_digits[i] + d) % 10;
      _wrong = false;
    });
  }

  void _try() {
    if (_digits.join() == widget.interaction.answer) {
      preferences.feedback(strong: true);
      widget.onOutcome('success');
      return;
    }
    preferences.feedback(strong: true);
    setState(() {
      _left--;
      _wrong = true;
    });
    _announce(
      context,
      _left > 0 ? 'Yanlış. $_left deneme hakkın kaldı.' : 'Kilit açılmadı.',
    );
    if (_left <= 0) widget.onOutcome('fail');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita, i = widget.interaction;
    return _Frame(
      label: 'Şifre kilidi',
      prompt: i.prompt,
      status: '$_left deneme',
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var d = 0; d < _digits.length; d++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  label: 'Hane ${d + 1}',
                  value: '${_digits[d]}',
                  increasedValue: '${(_digits[d] + 1) % 10}',
                  decreasedValue: '${(_digits[d] + 9) % 10}',
                  onIncrease: () => _spin(d, 1),
                  onDecrease: () => _spin(d, 9),
                  child: ExcludeSemantics(
                    child: Column(
                      children: [
                        IconButton(
                          onPressed: () => _spin(d, 1),
                          icon: Icon(Icons.keyboard_arrow_up, color: p.accent),
                        ),
                        Container(
                          width: 46,
                          height: 58,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: p.surfaceSunken,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _wrong ? p.negative : p.border,
                            ),
                          ),
                          child: Text(
                            '${_digits[d]}',
                            style: VitaType.serif(
                              30,
                              p.ink,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _spin(d, 9),
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: p.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (_wrong && i.hint.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            'İpucu: ${i.hint}',
            style: VitaType.caption(p).copyWith(color: p.accent),
          ),
        ],
        const SizedBox(height: 12),
        VitaButton(label: 'Kilidi dene', onPressed: _try),
      ],
    );
  }
}

// ---------------------------------------------------------------- Sıralama (kanıt panosu)

class OrderPuzzle extends StatefulWidget {
  const OrderPuzzle({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<OrderPuzzle> createState() => _OrderPuzzleState();
}

class _OrderPuzzleState extends State<OrderPuzzle> {
  late List<String> _items;
  late int _left = widget.interaction.attempts.clamp(1, 3);
  String? _feedback;

  @override
  void initState() {
    super.initState();
    final answer = widget.interaction.items;
    // Belirlenimci karıştırma: aynı sahne her açılışta aynı başlar, hiçbir zaman çözülmüş başlamaz.
    _items = [...answer]..shuffle(Random(answer.join().length));
    if (_listEq(_items, answer)) _items = answer.reversed.toList();
  }

  static bool _listEq(List<String> a, List<String> b) =>
      List.generate(a.length, (i) => a[i] == b[i]).every((x) => x);

  void _move(int from, int to) {
    if (to < 0 || to >= _items.length) return;
    preferences.feedback();
    setState(() {
      _items.insert(to, _items.removeAt(from));
      _feedback = null;
    });
  }

  void _check() {
    final answer = widget.interaction.items;
    if (_listEq(_items, answer)) {
      preferences.feedback(strong: true);
      widget.onOutcome('success');
      return;
    }
    final right = List.generate(
      answer.length,
      (i) => _items[i] == answer[i],
    ).where((x) => x).length;
    setState(() {
      _left--;
      _feedback = '$right / ${answer.length} yerinde.';
    });
    _announce(context, _feedback!);
    if (_left <= 0) widget.onOutcome('fail');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return _Frame(
      label: 'Sırala',
      prompt: widget.interaction.prompt,
      status: '$_left deneme',
      children: [
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: _move,
          children: [
            for (final (n, item) in _items.indexed)
              Padding(
                key: ValueKey(item),
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: p.surfaceSunken,
                  borderRadius: BorderRadius.circular(10),
                  child: Row(
                    children: [
                      ReorderableDragStartListener(
                        index: n,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.drag_indicator,
                            color: p.muted,
                            semanticLabel: 'Sürükle',
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '${n + 1}. $item',
                            style: VitaType.body(p),
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Yukarı taşı',
                        onPressed: n == 0 ? null : () => _move(n, n - 1),
                        icon: const Icon(Icons.arrow_upward, size: 18),
                      ),
                      IconButton(
                        tooltip: 'Aşağı taşı',
                        onPressed: n == _items.length - 1
                            ? null
                            : () => _move(n, n + 1),
                        icon: const Icon(Icons.arrow_downward, size: 18),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        if (_feedback != null)
          Text(
            _feedback!,
            style: VitaType.caption(p).copyWith(color: p.accent),
          ),
        const SizedBox(height: 10),
        VitaButton(label: 'Bu sırayla dene', onPressed: _check),
      ],
    );
  }
}

// ---------------------------------------------------------------- Frekans ayarı

class TuneDial extends StatefulWidget {
  const TuneDial({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<TuneDial> createState() => _TuneDialState();
}

class _TuneDialState extends State<TuneDial> {
  // Hedefe en uzak uçtan başla; aksi halde hedef bandın ucundaysa hiçbir şey yapmadan tutulur.
  late double _value =
      widget.interaction.target - widget.interaction.min <
          widget.interaction.max - widget.interaction.target
      ? widget.interaction.max
      : widget.interaction.min;
  Timer? _tick;
  int _held = 0, _elapsed = 0;
  bool _done = false;

  StoryInteraction get i => widget.interaction;
  double get _tolerance => i.tolerance * (_easyMode(context) ? 2 : 1);
  double get _signal =>
      (1 - (_value - i.target).abs() / ((i.max - i.min) * .25))
          .clamp(0, 1)
          .toDouble();

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(milliseconds: 100), (_) => _step());
  }

  void _step() {
    if (_done || !mounted) return;
    setState(() {
      _elapsed += 100;
      if ((_value - i.target).abs() <= _tolerance) {
        _held += 100;
      } else {
        _held = 0;
      }
    });
    if (_held >= i.holdMs) return _finish('success');
    if (!_easyMode(context) && _elapsed >= i.seconds * 1000) _finish('fail');
  }

  void _finish(String outcome) {
    if (_done) return;
    _done = true;
    _tick?.cancel();
    preferences.feedback(strong: true);
    widget.onOutcome(outcome);
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final easy = _easyMode(context);
    final left = max(0, i.seconds - _elapsed ~/ 1000);
    final bars = (_signal * 8).round();
    return _Frame(
      label: i.unit == 'MHz' ? 'Frekansı yakala' : 'Ayarla',
      prompt: i.prompt,
      status: easy ? null : '$left sn',
      children: [
        Center(
          child: Text(
            '${_value.toStringAsFixed(1)} ${i.unit}',
            style: VitaType.serif(
              30,
              p.ink,
              weight: FontWeight.w600,
            ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
        const SizedBox(height: 6),
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var b = 0; b < 8; b++)
                Container(
                  width: 10,
                  height: 8.0 + b * 3,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: b < bars ? p.accent : p.surfaceSunken,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _held > 0
                ? 'Sinyal temiz · sabit tut'
                : _signal > .7
                ? 'Bir ses seçiliyor…'
                : 'Cızırtı',
            style: VitaType.caption(p)
                .copyWith(color: _held > 0 ? p.positive : p.muted),
          ),
        ),
        Slider(
          value: _value,
          min: i.min,
          max: i.max,
          divisions: ((i.max - i.min) * 10).round(),
          label: _value.toStringAsFixed(1),
          semanticFormatterCallback: (v) =>
              '${v.toStringAsFixed(1)} ${i.unit}, sinyal yüzde ${(_signal * 100).round()}',
          onChanged: (v) {
            if ((v * 10).round() != (_value * 10).round() && _signal > .7) {
              preferences.feedback();
            }
            setState(() => _value = v);
          },
        ),
        if (i.hint.isNotEmpty) Text(i.hint, style: VitaType.caption(p)),
        const SizedBox(height: 8),
        VitaButton(
          label: 'Vazgeç',
          secondary: true,
          onPressed: () => _finish('fail'),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Zamanlama

class TimingBar extends StatefulWidget {
  const TimingBar({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<TimingBar> createState() => _TimingBarState();
}

class _TimingBarState extends State<TimingBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  int _round = 0, _hits = 0;
  String? _last;
  bool _started = false;

  StoryInteraction get i => widget.interaction;

  // Her turda bölge başka yerde; belirlenimci.
  double get _center => const [.7, .3, .55, .82, .2, .45][_round % 6];
  double get _zone => i.zone * (_easyMode(context) ? 1.6 : 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final slow = _easyMode(context) ? 2.0 : 1.0;
    _c
      ..duration = Duration(milliseconds: (1400 * slow / i.speed).round())
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _tap() {
    final hit = (_c.value - _center).abs() <= _zone / 2;
    preferences.feedback(strong: hit);
    setState(() {
      _round++;
      if (hit) _hits++;
      _last = hit ? 'İsabet!' : 'Kaçtı.';
    });
    _announce(context, _last!);
    final remaining = i.rounds - _round;
    if (_hits >= i.need) {
      _c.stop();
      widget.onOutcome('success');
    } else if (_hits + remaining < i.need) {
      _c.stop();
      widget.onOutcome('fail');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return _Frame(
      label: 'Zamanla',
      prompt: i.prompt,
      status:
          '$_hits / ${i.need} · tur ${min(_round + 1, i.rounds)}/${i.rounds}',
      children: [
        ExcludeSemantics(
          child: SizedBox(
            height: 44,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) => CustomPaint(
                painter: _TimingPainter(p, _c.value, _center, _zone),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (_last != null)
          Text(
            _last!,
            textAlign: TextAlign.center,
            style: VitaType.caption(p).copyWith(color: p.accent),
          ),
        const SizedBox(height: 8),
        VitaButton(label: 'Şimdi!', onPressed: _tap),
      ],
    );
  }
}

class _TimingPainter extends CustomPainter {
  _TimingPainter(this.p, this.t, this.center, this.zone);
  final VitaPalette p;
  final double t, center, zone;

  @override
  void paint(Canvas canvas, Size size) {
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, size.height / 2 - 6, size.width, 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(track, Paint()..color = p.surfaceSunken);
    final zx = (center - zone / 2) * size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(zx, size.height / 2 - 6, zone * size.width, 12),
        const Radius.circular(6),
      ),
      Paint()..color = p.accent.withValues(alpha: .55),
    );
    canvas.drawCircle(
      Offset(t * size.width, size.height / 2),
      11,
      Paint()..color = p.ink,
    );
  }

  @override
  bool shouldRepaint(_TimingPainter old) =>
      old.t != t || old.center != center || old.p != p;
}

// ---------------------------------------------------------------- Sahneyi incele

class SearchScene extends StatefulWidget {
  const SearchScene({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<SearchScene> createState() => _SearchSceneState();
}

class _SearchSceneState extends State<SearchScene> {
  final _opened = <int>{};

  int get _left => widget.interaction.picks - _opened.length;

  void _open(int n) {
    if (_left <= 0 || _opened.contains(n)) return;
    preferences.feedback();
    setState(() => _opened.add(n));
    _announce(context, widget.interaction.spots[n].text);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita, spots = widget.interaction.spots;
    return _Frame(
      label: 'İncele',
      prompt: widget.interaction.prompt,
      status: '$_left bakış hakkı',
      children: [
        for (final (n, s) in spots.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: _opened.contains(n) ? p.accentSoft : p.surfaceSunken,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _opened.contains(n) || _left <= 0
                    ? null
                    : () => _open(n),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _opened.contains(n)
                                  ? Icons.visibility
                                  : Icons.search,
                              size: 18,
                              color: p.accent,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                s.label,
                                style: VitaType.serif(
                                  15.5,
                                  p.ink,
                                  weight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_opened.contains(n)) ...[
                          const SizedBox(height: 6),
                          Text(s.text, style: VitaType.body(p)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: 6),
        VitaButton(
          label: _left > 0 ? 'Yeterince baktım' : 'Devam et',
          secondary: _left > 0,
          onPressed: () => widget.onOutcome(
            'done',
            indices: {..._opened},
            found: {
              for (final n in _opened)
                if (spots[n].flag.isNotEmpty) spots[n].flag,
            },
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Hafıza kartları

class MemoryPairs extends StatefulWidget {
  const MemoryPairs({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<MemoryPairs> createState() => _MemoryPairsState();
}

class _MemoryPairsState extends State<MemoryPairs> {
  late final List<String> _cards = [
    ...widget.interaction.items,
    ...widget.interaction.items,
  ]..shuffle(Random(widget.interaction.items.join().length));
  final _matched = <int>{};
  final _open = <int>[];
  late int _left = widget.interaction.attempts;
  bool _busy = false;

  void _flip(int n) {
    if (_busy || _open.contains(n) || _matched.contains(n)) return;
    preferences.feedback();
    setState(() => _open.add(n));
    if (_open.length < 2) return;
    final a = _open[0], b = _open[1];
    if (_cards[a] == _cards[b]) {
      setState(() {
        _matched.addAll([a, b]);
        _open.clear();
      });
      _announce(context, 'Eşleşti: ${_cards[a]}');
      if (_matched.length == _cards.length) {
        preferences.feedback(strong: true);
        widget.onOutcome('success');
      }
      return;
    }
    _busy = true;
    setState(() => _left--);
    _announce(context, 'Eşleşmedi. $_left hata hakkın kaldı.');
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() {
        _open.clear();
        _busy = false;
      });
      if (_left < 0) widget.onOutcome('fail');
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return _Frame(
      label: 'Hatırla',
      prompt: widget.interaction.prompt,
      status: '${max(0, _left)} hata hakkı',
      children: [
        LayoutBuilder(
          builder: (context, c) {
            final cols = _cards.length > 8 ? 4 : 3;
            final w = (c.maxWidth - 8 * (cols - 1)) / cols;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (n, label) in _cards.indexed)
                  SizedBox(
                    width: w,
                    height: 64,
                    child: Semantics(
                      button: true,
                      label: _open.contains(n) || _matched.contains(n)
                          ? label
                          : 'Kart ${n + 1}, kapalı',
                      child: Material(
                        color: _matched.contains(n)
                            ? p.accentSoft
                            : _open.contains(n)
                            ? p.surface
                            : p.surfaceSunken,
                        borderRadius: BorderRadius.circular(10),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _flip(n),
                          child: Center(
                            child: ExcludeSemantics(
                              child: Text(
                                _open.contains(n) || _matched.contains(n)
                                    ? label
                                    : '✦',
                                textAlign: TextAlign.center,
                                style: VitaType.serif(
                                  _open.contains(n) || _matched.contains(n)
                                      ? 14.5
                                      : 18,
                                  _matched.contains(n) ? p.accent : p.ink,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Bütçe paylaştırma

class BudgetSplit extends StatefulWidget {
  const BudgetSplit({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<BudgetSplit> createState() => _BudgetSplitState();
}

class _BudgetSplitState extends State<BudgetSplit> {
  late final List<int> _units = List.filled(
    widget.interaction.buckets.length,
    0,
  );
  int get _used => _units.fold(0, (a, b) => a + b);
  int get _free => widget.interaction.total - _used;

  void _add(int i, int d) {
    if (d > 0 && _free <= 0 || d < 0 && _units[i] <= 0) return;
    preferences.feedback();
    setState(() => _units[i] += d);
  }

  void _submit() {
    final ok =
        _free == 0 &&
        [
          for (final (i, b) in widget.interaction.buckets.indexed)
            _units[i] >= b.min,
        ].every((x) => x);
    preferences.feedback(strong: true);
    widget.onOutcome(ok ? 'success' : 'fail');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return _Frame(
      label: 'Paylaştır',
      prompt: widget.interaction.prompt,
      status: '$_free / ${widget.interaction.total} kaldı',
      children: [
        for (final (i, b) in widget.interaction.buckets.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(child: Text(b.label, style: VitaType.body(p))),
                IconButton(
                  tooltip: '${b.label} azalt',
                  onPressed: _units[i] > 0 ? () => _add(i, -1) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                SizedBox(
                  width: 54,
                  child: Semantics(
                    label: b.label,
                    value: '${_units[i]}',
                    child: ExcludeSemantics(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var k = 0; k < min(_units[i], 5); k++)
                            Container(
                              width: 6,
                              height: 18,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: p.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          if (_units[i] > 5)
                            Text(
                              '+${_units[i] - 5}',
                              style: VitaType.caption(p),
                            ),
                          if (_units[i] == 0)
                            Text('0', style: VitaType.caption(p)),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '${b.label} artır',
                  onPressed: _free > 0 ? () => _add(i, 1) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
        if (widget.interaction.hint.isNotEmpty)
          Text(widget.interaction.hint, style: VitaType.caption(p)),
        const SizedBox(height: 8),
        VitaButton(label: 'Planı onayla', onPressed: _submit),
      ],
    );
  }
}

// ---------------------------------------------------------------- Nefes (basılı tut)

class HoldBreath extends StatefulWidget {
  const HoldBreath({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;
  @override
  State<HoldBreath> createState() => _HoldBreathState();
}

class _HoldBreathState extends State<HoldBreath>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: widget.interaction.holdMs),
  );
  int _done = 0;
  late int _misses = widget.interaction.attempts;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _c.addStatusListener((st) {
      if (st != AnimationStatus.completed || _finished) return;
      preferences.feedback();
      setState(() => _done++);
      _c.value = 0;
      if (_done >= widget.interaction.rounds) {
        _finished = true;
        preferences.feedback(strong: true);
        widget.onOutcome('success');
      }
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _start() {
    if (!_finished) _c.forward(from: 0);
  }

  void _release() {
    if (_finished || !_c.isAnimating) return;
    _c.stop();
    _c.value = 0;
    setState(() => _misses--);
    _announce(context, 'Erken bıraktın.');
    if (_misses < 0) {
      _finished = true;
      widget.onOutcome('fail');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final easy = _easyMode(context);
    return _Frame(
      label: 'Nefes',
      prompt: widget.interaction.prompt,
      status: '$_done / ${widget.interaction.rounds}',
      children: [
        Center(
          child: Semantics(
            button: true,
            label: easy ? 'Nefes al' : 'Basılı tut',
            onTap: easy ? () => _c.forward(from: 0) : null,
            // Listener: parmak değer değmez başlar; kaydırma ile yarışmaz.
            child: Listener(
              onPointerDown: easy ? null : (_) => _start(),
              onPointerUp: easy ? null : (_) => _release(),
              onPointerCancel: easy ? null : (_) => _release(),
              child: GestureDetector(
                onTap: easy ? () => _c.forward(from: 0) : null,
                child: AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) => SizedBox.square(
                    dimension: 132,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.square(
                          dimension: 132,
                          child: CircularProgressIndicator(
                            value: _c.value,
                            strokeWidth: 6,
                            color: p.accent,
                            backgroundColor: p.surfaceSunken,
                          ),
                        ),
                        Container(
                          width: 92 + 18 * _c.value,
                          height: 92 + 18 * _c.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: p.accentSoft,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _c.isAnimating ? 'Ver…' : 'Al',
                            style: VitaType.serif(
                              18,
                              p.accent,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          easy
              ? 'Her dokunuş bir nefes.'
              : 'Halka dolana kadar parmağını kaldırma.',
          textAlign: TextAlign.center,
          style: VitaType.caption(p),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Bilgi sorusu

class QuizCard extends StatelessWidget {
  const QuizCard({
    super.key,
    required this.interaction,
    required this.onOutcome,
  });
  final StoryInteraction interaction;
  final OutcomeCallback onOutcome;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return _Frame(
      label: 'Bil bakalım',
      prompt: interaction.prompt,
      children: [
        for (final (n, o) in interaction.items.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: p.surfaceSunken,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () {
                  preferences.feedback(strong: true);
                  onOutcome(n == interaction.answerIndex ? 'success' : 'fail');
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Text(
                          String.fromCharCode(65 + n),
                          style: VitaType.serif(
                            15,
                            p.accent,
                            weight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(o, style: VitaType.body(p))),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------- Süreli karar

class TimedChoiceBar extends StatefulWidget {
  const TimedChoiceBar({
    super.key,
    required this.interaction,
    required this.onTimeout,
  });
  final StoryInteraction interaction;
  final VoidCallback onTimeout;
  @override
  State<TimedChoiceBar> createState() => _TimedChoiceBarState();
}

class _TimedChoiceBarState extends State<TimedChoiceBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Duration(seconds: widget.interaction.seconds),
  );
  bool _paused = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Ekran okuyucu açıkken süre işlemez: seçenekleri dinlemek zaman alır.
    _paused = _easyMode(context);
    if (_paused) {
      _c.stop();
    } else if (!_c.isAnimating && !_c.isCompleted) {
      _c.forward().whenComplete(() {
        if (mounted && _c.isCompleted) widget.onTimeout();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.interaction.prompt,
            style: VitaType.body(p)
                .copyWith(color: p.accent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          if (_paused)
            Text(
              'Ekran okuyucu açık: süre durduruldu.',
              style: VitaType.caption(p),
            )
          else
            AnimatedBuilder(
              animation: _c,
              builder: (_, _) => Semantics(
                label: 'Kalan süre',
                value:
                    '${(widget.interaction.seconds * (1 - _c.value)).ceil()} saniye',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: 1 - _c.value,
                    minHeight: 6,
                    color: _c.value > .7 ? p.negative : p.accent,
                    backgroundColor: p.surfaceSunken,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Sahne görünümleri

/// Mesajlaşma: "Ad: metin" satırları balon olur; "Sen:" sağda. İki nokta içermeyen satır sistem notudur.
class ChatThread extends StatelessWidget {
  const ChatThread({super.key, required this.text, this.fontScale = 1});
  final String text;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final line in lines)
          () {
            final colon = line.indexOf(':');
            if (colon < 1 || colon > 24) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  line,
                  textAlign: TextAlign.center,
                  style: VitaType.caption(p),
                ),
              );
            }
            final who = line.substring(0, colon).trim(),
                msg = line.substring(colon + 1).trim();
            final me = who == 'Sen';
            return Align(
              alignment: me ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 290),
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: me ? p.accentSoft : p.surfaceSunken,
                  border: Border.all(
                    color: me ? p.accent.withValues(alpha: .5) : p.border,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(me ? 14 : 4),
                    bottomRight: Radius.circular(me ? 4 : 14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!me)
                      Text(
                        who,
                        style: VitaType.caption(p).copyWith(
                          color: p.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    Text(
                      msg,
                      style: VitaType.body(p)
                          .copyWith(fontSize: 15 * fontScale),
                    ),
                  ],
                ),
              ),
            );
          }(),
      ],
    );
  }
}

/// El yazısı not ya da belge.
class PaperNote extends StatelessWidget {
  const PaperNote({super.key, required this.text, this.fontScale = 1});
  final String text;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: p.isDark ? const Color(0xFF2A2433) : const Color(0xFFFFF8EA),
        borderRadius: BorderRadius.circular(4),
        border: Border(
          left: BorderSide(color: p.negative.withValues(alpha: .6), width: 2),
        ),
      ),
      child: Text(
        text,
        style: VitaType.serif(
          17 * fontScale,
          p.ink,
          height: 1.6,
        ).copyWith(fontStyle: FontStyle.italic),
      ),
    );
  }
}

/// Telsiz/kayıt dökümü: eşit aralıklı yazı, kayıt işareti.
class RadioTranscript extends StatelessWidget {
  const RadioTranscript({super.key, required this.text, this.fontScale = 1});
  final String text;
  final double fontScale;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceSunken,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.fiber_manual_record, size: 12, color: p.negative),
              const SizedBox(width: 6),
              Text('KAYIT', style: VitaType.overline(p, color: p.negative)),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14.5 * fontScale,
              height: 1.55,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
