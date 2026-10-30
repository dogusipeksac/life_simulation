import 'package:flutter/material.dart';
import '../design/preferences.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import '../game/session.dart';
import '../game/state.dart';
import '../game/text.dart';
import 'game_controller.dart';
import '../game/fate.dart';

/// Açılış: yalnızca devam et ve yeni bir hayata başla. Kütüphane, rozetler ve gizlilik oyunun içinde.
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key, required this.game});
  final GameController game;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Scaffold(
      backgroundColor: p.background,
      body: Backdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) => LayoutBuilder(
              builder: (context, c) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: c.maxHeight - 48),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const SizedBox(height: 24),
                        EnterAnimation(
                          child: Text('Hayat Simülasyonu',
                              textAlign: TextAlign.center, style: VitaType.display(p).copyWith(color: p.accent)),
                        ),
                        const SizedBox(height: 6),
                        Text('Bir hayatın kitabı', textAlign: TextAlign.center, style: VitaType.serif(16, p.muted)),
                        const SizedBox(height: 28),
                        const EnterAnimation(index: 1, child: AtmosphereStrip(stage: 0, height: 170)),
                      ]),
                      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const SizedBox(height: 28),
                        if (game.notice != null) ...[
                          LifeSimulationCard(child: Text(game.notice!, style: VitaType.body(p))),
                          const SizedBox(height: 16),
                        ],
                        if (game.hasSave) ...[
                          EnterAnimation(
                            index: 2,
                            child: VitaButton(label: 'Kaldığın yerden devam et', onPressed: () => game.continueGame()),
                          ),
                          const SizedBox(height: 10),
                        ],
                        EnterAnimation(
                          index: 3,
                          child: VitaButton(
                            label: 'Yeni bir hayata başla',
                            secondary: game.hasSave,
                            onPressed: () => Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => CreationWizard(game: game))),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Bütün karakterler, kurumlar ve olaylar kurgusaldır.',
                          textAlign: TextAlign.center,
                          style: VitaType.caption(p),
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Yeni hayat: ad, cinsiyet ve doğum günü önerilir (değiştirilebilir); gerisi kaderin.
/// Kader bir kez atılır; yeniden atılmaz. Her oyuncu başka bir hayatla karşılaşır.
class CreationWizard extends StatefulWidget {
  const CreationWizard({super.key, required this.game});
  final GameController game;

  @override
  State<CreationWizard> createState() => _CreationWizardState();
}

class _CreationWizardState extends State<CreationWizard> {
  static const _paces = ['Uzun hayat', 'Klasik'];

  final int _seed = GameController.newSeed();
  late final _identity = suggestIdentity(_seed);
  late final _name = TextEditingController(text: _identity.name);
  late final profile = CharacterProfile()
    ..detailedLife = true
    ..gender = _identity.gender
    ..birthDay = _identity.day
    ..birthMonth = _identity.month;
  int _nameVariant = 0;
  bool _revealed = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _reveal() {
    final err = GameSession.validatePlayerName(_name.text);
    if (err != null) return setState(() => _error = err);
    FocusScope.of(context).unfocus();
    applyFate(profile, _seed);
    preferences.feedback(strong: true);
    setState(() {
      _error = null;
      _revealed = true;
    });
  }

  void _start() {
    final family = widget.game.previewFamily(_seed);
    if (family != null) profile.familyId = family.id;
    preferences.feedback(strong: true);
    widget.game.startNewGame(_name.text, seed: _seed, profile: profile);
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return PopScope(
      // Kader görüldükten sonra geri dönüp yeniden atmak yok.
      canPop: !_revealed,
      child: Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: p.ink,
          automaticallyImplyLeading: !_revealed,
          title: Text(_revealed ? 'Kaderin' : 'Yeni bir hayat', style: VitaType.caption(p)),
          centerTitle: true,
        ),
        body: Backdrop(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                KeyedSubtree(
                  key: ValueKey(_revealed),
                  child: EnterAnimation(child: _revealed ? _fate(p) : _identityStep(p)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _identityStep(VitaPalette p) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(header: true, child: Text('Bu hikâyenin adı ne?', style: VitaType.title(p))),
        const SizedBox(height: 6),
        Text('Senin için bir ad önerdik. İstersen değiştir; gerisini kader seçecek.', style: VitaType.caption(p)),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _field(p, 'Karakterin adı', _name, GameSession.maxPlayerNameLength)),
          const SizedBox(width: 6),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IconButton.filledTonal(
              tooltip: 'Başka bir ad öner',
              onPressed: () => setState(() => _name.text = suggestName(profile.gender, _seed, ++_nameVariant)),
              icon: const Icon(Icons.casino_outlined),
            ),
          ),
        ]),
        _label(p, 'Cinsiyet'),
        _chips(p, CharacterProfile.genders, profile.gender, (v) => profile.gender = v),
        _label(p, 'Doğum günü'),
        Row(children: [
          Expanded(
            flex: 2,
            child: KeyedSubtree(
              key: ValueKey(profile.birthMonth),
              child: _dropdown(p, [for (var d = 1; d <= CharacterProfile.daysInMonth(profile.birthMonth); d++) '$d'],
                  '${profile.birthDay}', (v) => profile.birthDay = int.parse(v)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: _dropdown(p, CharacterProfile.monthNames, CharacterProfile.monthNames[profile.birthMonth - 1], (v) {
              profile.birthMonth = CharacterProfile.monthNames.indexOf(v) + 1;
              profile.birthDay = profile.birthDay.clamp(1, CharacterProfile.daysInMonth(profile.birthMonth));
            }),
          ),
        ]),
        _label(p, 'Oyun temposu'),
        _chips(p, _paces, _paces[profile.detailedLife ? 0 : 1], (v) => profile.detailedLife = v == _paces[0]),
        const SizedBox(height: 6),
        Text('Uzun hayatta daha çok karar verirsin; klasikte yıllar daha hızlı geçer.', style: VitaType.caption(p)),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: VitaType.body(p).copyWith(color: p.negative)),
        ],
        const SizedBox(height: 22),
        LifeSimulationCard(
          child: Row(children: [
            Icon(Icons.casino_outlined, color: p.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nerede doğacağını, hangi ailede, kimin yanında büyüyeceğini ve nasıl biri olacağını sen seçmeyeceksin. Kader bir kez atılır.',
                style: VitaType.caption(p).copyWith(color: p.ink),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),
        VitaButton(label: 'Kaderimi göster', onPressed: _reveal),
      ]);

  Widget _fate(VitaPalette p) {
    final family = widget.game.previewFamily(_seed);
    Widget row(IconData icon, String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: Row(children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 19, color: p.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(label, style: VitaType.caption(p)),
                Text(value, style: VitaType.serif(16, p.ink, weight: FontWeight.w500)),
              ]),
            ),
          ]),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(child: PersonMedallion(name: _name.text, female: profile.gender == 'Kadın', size: 84)),
      const SizedBox(height: 10),
      Text(_name.text.trim(), textAlign: TextAlign.center, style: VitaType.title(p)),
      Text('${profile.birthdayText} · ${profile.gender}', textAlign: TextAlign.center, style: VitaType.caption(p)),
      const SizedBox(height: 18),
      LifeSimulationCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (family?.tier != null) VitaChip(wealthDisplay(family!.tier!), icon: Icons.casino_outlined),
          const SizedBox(height: 10),
          Text(family?.name ?? 'Bir aile', style: VitaType.cardTitle(p)),
          const SizedBox(height: 6),
          Text(family?.description ?? '', style: VitaType.prose(p).copyWith(fontSize: 16)),
        ]),
      ),
      const SizedBox(height: 12),
      LifeSimulationCard(
        child: Column(children: [
          row(Icons.location_city_outlined, 'Doğum yeri', profile.birthplace),
          row(Icons.family_restroom, 'Aile ortamı', profile.family),
          row(Icons.volunteer_activism_outlined, 'Yanında büyüyeceğin', profile.caregiver),
          row(Icons.psychology_outlined, 'Mizacın', profile.personality),
          row(Icons.auto_awesome_outlined, 'Hayalin', profile.dream),
        ]),
      ),
      const SizedBox(height: 18),
      VitaButton(label: 'Hayata başla', onPressed: _start),
    ]);
  }

  Widget _label(VitaPalette p, String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(upperTr(text), style: VitaType.overline(p)),
      );

  Widget _field(VitaPalette p, String label, TextEditingController c, int max) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TextField(
          controller: c,
          maxLength: max,
          textCapitalization: TextCapitalization.words,
          style: VitaType.serif(17, p.ink),
          decoration: InputDecoration(
            labelText: label,
            filled: true,
            fillColor: p.surfaceSunken,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: p.accent)),
          ),
        ),
      );

  Widget _chips(VitaPalette p, List<String> options, String selected, ValueChanged<String> onPick) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in options)
            ChoiceChip(
              label: Text(o),
              selected: o == selected,
              showCheckmark: false,
              materialTapTargetSize: MaterialTapTargetSize.padded,
              labelStyle: TextStyle(color: o == selected ? p.accent : p.ink, fontSize: 13.5),
              backgroundColor: p.surfaceSunken,
              selectedColor: p.accentSoft,
              side: BorderSide(color: o == selected ? p.accent : p.border),
              shape: const StadiumBorder(),
              onSelected: (_) => setState(() => onPick(o)),
            ),
        ],
      );

  Widget _dropdown(VitaPalette p, List<String> items, String value, ValueChanged<String> onPick) =>
      DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        dropdownColor: p.surface,
        style: VitaType.body(p),
        decoration: InputDecoration(
          filled: true,
          fillColor: p.surfaceSunken,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
        items: [for (final i in items) DropdownMenuItem(value: i, child: Text(i))],
        onChanged: (v) => setState(() => onPick(v!)),
      );
}
