import 'dart:math';

import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import 'game_controller.dart';

/// Beş tur; ödül yalnızca kalıcı oturum token'ı ile bir kez verilir.
class MiniGameScreen extends StatefulWidget {
  const MiniGameScreen({
    super.key,
    required this.game,
    required this.kind,
    required this.token,
  });
  final GameController game;
  final String kind, token;
  @override
  State<MiniGameScreen> createState() => _MiniGameScreenState();
}

class _MiniGameScreenState extends State<MiniGameScreen> {
  static const names = ['Defne', 'Mert', 'Ece'];
  static const colors = [
    Color(0xff9677d3),
    Color(0xff4c9986),
    Color(0xffd87173),
  ];
  static const colorNames = ['Mor', 'Mint', 'Mercan'];
  final _random = Random();
  int _round = 0, _score = 0, _answer = 0, _offset = 0;
  bool _study = true, _answered = false;
  String _message = '';
  @override
  void initState() {
    super.initState();
    if (widget.kind == 'balls') {
      _study = false;
      _question();
    }
  }

  void _question() {
    _answer = _random.nextInt(3);
    _offset = _random.nextInt(3);
    _answered = false;
    _message = '';
  }

  void _choose(int i) {
    if (_answered) return;
    setState(() {
      _answered = true;
      final correct = i == _answer;
      if (correct) _score++;
      _round++;
      _message = correct
          ? '✓ Harika, doğru!'
          : 'Bu kez olmadı. Doğru cevap: ${widget.kind == 'memory' ? names[_answer] : colorNames[_answer]}';
      if (_round == 5) {
        _message +=
            '\n${widget.game.finishMiniGame(widget.token, _score).message}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        title: Text(
          widget.kind == 'memory' ? 'Yüz–isim eşleştirme' : 'Toplar ve kutular',
        ),
      ),
      body: Backdrop(
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            if (_study) ...[
              Text('Bu üç yüzü ve ismi aklında tut.', style: VitaType.title(p)),
              const SizedBox(height: 16),
              for (var i = 0; i < names.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: LifeSimulationCard(
                    child: Row(
                      children: [
                        PersonMedallion(name: names[i], female: i != 1),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(names[i], style: VitaType.cardTitle(p)),
                        ),
                      ],
                    ),
                  ),
                ),
              VitaButton(
                label: 'Hazırım · Başla',
                onPressed: () => setState(() {
                  _study = false;
                  _question();
                }),
              ),
            ] else ...[
              VitaChip(
                'TUR ${_answered ? _round : _round + 1} / 5 · $_score DOĞRU',
              ),
              const SizedBox(height: 18),
              Text(
                widget.kind == 'memory'
                    ? 'Bu kişinin adı neydi?'
                    : 'Topu aynı renkteki kutuya gönder',
                style: VitaType.title(p),
              ),
              const SizedBox(height: 20),
              if (widget.kind == 'memory')
                Center(
                  child: PersonMedallion(
                    name: names[_answer],
                    female: _answer != 1,
                    size: 130,
                  ),
                )
              else
                Semantics(
                  label: '${colorNames[_answer]} top',
                  child: Icon(Icons.circle, color: colors[_answer], size: 130),
                ),
              const SizedBox(height: 20),
              for (var j = 0; j < 3; j++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: VitaButton(
                    label: widget.kind == 'memory'
                        ? names[(j + _offset) % 3]
                        : '${colorNames[(j + _offset) % 3]} kutu',
                    secondary: true,
                    onPressed: _answered
                        ? null
                        : () => _choose((j + _offset) % 3),
                  ),
                ),
              if (_message.isNotEmpty)
                Semantics(
                  liveRegion: true,
                  child: Text(_message, style: VitaType.body(p)),
                ),
              const SizedBox(height: 16),
              if (_answered && _round < 5)
                VitaButton(
                  label: 'Sonraki tur',
                  onPressed: () => setState(_question),
                ),
              if (_round == 5)
                VitaButton(
                  label: 'Aktivitelere dön',
                  onPressed: () => Navigator.pop(context),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
