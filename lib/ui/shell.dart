import 'package:flutter/material.dart';
import '../design/preferences.dart';

import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';

// Ortak iskelet: üstte canlı sosyal akış HUD başlığı, altta yüzen kapsül sekme çubuğu.

/// Üstteki ince Canlı Akış künye şeridi (48px sabit yükseklik).
class VitaKunye extends StatelessWidget {
  const VitaKunye({super.key, required this.name, required this.detail, required this.money});
  final String name, detail, money;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: p.surface.withValues(alpha: p.isDark ? .88 : .94),
        border: Border(bottom: BorderSide(color: p.border.withValues(alpha: .7))),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: p.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text('Hayat Simülasyonu', style: VitaType.serif(14.5, p.accent, weight: FontWeight.w600)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$name · $detail',
              overflow: TextOverflow.ellipsis,
              style: VitaType.caption(p).copyWith(color: p.ink, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: p.accentSoft,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: p.accent.withValues(alpha: .4)),
            ),
            child: Text(
              money,
              style: VitaType.caption(p).copyWith(color: p.accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Hikâye akışının üstünde yer alan 4'lü canlı stat kapsül şeridi.
class FeedStatStrip extends StatelessWidget {
  const FeedStatStrip({
    super.key,
    required this.health,
    required this.happiness,
    required this.education,
    required this.social,
  });

  final int health, happiness, education, social;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return ExcludeSemantics(
      child: Row(
        children: [
          _MiniStatPill(icon: Icons.favorite_rounded, value: health, color: p.health, p: p),
          const SizedBox(width: 6),
          _MiniStatPill(icon: Icons.sentiment_satisfied_alt_rounded, value: happiness, color: p.happiness, p: p),
          const SizedBox(width: 6),
          _MiniStatPill(icon: Icons.school_rounded, value: education, color: p.education, p: p),
          const SizedBox(width: 6),
          _MiniStatPill(icon: Icons.people_alt_rounded, value: social, color: p.social, p: p),
        ],
      ),
    );
  }
}

class _MiniStatPill extends StatelessWidget {
  const _MiniStatPill({
    required this.icon,
    required this.value,
    required this.color,
    required this.p,
  });

  final IconData icon;
  final int value;
  final Color color;
  final VitaPalette p;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0, 100);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 5),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: v / 100,
                  minHeight: 4,
                  color: color,
                  backgroundColor: p.surfaceSunken,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              '$v',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: p.ink),
            ),
          ],
        ),
      ),
    );
  }
}

/// Altta yüzen sekmeler: Kütüphane · Kariyer · Hikâye (ortada) · İlişkiler · Profil madalyonu.
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
    (Icons.dynamic_feed_rounded, 'Hikâye'),
    (Icons.work_outline_rounded, 'Kariyer'),
    (Icons.people_outline_rounded, 'İlişkiler'),
    (Icons.library_books_outlined, 'Kütüphane'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    Widget tab(int i, {bool featured = false}) {
      final (icon, label) = _tabs[i];
      final selected = !profileSelected && i == index;
      final c = selected ? p.accent : p.muted;
      // Ortadaki Hikâye/Akış sekmesi kapsül rozetle öne çıkar.
      final glyph = featured
          ? Container(
              width: 38,
              height: 28,
              decoration: BoxDecoration(
                color: selected ? p.accent : p.accentSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 19, color: selected ? p.background : p.accent),
            )
          : Icon(icon, size: 22, color: c);
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
                glyph,
                const SizedBox(height: 3),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: c, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
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
            color: p.surface.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? .45 : .08),
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(children: [
            tab(3),
            tab(1),
            tab(0, featured: true),
            tab(2),
            Padding(
              padding: const EdgeInsets.only(left: 2, right: 6),
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
          ]),
        ),
      ),
    );
  }
}
