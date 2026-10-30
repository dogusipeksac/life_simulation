import 'package:flutter/material.dart';
import '../design/preferences.dart';

import '../design/illustrations.dart';
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
        Text('Hayat Simülasyonu', style: VitaType.serif(15, p.accent, weight: FontWeight.w600)),
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

/// Altta yüzen dört sekme; ortada profil madalyonu.
class VitaTabBar extends StatelessWidget {
  const VitaTabBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.playerName,
    required this.female,
    required this.onProfile,
    this.profileSelected = false,
  });
  final int index;
  final ValueChanged<int> onSelect;
  final String playerName;
  final bool female;
  final VoidCallback onProfile;
  final bool profileSelected;

  static const _tabs = [
    (Icons.auto_stories_outlined, 'Hikâye'),
    (Icons.work_outline, 'Kariyer'),
    (Icons.people_outline, 'İlişkiler'),
    (Icons.library_books_outlined, 'Kütüphane'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    Widget tab(int i) {
      final (icon, label) = _tabs[i];
      final selected = !profileSelected && i == index;
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
              child: Tooltip(
                message: 'Profil',
                child: Semantics(
                  button: true,
                  selected: profileSelected,
                  label: 'Profil',
                  child: Material(
                    color: profileSelected ? p.accent.withValues(alpha: .18) : Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {
                        preferences.feedback();
                        onProfile();
                      },
                      child: SizedBox.square(
                        dimension: 52,
                        child: Center(
                          child: PersonMedallion(
                            name: playerName,
                            female: female,
                            size: 40,
                          ),
                        ),
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

