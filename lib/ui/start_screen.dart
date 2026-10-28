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
import 'story_library_screen.dart';
import 'achievements_screen.dart';
import 'privacy_screen.dart';

/// Açılış: logo, atmosfer şeridi, kayıtlı hayata devam, yeni hayat.
class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key, required this.game, this.onGallery});
  final GameController game;
  final VoidCallback? onGallery;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Scaffold(
      backgroundColor: p.background,
      body: Backdrop(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: game,
            builder: (context, _) => ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              children: [
                EnterAnimation(child: Text('vita ✦', textAlign: TextAlign.center, style: VitaType.display(p).copyWith(color: p.accent))),
                const SizedBox(height: 6),
                Text('Bir hayatın kitabı', textAlign: TextAlign.center, style: VitaType.serif(16, p.muted)),
                const SizedBox(height: 24),
                const EnterAnimation(index: 1, child: AtmosphereStrip(stage: 0, height: 150)),
                const SizedBox(height: 24),
                if (game.notice != null) ...[
                  VitaCard(child: Text(game.notice!, style: VitaType.body(p))),
                  const SizedBox(height: 16),
                ],
                if (game.hasSave) ...[
                  EnterAnimation(
                    index: 2,
                    child: VitaButton(label: 'Kayıtlı hayata devam et', onPressed: () => game.continueGame()),
                  ),
                  const SizedBox(height: 10),
                ],
                EnterAnimation(
                  index: 3,
                  child: VitaButton(
                    label: 'Yeni bir hayat',
                    secondary: game.hasSave,
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreationWizard(game: game))),
                  ),
                ),
                const SizedBox(height: 10),
                VitaButton(label: 'Hikâye kütüphanesi', secondary: true, onPressed: () => openStoryLibrary(context, game)),
                const SizedBox(height: 10),
                VitaButton(label: 'Başarımlar', secondary: true, onPressed: () => openAchievements(context, game)),
                TextButton(onPressed: () => openPrivacy(context), child: const Text('Gizlilik ve bağlantılar')),
                const SizedBox(height: 28),
                Text(
                  'Bütün karakterler, kurumlar ve olaylar kurgusaldır. Ana oyun çevrimdışı çalışır. Reklam ve mağaza özellikleri bağlantı kullanır.',
                  textAlign: TextAlign.center,
                  style: VitaType.caption(p),
                ),
                if (onGallery != null) TextButton(onPressed: onGallery, child: const Text('Stil galerisi')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 4 adım: kimlik → köken → mizaç → kader zarı. (Godot: UI/CharacterCreation.cs)
class CreationWizard extends StatefulWidget {
  const CreationWizard({super.key, required this.game});
  final GameController game;

  @override
  State<CreationWizard> createState() => _CreationWizardState();
}

class _CreationWizardState extends State<CreationWizard> {
  static const _titles = ['Bu hikâyenin adı ne?', 'Nerede, kimlerle büyüyecek?', 'Nasıl biri olacak?', 'Kaderin Zarı'];
  static const _families = ['Çekirdek aile', 'Geniş aile', 'Tek ebeveynli aile', 'Koruyucu aile'];
  static const _personalities = ['Meraklı', 'Sakin', 'Dışa dönük', 'Hayalperest'];
  static const _dreams = ['Kendi yolumu bulmak', 'Yeni şeyler keşfetmek', 'İnsanlara yardım etmek', 'Bir eser bırakmak'];
  static const _paces = ['Uzun hayat · daha küçük zaman adımları', 'Klasik · daha hızlı yıllar'];

  final _name = TextEditingController();
  final _birthplace = TextEditingController(text: 'İstanbul');
  final _caregiver = TextEditingController(text: 'Ailem');
  final profile = CharacterProfile()..detailedLife = true;
  int _step = 0;
  String? _error;
  int _seed = GameController.newSeed();

  @override
  void dispose() {
    _name.dispose();
    _birthplace.dispose();
    _caregiver.dispose();
    super.dispose();
  }

  void _next() {
    if (_step == 0) {
      final err = GameSession.validatePlayerName(_name.text);
      if (err != null) return setState(() => _error = err);
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _error = null;
      _step++;
    });
  }

  void _start() {
    profile
      ..birthplace = _birthplace.text
      ..caregiver = _caregiver.text;
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
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: p.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: p.ink,
          title: Text('${_step + 1} / 4', style: VitaType.caption(p)),
          centerTitle: true,
        ),
        body: Backdrop(
          child: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (_step + 1) / 4,
                    minHeight: 3,
                    color: p.accent,
                    backgroundColor: p.surfaceSunken,
                  ),
                ),
                const SizedBox(height: 20),
                Semantics(header: true, child: Text(_titles[_step], style: VitaType.title(p))),
                const SizedBox(height: 16),
                KeyedSubtree(key: ValueKey(_step), child: EnterAnimation(child: _body(p))),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: VitaType.body(p).copyWith(color: p.negative)),
                ],
                const SizedBox(height: 24),
                VitaButton(label: _step < 3 ? 'Devam' : 'Hayata başla', onPressed: _step < 3 ? _next : _start),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(VitaPalette p) => switch (_step) {
        0 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _field(p, 'Karakterin adı', _name, 'Örneğin Deniz', GameSession.maxPlayerNameLength),
            _label(p, 'Cinsiyet'),
            _chips(p, CharacterProfile.genders, profile.gender, (v) => profile.gender = v),
            _label(p, 'Doğum günü'),
            Row(children: [
              Expanded(
                flex: 2,
                child: KeyedSubtree(key: ValueKey(profile.birthMonth), child: _dropdown(p, [for (var d = 1; d <= CharacterProfile.daysInMonth(profile.birthMonth); d++) '$d'],
                    '${profile.birthDay}', (v) => profile.birthDay = int.parse(v))),
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
            const SizedBox(height: 12),
            Text('Kurgusal bir karakter yaratıyorsun. Gerçek adını veya kişisel bilgilerini paylaşman gerekmiyor.',
                style: VitaType.caption(p)),
          ]),
        1 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _field(p, 'Doğduğu şehir veya kasaba', _birthplace, 'İstanbul', 32),
            _label(p, 'Aile ortamı'),
            _chips(p, _families, profile.family, (v) => profile.family = v),
            const SizedBox(height: 8),
            _field(p, 'Bakım verenine nasıl sesleniyor?', _caregiver, 'Ailem', 24),
          ]),
        2 => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _label(p, 'Mizacı'),
            _chips(p, _personalities, profile.personality, (v) => profile.personality = v),
            _label(p, 'Büyürken hayali'),
            _chips(p, _dreams, profile.dream, (v) => profile.dream = v),
            _label(p, 'Oyun temposu'),
            _chips(p, _paces, _paces[profile.detailedLife ? 0 : 1], (v) => profile.detailedLife = v == _paces[0]),
            const SizedBox(height: 8),
            Text(
              'Uzun hayatta daha çok karar verirsin. Bebeklikte bakım verenlerin senin adına karar alır; büyüdükçe kendi yolunu çizersin.',
              style: VitaType.caption(p),
            ),
          ]),
        _ => _fate(p),
      };

  Widget _fate(VitaPalette p) {
    final family = widget.game.previewFamily(_seed);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Doğacağın aileyi sen seçmiyorsun. Zar atıldı:', style: VitaType.body(p).copyWith(color: p.muted)),
      const SizedBox(height: 12),
      VitaCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (family?.tier != null) VitaChip(wealthDisplay(family!.tier!), icon: Icons.casino_outlined),
          const SizedBox(height: 10),
          Text(family?.name ?? 'Bir aile', style: VitaType.cardTitle(p)),
          const SizedBox(height: 6),
          Text(family?.description ?? '', style: VitaType.prose(p).copyWith(fontSize: 16)),
        ]),
      ),
      const SizedBox(height: 10),
      TextButton.icon(
        onPressed: () => setState(() => _seed = GameController.newSeed()),
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Zarı yeniden at'),
        style: TextButton.styleFrom(foregroundColor: p.accent, minimumSize: const Size.fromHeight(48)),
      ),
    ]);
  }

  Widget _label(VitaPalette p, String text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 8),
        child: Text(upperTr(text), style: VitaType.overline(p)),
      );

  Widget _field(VitaPalette p, String label, TextEditingController c, String hint, int max) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TextField(
          controller: c,
          maxLength: max,
          textCapitalization: TextCapitalization.words,
          style: VitaType.serif(17, p.ink),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
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
