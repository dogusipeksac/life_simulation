import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'palette.dart';
import 'theme.dart';

/// Temel kart: surface, radius 12, 1px kenar. Açık temada çok hafif gölge.
class VitaCard extends StatelessWidget {
  const VitaCard({super.key, required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final radius = BorderRadius.circular(12);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: radius,
        border: Border.all(color: p.border),
        boxShadow: p.isDark
            ? null
            : [BoxShadow(color: const Color(0xFF6B5A3E).withValues(alpha: .06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(padding: padding ?? const EdgeInsets.symmetric(horizontal: 14, vertical: 13), child: child),
        ),
      ),
    );
  }
}

/// Bölüm başlığı: büyük harf, accent, altında saç teli çizgi.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(text.toUpperCase(), style: VitaType.overline(p)),
            const SizedBox(height: 6),
            Container(height: .6, color: p.border),
          ],
        ),
      ),
    );
  }
}

/// Pill biçimli çip.
class VitaChip extends StatelessWidget {
  const VitaChip(this.label, {super.key, this.icon});
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: p.accentSoft,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: p.accent.withValues(alpha: .55)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: p.accent), const SizedBox(width: 5)],
        Flexible(child: Text(label, style: TextStyle(fontSize: 12.5, color: p.accent, fontWeight: FontWeight.w500))),
      ]),
    );
  }
}

const _roman = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII'];

/// Numaralı karar kartı: solda 3px kehribar şerit ve serif Romen rakamı.
class DecisionCard extends StatelessWidget {
  const DecisionCard({
    super.key,
    required this.index,
    required this.text,
    this.hint,
    this.cost,
    this.lockedReason,
    this.onTap,
  });

  final int index;
  final String text;
  final String? hint;
  final String? cost;
  final String? lockedReason;
  final VoidCallback? onTap;

  bool get locked => lockedReason != null;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final radius = BorderRadius.circular(10);
    final numeral = index < _roman.length ? _roman[index] : '${index + 1}';
    return Semantics(
      button: true,
      enabled: !locked,
      label: 'Seçenek ${index + 1}',
      child: Opacity(
        opacity: locked ? .5 : 1,
        child: Material(
          color: p.surfaceSunken,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: locked
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap?.call();
                  },
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: IntrinsicHeight(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Container(width: 3, color: locked ? p.muted : p.accent),
                  SizedBox(
                    width: 44,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(numeral,
                          textAlign: TextAlign.center,
                          style: VitaType.serif(15, p.accent, weight: FontWeight.w600)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 13, 14, 13),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(text, style: VitaType.decision(p)),
                        if (hint != null) ...[const SizedBox(height: 4), Text(hint!, style: VitaType.caption(p))],
                        if (cost != null) ...[
                          const SizedBox(height: 4),
                          Text(cost!, style: VitaType.caption(p).copyWith(color: p.accent, fontWeight: FontWeight.w600)),
                        ],
                        if (locked) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.lock_outline, size: 13, color: p.muted),
                            const SizedBox(width: 4),
                            Expanded(child: Text(lockedReason!, style: VitaType.caption(p))),
                          ]),
                        ],
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Menü satırı: 32×32 rozet + serif başlık + açıklama + ›.
class MenuRow extends StatelessWidget {
  const MenuRow({super.key, required this.icon, required this.title, this.caption, this.onTap});
  final IconData icon;
  final String title;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 17, color: p.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: VitaType.serif(16, p.ink, weight: FontWeight.w500)),
                if (caption != null) Text(caption!, style: VitaType.caption(p)),
              ]),
            ),
            Text('›', style: TextStyle(fontSize: 22, color: p.muted)),
          ]),
        ),
      ),
    );
  }
}

/// İnce stat çubuğu (4px) ve sağda değer.
class StatBar extends StatelessWidget {
  const StatBar({super.key, required this.label, required this.value, required this.color});
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final v = value.clamp(0, 100);
    return Semantics(
      label: '$label $v',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          SizedBox(width: 82, child: Text(label, style: VitaType.body(p).copyWith(fontSize: 13.5))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: TweenAnimationBuilder<double>(
                tween: Tween(end: v / 100),
                duration: Motion.of(context, const Duration(milliseconds: 500)),
                curve: Curves.easeOutCubic,
                builder: (_, t, _) => LinearProgressIndicator(
                  value: t,
                  minHeight: 4,
                  color: color,
                  backgroundColor: p.surfaceSunken,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text('$v', textAlign: TextAlign.right, style: VitaType.caption(p).copyWith(color: p.ink)),
          ),
        ]),
      ),
    );
  }
}

/// Sonuç sayfasındaki ▲/▼ değişim satırı.
class StatDelta extends StatelessWidget {
  const StatDelta({super.key, required this.label, required this.delta});
  final String label;
  final int delta;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final up = delta >= 0;
    final c = up ? p.positive : p.negative;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Text(up ? '▲' : '▼', style: TextStyle(fontSize: 10, color: c)),
      const SizedBox(width: 4),
      Text('$label ${up ? '+' : ''}$delta', style: VitaType.body(p).copyWith(color: c, fontSize: 13.5)),
    ]);
  }
}

/// Ana eylem düğmesi (kehribar).
class VitaButton extends StatelessWidget {
  const VitaButton({super.key, required this.label, this.onPressed, this.secondary = false});
  final String label;
  final VoidCallback? onPressed;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));
    final text = Text(label, style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600));
    const size = Size.fromHeight(52);
    return secondary
        ? OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
                minimumSize: size, foregroundColor: p.accent, side: BorderSide(color: p.border), shape: shape),
            child: text)
        : FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
                minimumSize: size, backgroundColor: p.accent, foregroundColor: p.background, shape: shape),
            child: text);
  }
}

/// Alt sayfa: tutamak, radius 16, karartılmış arka plan (tema ayarlarından).
Future<T?> showVitaSheet<T>(BuildContext context, {required String title, required Widget child}) {
  final p = context.vita;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * .85),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(title, style: VitaType.title(p)),
          const SizedBox(height: 12),
          child,
        ]),
      ),
    ),
  );
}

/// Hareket ayarı: uygulama ayarı ya da sistem "animasyonları kapat" açıksa süre sıfır.
class Motion extends InheritedWidget {
  const Motion({super.key, required this.enabled, required super.child});
  final bool enabled;

  static Duration of(BuildContext context, Duration d) {
    final m = context.dependOnInheritedWidgetOfExactType<Motion>();
    final off = MediaQuery.disableAnimationsOf(context) || !(m?.enabled ?? true);
    return off ? Duration.zero : d;
  }

  @override
  bool updateShouldNotify(Motion oldWidget) => enabled != oldWidget.enabled;
}

/// Sayfa/öğe girişi: fade + hafif ölçek, isteğe bağlı kademeli gecikme.
class EnterAnimation extends StatefulWidget {
  const EnterAnimation({super.key, required this.child, this.index = 0});
  final Widget child;
  final int index;

  @override
  State<EnterAnimation> createState() => _EnterAnimationState();
}

class _EnterAnimationState extends State<EnterAnimation> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this);
  double _delay = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final d = Motion.of(context, const Duration(milliseconds: 300));
    if (d == Duration.zero) {
      _c.value = 1;
      return;
    }
    if (_c.isAnimating || _c.isCompleted) return;
    // Kademeli gecikme zamanlayıcıyla değil, aynı kontrolcünün başındaki boş aralıkla.
    _delay = 50.0 * widget.index.clamp(0, 8);
    _c.duration = d + Duration(milliseconds: _delay.round());
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _c.duration?.inMilliseconds ?? 0;
    final start = total == 0 ? 0.0 : _delay / total;
    final a = CurvedAnimation(parent: _c, curve: Interval(start, 1, curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: .97, end: 1.0).animate(a), child: widget.child),
    );
  }
}
