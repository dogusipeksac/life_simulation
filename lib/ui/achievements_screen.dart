import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import 'game_controller.dart';

void openAchievements(BuildContext context, GameController game) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => AchievementsScreen(game: game)),
    );

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.game});
  final GameController game;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: game,
    builder: (context, _) {
      final p = context.vita, service = game.session.achievements;
      final views = service.views
        ..sort(
          (a, b) => a.unlocked == b.unlocked
              ? a.id.compareTo(b.id)
              : a.unlocked
              ? -1
              : 1,
        );
      return Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(title: const Text('Başarımlar')),
        body: Backdrop(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(18),
              children: [
                VitaChip(
                  '${service.unlockedCount} / ${service.definitions.length} açıldı',
                ),
                const SizedBox(height: 16),
                if (service.notice.isNotEmpty)
                  Text(service.notice, style: VitaType.body(p)),
                for (final view in views)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LifeSimulationCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${view.unlocked ? '★' : '◇'} ${view.title}',
                            style: VitaType.cardTitle(p),
                          ),
                          const SizedBox(height: 8),
                          Text(view.description, style: VitaType.caption(p)),
                          if (view.unlocked)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: VitaChip('✓ Açıldı'),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
