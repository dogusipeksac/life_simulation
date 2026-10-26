import 'package:flutter/material.dart';
import '../design/preferences.dart';

import '../design/palette.dart';
import '../design/theme.dart';

// Ortak iskelet: üstte künye şeridi, altta yüzen sekme çubuğu.

/// Üstteki ince künye şeridi.
class VitaKunye extends StatelessWidget {
  const VitaKunye({super.key, required this.name, required this.detail, required this.money});
  final String name, detail, money;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: p.border.withValues(alpha: .6)))),
      child: Row(children: [
        Text('vita ✦', style: VitaType.serif(18, p.accent, weight: FontWeight.w600)),
        const SizedBox(width: 12),
        Expanded(
          child: Text('$name · $detail',
              overflow: TextOverflow.ellipsis, style: VitaType.caption(p).copyWith(color: p.ink)),
        ),
        Text(money, style: VitaType.caption(p).copyWith(color: p.accent, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

/// Altta yüzen 5 duraklı sekme çubuğu; ortada kehribar "Yeni yaş".
class VitaTabBar extends StatelessWidget {
  const VitaTabBar({super.key, required this.index, required this.onSelect, required this.onNewAge});
  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onNewAge;

  static const _tabs = [
    (Icons.auto_stories_outlined, 'Hikâye'),
    (Icons.work_outline, 'Kariyer'),
    (Icons.people_outline, 'İlişkiler'),
    (Icons.person_outline, 'Kişisel'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    Widget tab(int i) {
      final (icon, label) = _tabs[i];
      final selected = i == index;
      final c = selected ? p.accent : p.muted;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: InkResponse(
            onTap: () {
              preferences.feedback();
              onSelect(i);
            },
            radius: 32,
            child: SizedBox(
              height: 60,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(icon, size: 22, color: c),
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
              ]),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            color: p.surface.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: p.border),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: p.isDark ? .4 : .08), blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Row(children: [
            tab(0),
            tab(1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Semantics(
                button: true,
                label: 'Yeni yaş',
                child: Material(
                  color: p.accent,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    customBorder: const StadiumBorder(),
                    onTap: () {
                      preferences.feedback(strong: true);
                      onNewAge();
                    },
                    child: SizedBox(
                      height: 48,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.cake_outlined, size: 18, color: p.background),
                          const SizedBox(width: 6),
                          Text('Yeni yaş', style: TextStyle(color: p.background, fontWeight: FontWeight.w700, fontSize: 13.5)),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            tab(2),
            tab(3),
          ]),
        ),
      ),
    );
  }
}

