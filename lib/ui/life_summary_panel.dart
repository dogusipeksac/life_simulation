import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import '../game/text.dart';
import 'game_controller.dart';
import 'achievements_screen.dart';

class LifeSummaryPanel extends StatefulWidget {
  const LifeSummaryPanel({super.key, required this.game});
  final GameController game;
  @override
  State<LifeSummaryPanel> createState() => _LifeSummaryPanelState();
}

class _LifeSummaryPanelState extends State<LifeSummaryPanel> {
  String _notice = '';
  @override
  Widget build(BuildContext context) {
    final p = context.vita,
        game = widget.game,
        summary = game.session.buildLifeSummary()!;
    Widget text(String value) => Text(value, style: VitaType.body(p));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('HAYATIN SONU', style: VitaType.overline(p)),
        const SizedBox(height: 8),
        Text(
          summary.endingTitle,
          style: VitaType.display(p).copyWith(fontSize: 32),
        ),
        const SizedBox(height: 12),
        if (summary.endingText.isNotEmpty)
          Text(summary.endingText, style: VitaType.prose(p)),
        const SectionHeader('Bir hayatın özeti'),
        VitaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              text(summary.name),
              text(summary.portrait),
              if (summary.reason != null)
                text(gameOverDisplay(summary.reason!)),
              text('${summary.age} yıl · ${summary.eventsLived} olay'),
              text('Servet: ${formatMoney(summary.money)}'),
              text('Eğitim: ${educationDisplay(summary.educationLevel)}'),
              text('Meslek: ${summary.career}'),
              StatBar(label: 'Sağlık', value: summary.health, color: p.health),
              StatBar(
                label: 'Mutluluk',
                value: summary.happiness,
                color: p.happiness,
              ),
              StatBar(
                label: 'Eğitim',
                value: summary.education,
                color: p.education,
              ),
              StatBar(label: 'Sosyal', value: summary.social, color: p.social),
            ],
          ),
        ),
        SectionHeader(
          'Hayat hedefleri (${summary.completedGoals.length}/${summary.goals.length})',
        ),
        for (final g in summary.goals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: text(
              '${summary.completedGoals.contains(g.id) ? '✓' : '○'} ${g.title}',
            ),
          ),
        if (summary.achievements.isNotEmpty) ...[
          const SectionHeader('Bu hayatta açılan başarımlar'),
          for (final title in summary.achievements) text('★ $title'),
        ],
        const SectionHeader('Bu hayat'),
        Text(summary.story, style: VitaType.prose(p)),
        if (summary.memories.isNotEmpty) ...[
          const SectionHeader('Son anılar'),
          for (final memory in summary.memories)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: text(memory),
            ),
        ],
        if (summary.highlights.isNotEmpty) ...[
          const SectionHeader('Unutulmaz anlar'),
          for (final h in summary.highlights) text('• $h'),
        ],
        const SizedBox(height: 20),
        if (game.session.canSecondChance) ...[
          Text(
            'İsteğe bağlı bir reklamı tamamlayarak sağlığını 20’ye çıkarabilir, bu hayatta bir kez devam edebilirsin.',
            style: VitaType.caption(p),
          ),
          const SizedBox(height: 10),
          VitaButton(
            label: game.rewardBusy
                ? 'Reklam bekleniyor…'
                : 'İkinci şans · bir reklam',
            secondary: true,
            onPressed: !game.rewardBusy && game.ads.rewardedAvailable
                ? () async {
                    final r = await game.secondChance();
                    if (mounted) setState(() => _notice = r.message);
                  }
                : null,
          ),
          const SizedBox(height: 8),
          Text(game.ads.status, style: VitaType.caption(p)),
          if (!game.ads.rewardedAvailable)
            TextButton(
              onPressed: game.rewardBusy ? null : game.refreshAds,
              child: const Text('Reklamı yeniden dene'),
            ),
        ],
        if (_notice.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Semantics(liveRegion: true, child: text(_notice)),
          ),
        const SizedBox(height: 12),
        VitaButton(
          label: 'Başarımlar',
          secondary: true,
          onPressed: () => openAchievements(context, game),
        ),
        const SizedBox(height: 12),
        VitaButton(
          label: 'Yeni bir hayat',
          onPressed: game.rewardBusy ? null : game.leaveToTitle,
        ),
      ],
    );
  }
}
