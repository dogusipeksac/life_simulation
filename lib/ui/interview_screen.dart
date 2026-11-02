// Başvuru mülakatı: üç soru, her cevaba görüşmecinin tepkisi, sonunda izlenim.
// Tamamlanan mülakat geri döner; vazgeçilirse null döner ve başvuru yapılmaz.
import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import '../game/interview.dart';
import '../game/state.dart';

Future<Interview?> runInterview(BuildContext context, Interview interview, GameState state) =>
    Navigator.of(context).push<Interview>(
      MaterialPageRoute(builder: (_) => InterviewScreen(interview: interview, state: state)),
    );

class InterviewScreen extends StatefulWidget {
  const InterviewScreen({super.key, required this.interview, required this.state});
  final Interview interview;
  final GameState state;

  @override
  State<InterviewScreen> createState() => _InterviewScreenState();
}

class _InterviewScreenState extends State<InterviewScreen> {
  InterviewReply? _reply;
  Interview get iv => widget.interview;

  void _answer(int i) => setState(() => _reply = iv.answer(widget.state, i));

  void _next() => setState(() => _reply = null);

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final q = _reply == null ? iv.current : iv.questions[iv.replies.length - 1];
    final step = _reply == null ? iv.replies.length : iv.replies.length - 1;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('Mülakat', style: VitaType.cardTitle(p)),
        leading: IconButton(
          tooltip: 'Vazgeç',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Backdrop(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            VitaChip(iv.career.name.toUpperCase(), icon: Icons.work_outline),
            const SizedBox(height: 6),
            Text(iv.career.theme, style: VitaType.caption(p)),
            const SizedBox(height: 18),
            Row(children: [
              for (var i = 0; i < iv.questions.length; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == iv.questions.length - 1 ? 0 : 6),
                    decoration: BoxDecoration(
                      color: i < iv.replies.length ? p.accent : p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 18),
            if (q == null) ..._verdict(p) else ...[
              Text('SORU ${step + 1} / ${iv.questions.length}', style: VitaType.overline(p, color: p.accent)),
              const SizedBox(height: 8),
              Text(q.question, style: VitaType.title(p)),
              const SizedBox(height: 18),
              if (_reply == null)
                for (final (i, a) in q.answers.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DecisionCard(index: i, text: a.text, onTap: () => _answer(i)),
                  )
              else ...[
                _replyCard(p, _reply!),
                const SizedBox(height: 16),
                VitaButton(label: iv.done ? 'Görüşmeyi bitir' : 'Sonraki soru', onPressed: _next),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _replyCard(VitaPalette p, InterviewReply r) {
    final good = r.score > 0;
    final color = r.bluff || r.score < 0 ? p.negative : good ? p.positive : p.muted;
    return LifeSimulationCard(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(r.bluff ? Icons.visibility_outlined : good ? Icons.thumb_up_alt_outlined : Icons.remove_circle_outline,
            color: color, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (r.bluff) ...[
              Text('BLÖF FARK EDİLDİ', style: VitaType.overline(p, color: p.negative)),
              const SizedBox(height: 4),
            ],
            Text(r.text, style: VitaType.prose(p)),
          ]),
        ),
      ]),
    );
  }

  List<Widget> _verdict(VitaPalette p) => [
        Text('GÖRÜŞME BİTTİ', style: VitaType.overline(p, color: p.accent)),
        const SizedBox(height: 8),
        Text(iv.verdict, style: VitaType.title(p)),
        const SizedBox(height: 12),
        Text(
          iv.rejected
              ? 'Bu dönem aynı işe tekrar başvuramazsın.'
              : iv.bonus >= 0
                  ? 'Mülakat kabul şansını +%${iv.bonus} etkiledi.'
                  : 'Mülakat kabul şansını −%${-iv.bonus} etkiledi.',
          style: VitaType.body(p),
        ),
        const SizedBox(height: 20),
        VitaButton(label: 'Sonucu öğren', onPressed: () => Navigator.of(context).pop(iv)),
      ];
}
