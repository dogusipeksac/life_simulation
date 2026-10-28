import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/preferences.dart';
import '../design/theme.dart';
import '../game/director.dart';
import '../game/progression.dart';
import '../game/session.dart';
import '../game/social.dart';
import '../game/state.dart';
import '../game/text.dart';
import '../game/voice.dart';
import '../game/wedding.dart';
import '../game/world.dart';
import 'game_controller.dart';
import 'story_library_screen.dart';
import 'achievements_screen.dart';
import 'privacy_screen.dart';
import 'mini_game.dart';

/// P3 sayfaları yalnızca durumu okur ve controller'a niyet gönderir.
class LifePage extends StatefulWidget {
  const LifePage({
    super.key,
    required this.game,
    required this.page,
    required this.navigate,
    this.personId,
  });
  final GameController game;
  final String page;
  final String? personId;
  final ValueChanged<String> navigate;
  @override
  State<LifePage> createState() => _LifePageState();
}

class _LifePageState extends State<LifePage> {
  final _amount = TextEditingController(text: '100');
  String _message = '', _query = '';
  bool _allJobs = false;
  int _memories = 20;
  GameController get game => widget.game;
  GameState get s => game.state!;
  Progression get rules => game.session.progression;
  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void result(ActionResult r) {
    setState(() => _message = r.message);
  }

  void go(String page) {
    game.save();
    widget.navigate(page);
  }

  Widget text(String value, {bool caption = false}) => Text(
    value,
    style: caption
        ? VitaType.caption(context.vita)
        : VitaType.body(context.vita),
  );
  Widget info(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Wrap(
      spacing: 8,
      runSpacing: 3,
      alignment: WrapAlignment.spaceBetween,
      children: [text(label, caption: true), text(value)],
    ),
  );
  Widget card(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: VitaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: VitaType.overline(context.vita)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    ),
  );
  Widget button(String label, VoidCallback? action, {bool secondary = true}) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: VitaButton(
          label: label,
          onPressed: action,
          secondary: secondary,
        ),
      );
  Future<bool> confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Onayla'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) {
    final children = switch (widget.page) {
      'career' => career(),
      'relationships' => relationships(),
      'person' => person(),
      'profile' => profile(),
      'activities' => activities(),
      'finance' => finance(),
      'bank' => bank(),
      'world' => world(),
      'journal' => journal(),
      'life' => life(),
      _ => menu(),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 128),
      children: [
        if (![
          'career',
          'relationships',
          'profile',
          'menu',
        ].contains(widget.page))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => go(
                widget.page == 'person'
                    ? 'relationships'
                    : widget.page == 'bank'
                    ? 'finance'
                    : 'menu',
              ),
              icon: const Icon(Icons.chevron_left),
              label: Text(
                widget.page == 'person'
                    ? 'İlişkiler'
                    : widget.page == 'bank'
                    ? 'Finans'
                    : 'Menü',
              ),
            ),
          ),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Semantics(
              liveRegion: true,
              child: VitaCard(child: text(_message)),
            ),
          ),
        ...children,
      ],
    );
  }

  List<Widget> career() {
    final c = game.session.content.careers[s.careerId];
    final goals = game.session.content.goals.where(
      (g) => s.activeGoalIds.contains(g.id),
    );
    final jobs = (_allJobs ? rules.views(s) : rules.openings(s)).where(
      (v) =>
          lowerInvariant('${v.career.name} ${v.career.theme}')
              .contains(lowerInvariant(_query)),
    );
    return [
      Text('Geleceğini şekillendir', style: VitaType.title(context.vita)),
      const SizedBox(height: 14),
      card('ŞU ANKİ DURUMUN', [
        text(game.session.describeOccupation()),
        info('Eğitim', educationDisplay(s.educationLevel)),
        if (s.studyLevel != null)
          info(
            'Öğrenim',
            '${educationDisplay(s.studyLevel!)} · ${s.age - s.studyStartAge}. yıl',
          ),
        if (c != null) ...[
          info('Basamak', '${s.careerLevel} / ${c.levels.length}'),
          info('Aylık maaş', formatMoney(rules.salary(s))),
          button('İşinden istifa et', () async {
            if (await confirm(
              'İstifa etmek istiyor musun?',
              'Maaşın kesilecek. Bu işe yeniden başvurmak için 90 gün beklemen gerekecek.',
            )) {
              if (!mounted) return;
              game.quitCareer();
              setState(() => _message = 'İşinden ayrıldın.');
            }
          }),
        ],
        if (c == null)
          text(
            s.age < 16
                ? 'Çalışmak için henüz çok küçüksün. Şimdilik okul ve oyun zamanı.'
                : s.studyLevel != null
                ? 'Okuyorsun. Mezun olunca daha çok kapı açılır; yine de ilanlara bakabilirsin.'
                : 'Şu an çalışmıyorsun. Aşağıdaki ilanlara başvurabilir ya da kaderine güvenebilirsin.',
            caption: true,
          ),
      ]),
      card('HAYAT HEDEFLERİN', [
        for (final g in goals)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: text(
              '${s.completedGoalIds.contains(g.id) ? '✓' : '○'} ${g.title}\n${g.description}',
            ),
          ),
      ]),
      card('AYLIK BÜTÇEN', budget()),
      const SectionHeader('İş ilanları'),
      text(
        'İlanlar ${180 - s.day % 180} gün sonra yenilenir. Başvurular zamanı ilerletmez.',
        caption: true,
      ),
      button(
        'Kaderine güven',
        s.isGameOver ? null : () => result(game.trustFate()),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: text('Tüm meslekler'),
        value: _allJobs,
        onChanged: (v) => setState(() => _allJobs = v),
      ),
      TextField(
        decoration: const InputDecoration(
          labelText: 'Meslek veya alan ara',
          prefixIcon: Icon(Icons.search),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: 12),
      for (final v in jobs)
        card(v.career.name, [
          text(v.career.theme, caption: true),
          text(v.career.description),
          info('Başlangıç maaşı', formatMoney(salaryAt(v.career, 1))),
          info('Kabul şansı', '%${v.chance}'),
          if (v.blockers.isNotEmpty) text(v.blockers.join('\n'), caption: true),
          button(
            v.current ? 'Şu anki mesleğin' : 'Başvur',
            !s.isGameOver && v.canApply
                ? () => result(game.applyCareer(v.career.id))
                : null,
          ),
        ]),
    ];
  }

  List<Widget> budget() {
    final lines = rules.budget(s);
    return [
      for (final l in lines) info(l.$1, formatMoney(l.$2)),
      const Divider(),
      info('Aylık net', formatMoney(lines.fold(0, (v, l) => v + l.$2))),
      text(
        'Bütçe zaman ilerledikçe aylık işlenir. Banka bakiyesi otomatik harcanmaz; faturalar için yeterli nakit bırak.',
        caption: true,
      ),
    ];
  }

  List<Widget> profile() => [
    Text(s.playerName, style: VitaType.title(context.vita)),
    const SizedBox(height: 12),
    Center(
      child: PersonMedallion(
        name: s.playerName,
        female: s.profile.gender == 'Kadın',
        size: 96,
      ),
    ),
    const SizedBox(height: 12),
    card('KİMLİĞİN', [
      info('Yaş', s.ageText),
      info('Doğum yeri', s.profile.birthplace),
      info('Doğum günü', s.profile.birthdayText),
      info('Cinsiyet', s.profile.gender),
      info('Mizaç', s.profile.personality),
      info('Hayalin', s.profile.dream),
      info('Aile', s.profile.family),
      info(
        'Köken',
        game.session.familyOf(s)?.name ?? wealthDisplay(s.profile.wealth),
      ),
      info(
        'İlişki',
        s.flags.contains('married')
            ? 'Evli'
            : s.simulation.wedding.pending
            ? 'Nişanlı · Tören hazırlığı'
            : s.flags.contains('dating')
            ? 'Biriyle görüşüyor'
            : 'Yalnız',
      ),
      info(
        'Sahip oldukların',
        [
          if (s.flags.contains('owns_house')) 'Ev',
          if (s.flags.contains('owns_car')) 'Araba',
          if (s.flags.contains('pet_owner')) 'Evcil dost',
        ].join(' · '),
      ),
    ]),
    card('DURUMUN', [
      info('Meslek', game.session.describeOccupation()),
      info('Para', formatMoney(s.money)),
      StatBar(label: 'Sağlık', value: s.health, color: context.vita.health),
      StatBar(
        label: 'Mutluluk',
        value: s.happiness,
        color: context.vita.happiness,
      ),
      StatBar(
        label: 'Eğitim',
        value: s.education,
        color: context.vita.education,
      ),
      StatBar(label: 'Sosyal', value: s.social, color: context.vita.social),
      info('Görünüm', '${s.appearance}'),
      info('Takipçi', '${s.followers}'),
    ]),
    card('HAYAT HİKÂYEN', [
      text(
        lifeStory(
          s,
          game.session.describeOccupation(),
          origin: game.session.familyOf(s),
        ),
      ),
    ]),
    card('BU DÖNEMDE ÖNCELİĞİN', [
      text(
        'Önceliğin karşılaşacağın olayları etkiler. 90 günde bir değiştirebilirsin.',
        caption: true,
      ),
      if (s.day - s.focusChangedDay < 90)
        text(
          '${90 - (s.day - s.focusChangedDay)} gün sonra yeniden değiştirebilirsin.',
          caption: true,
        ),
      for (final focus in lifeFocuses)
        button(
          '${s.lifeFocus == focus ? '✓ ' : ''}$focus',
          !s.isGameOver &&
                  s.day - s.focusChangedDay >= 90 &&
                  s.lifeFocus != focus
              ? () => result(game.setFocus(focus))
              : null,
        ),
    ]),
    MenuRow(
      icon: Icons.local_activity_outlined,
      title: 'Aktiviteler',
      caption: 'Bu yıl ${Social.remaining(s)} / 12 hak',
      onTap: () => go('activities'),
    ),
    MenuRow(
      icon: Icons.history,
      title: 'Yaşam günlüğü',
      caption: '${s.journal.length} anı birikti',
      onTap: () => go('journal'),
    ),
    MenuRow(
      icon: Icons.menu,
      title: 'Menü ve ayarlar',
      onTap: () => go('menu'),
    ),
  ];
  List<Widget> relationships() => [
    Text('Hayatındaki insanlar', style: VitaType.title(context.vita)),
    const SizedBox(height: 8),
    text(
      'Bağlarını birlikte geçirdiğin zaman güçlendirir. Bu yıl ${Social.remaining(s)} / 12 etkinlik hakkın var.',
      caption: true,
    ),
    const SizedBox(height: 14),
    for (final p in s.relationships)
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: VitaCard(
          onTap: () => go('person:${p.id}'),
          child: Row(
            children: [
              PersonMedallion(
                name: p.name,
                female: p.gender == 'Kadın',
                alive: p.alive,
                grandparent: p.role == 'Büyükanne',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name, style: VitaType.cardTitle(context.vita)),
                    text(
                      '${p.role} · ${p.alive ? '${p.ageNow(s)} yaş' : 'Anısı yaşıyor'}',
                      caption: true,
                    ),
                    StatBar(
                      label: 'Bağınız',
                      value: p.bond,
                      color: context.vita.social,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    button(
      'Yeni biriyle tanış',
      Social.blocked(s, Social.activities.firstWhere((a) => a.id == 'meet')) ==
              null
          ? () => result(game.doAction('meet'))
          : null,
    ),
    if (Social.blocked(s, Social.activities.firstWhere((a) => a.id == 'meet'))
        case final reason?)
      text(reason, caption: true),
  ];
  List<Widget> person() {
    final p = s.relationships.where((p) => p.id == widget.personId).firstOrNull;
    if (p == null) return [text('Kişi bulunamadı.')];
    return [
      Center(
        child: PersonMedallion(
          name: p.name,
          female: p.gender == 'Kadın',
          alive: p.alive,
          grandparent: p.role == 'Büyükanne',
          size: 96,
        ),
      ),
      const SizedBox(height: 14),
      Text(p.name, style: VitaType.title(context.vita)),
      card(p.role, [
        info('Yaş', '${p.ageNow(s)}'),
        info('Şehir', p.city),
        info('Meslek', p.occupation),
        info('Eğitim', p.education),
        info('Kişilik', p.personality),
        StatBar(label: 'Bağınız', value: p.bond, color: context.vita.social),
        StatBar(label: 'Sağlık', value: p.health, color: context.vita.health),
      ]),
      text('Bu yıl ${Social.remaining(s)} / 12 hak', caption: true),
      for (final a in Social.interactions) actionCard(a, p),
    ];
  }

  Widget actionCard(LifeAction a, [RelationshipPerson? p]) {
    final reason = Social.blocked(s, a, p);
    return card('${a.icon} ${a.title}', [
      text(a.description, caption: true),
      if (reason != null) text(reason, caption: true),
      button(
        a.title,
        reason != null
            ? null
            : () async {
                if (['car', 'house', 'pet', 'breakup'].contains(a.id)) {
                  if (!await confirm(a.title, a.description)) return;
                  if (!mounted) return;
                }
                result(game.doAction(a.id, personId: p?.id));
              },
      ),
    ]);
  }

  List<Widget> activities() => [
    Text('Bugün ne yapmak istersin?', style: VitaType.title(context.vita)),
    const SizedBox(height: 8),
    VitaChip('${s.ageText} · BU YIL ${Social.remaining(s)} / 12 HAK'),
    const SizedBox(height: 12),
    text(
      'Her etkinlik bir hak kullanır. Aynı etkinlik için 30 gün beklenir; doğum gününde 12 hak yenilenir.',
      caption: true,
    ),
    for (final category
        in Social.activities.map((a) => a.category).toSet()) ...[
      SectionHeader(category),
      for (final a in Social.activities.where((a) => a.category == category))
        actionCard(a),
    ],
    const SectionHeader('Mini oyunlar'),
    for (final (id, title) in [
      ('memory', 'Yüz–isim eşleştirme'),
      ('balls', 'Toplar ve kutular'),
    ])
      card(title, [
        text(
          'Bir oyun bir etkinlik hakkı kullanır. Ödül tamamlanan 5 turun sonunda verilir. Erken çıkarsan ödül alamazsın.',
          caption: true,
        ),
        if (Social.blocked(s, const LifeAction('minigame', '', '', '', '', 3))
            case final reason?)
          text(reason, caption: true),
        button(
          'Oyna · $title',
          Social.blocked(s, const LifeAction('minigame', '', '', '', '', 3)) ==
                  null
              ? () async {
                  final r = game.startMiniGame(id);
                  if (!r.success) {
                    result(r);
                    return;
                  }
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MiniGameScreen(
                        game: game,
                        kind: id,
                        token: r.message,
                      ),
                    ),
                  );
                  if (mounted) setState(() {});
                }
              : null,
        ),
      ]),
  ];
  List<Widget> menu() => [
    Text("Senin Vita'n", style: VitaType.title(context.vita)),
    MenuRow(
      icon: Icons.auto_stories_outlined,
      title: 'Hikâyeye dön',
      caption: 'Seni bekleyen kararı gör',
      onTap: () => go('story'),
    ),
    MenuRow(
      icon: Icons.local_activity_outlined,
      title: 'Aktiviteler',
      caption: 'Hobiler, alışveriş ve mini oyunlar',
      onTap: () => go('activities'),
    ),
    MenuRow(
      icon: Icons.history,
      title: 'Hayat günlüğü',
      caption: 'Doğumundan bugüne bütün anıların',
      onTap: () => go('journal'),
    ),
    MenuRow(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Finans & banka',
      caption: 'Nakit, birikim ve aylık bütçe',
      onTap: () => go('finance'),
    ),
    MenuRow(
      icon: Icons.public,
      title: 'Ülke & gündelik hayat',
      caption: 'Seçimler, hayat pahalılığı ve iş koşulları',
      onTap: () => go('world'),
    ),
    MenuRow(
      icon: Icons.favorite_outline,
      title: 'Hayatının izleri',
      caption: 'Kararların, aile ve evlilik hazırlığın',
      onTap: () => go('life'),
    ),
    MenuRow(
      icon: Icons.library_books_outlined,
      title: 'Hikâye kütüphanesi',
      caption: 'Başka bir hayat, başka bir ihtimal',
      onTap: () => openStoryLibrary(context, game),
    ),
    MenuRow(
      icon: Icons.home_outlined,
      title: 'Ana menüye dön',
      caption: 'Hayatını kaydet ve açılış ekranına dön',
      onTap: () async {
        if (await confirm(
          'Ana menüye dön?',
          'Hayatın kaydedilecek. Kaldığın yerden devam edebilir veya yeni bir hayat başlatabilirsin.',
        )) {
          if (mounted) game.leaveToTitle();
        }
      },
    ),
    MenuRow(
      icon: Icons.workspace_premium_outlined,
      title: 'Rozetler',
      caption:
          '${game.session.achievements.unlockedCount} / ${game.session.achievements.definitions.length} başarım açıldı',
      onTap: () => openAchievements(context, game),
    ),
    const SectionHeader('Bir mola'),
    text(
      'Bu hayatta ${game.session.breathsRemaining} / 3 nefes hakkın var. İsteğe bağlı reklamı tamamla: +6 mutluluk.',
      caption: true,
    ),
    button(
      game.rewardBusy
          ? 'Reklam bekleniyor…'
          : game.retryBreathAvailable
          ? 'Nefes ödülünü kaydet'
          : 'Derin bir nefes · bir reklam',
      !game.rewardBusy &&
              !s.isGameOver &&
              game.session.breathsRemaining > 0 &&
              (game.ads.rewardedAvailable || game.retryBreathAvailable)
          ? () async {
              final r = await game.rewardedBreath();
              if (mounted) result(r);
            }
          : null,
    ),
    text(game.ads.status, caption: true),
    if (!game.ads.rewardedAvailable && !game.retryBreathAvailable)
      button('Reklamı yeniden dene', game.rewardBusy ? null : game.refreshAds),
    const SectionHeader('Mağaza'),
    text(game.storyStore.status, caption: true),
    if (game.storyStore.notice.isNotEmpty) text(game.storyStore.notice),
    button(
      game.storyStore.adsRemoved
          ? 'Reklamlar kapalı'
          : game.storyStore.price('remove_ads').isEmpty
          ? 'Reklamları kaldır · mağaza hazır değil'
          : "Reklamları kaldır · ${game.storyStore.price('remove_ads')}",
      game.storyStore.canPurchase('remove_ads')
          ? () => result(game.purchaseStory('remove_ads'))
          : null,
    ),
    text(
      'Reklamları kaldırmak ara reklamları kapatır. Ödüllü reklamlar isteğe bağlı kalır.',
      caption: true,
    ),
    button(
      'Satın alımları geri yükle',
      game.storyStore.busy ? null : () => result(game.restoreStories()),
    ),
    MenuRow(
      icon: Icons.privacy_tip_outlined,
      title: 'Gizlilik ve bağlantılar',
      onTap: () => openPrivacy(context),
    ),
    if (game.ads.privacyOptionsRequired)
      button('Reklam gizlilik seçenekleri', game.showAdPrivacyOptions),
    const SectionHeader('Ayarlar'),
    for (final (key, title, value) in [
      ('sound', 'Dokunma sesleri', preferences.sound),
      ('haptics', 'Titreşim', preferences.haptics),
      ('motion', 'Animasyonlar', preferences.motion),
      ('dark', 'Karanlık tema', preferences.dark),
    ])
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: text(title),
        value: value,
        onChanged: (v) {
          preferences.set(key, v);
          setState(() {});
        },
      ),
    card('VITA · HAYAT SİMÜLASYONU', [
      text(
        'Seçimlerin, ilişkilerin ve hikâyelerin bu cihazda saklanır. Oyun temposu: ${s.profile.detailedLife ? 'Uzun hayat' : 'Klasik'}.',
        caption: true,
      ),
    ]),
  ];
  List<Widget> finance() {
    final assets =
        (s.flags.contains('owns_house') ? 2500000 : 0) +
        (s.flags.contains('owns_car') ? 600000 : 0);
    return [
      Text('Finans', style: VitaType.title(context.vita)),
      const SizedBox(height: 14),
      card('BİRİKİMİN', [
        info('Nakit', formatMoney(s.money)),
        info('Banka', formatMoney(s.bankBalance)),
        info('Takı cüzdanı', '${s.simulation.goldWallet} oyun altını'),
        info('Varlık alış bedeli', formatMoney(assets)),
        info('Net değer', formatMoney(s.money + s.bankBalance + assets)),
      ]),
      card('AYLIK NAKİT AKIŞI', budget()),
      if (s.simulation.goldWallet > 0)
        card('TAKI CÜZDANI', [
          text(
            '1 oyun altını = ${formatMoney(Wedding.goldValue(s))}. Bu kur gerçek altın fiyatını temsil etmez.',
            caption: true,
          ),
          button('1 oyun altınını nakde çevir', () => result(game.sellGold(1))),
        ]),
      MenuRow(
        icon: Icons.account_balance_outlined,
        title: 'Banka hesabı',
        caption: s.age < 18
            ? '18 yaşında açılır.'
            : 'Para yatır veya çek · faizsiz birikim',
        onTap: () => go('bank'),
      ),
    ];
  }

  List<Widget> bank() => [
    Text('Banka hesabın', style: VitaType.title(context.vita)),
    const SizedBox(height: 10),
    text(
      'Birikimlerini nakitten ayrı tut. Bu hesap faiz getirmez.',
      caption: true,
    ),
    card('BAKİYEN', [
      info('Nakit', formatMoney(s.money)),
      info('Banka', formatMoney(s.bankBalance)),
    ]),
    TextField(
      controller: _amount,
      decoration: const InputDecoration(labelText: 'İşlem tutarı (₺)'),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    ),
    if (s.age < 18) text('Banka hesabı 18 yaşında açılır.', caption: true),
    button(
      'Bankaya yatır',
      s.age < 18 || s.isGameOver
          ? null
          : () => result(
              game.transferBank(int.tryParse(_amount.text) ?? 0, deposit: true),
            ),
    ),
    button(
      'Nakit çek',
      s.age < 18 || s.isGameOver
          ? null
          : () => result(
              game.transferBank(
                int.tryParse(_amount.text) ?? 0,
                deposit: false,
              ),
            ),
    ),
  ];
  List<Widget> world() {
    final w = s.simulation;
    return [
      VitaChip('${w.year(s)} · KURGUSAL ÜLKE'),
      const SizedBox(height: 10),
      Text(w.country, style: VitaType.title(context.vita)),
      const SizedBox(height: 10),
      text(
        'Seçimler ve ülke koşulları bu hayatın arka planını değiştirir. Gerçek parti, seçim tahmini veya ekonomik öngörü değildir.',
        caption: true,
      ),
      const SizedBox(height: 14),
      card('YAŞADIĞIN DÖNEM', [
        info('Yönetim programı', w.government),
        info('Yaşam maliyeti', 'Başlangıca göre %${w.costIndex - 100}'),
        StatBar(
          label: 'İş olanakları',
          value: w.employment,
          color: context.vita.education,
        ),
        StatBar(
          label: 'Kamu hizmetleri',
          value: w.publicServices,
          color: context.vita.social,
        ),
        StatBar(
          label: 'Gerilim',
          value: w.socialTension,
          color: context.vita.health,
        ),
        if (World.electionOpen(s)) ...[
          text(
            s.age < 18
                ? 'Seçim dönemi sürüyor; oy verme yaşı oyunda 18.'
                : w.lastVotedElection == w.electionNumber
                ? 'Bu seçim dönemindeki tercihin kaydedildi. Sonucu diğer seçmenler belirleyecek.'
                : 'Oy verme kararın hikâyende seni bekliyor. Bekleyen sahneni tamamlayınca sandığa gidebilirsin.',
          ),
          button('Hikâyeme dön', () => go('story')),
        ] else
          text(
            'Bir sonraki kurgusal seçim yılı: ${w.birthYear + (s.age ~/ 5 + 1) * 5}.',
            caption: true,
          ),
      ]),
      for (final e in w.elections.reversed.take(5))
        card('${e.year} SEÇİMİ', [
          text('Yeni yönetim: ${e.winner}'),
          text('Senin tercihin: ${e.vote}', caption: true),
        ]),
    ];
  }

  List<Widget> journal() => [
    Text(
      '${s.playerName} · Hayat günlüğü',
      style: VitaType.title(context.vita),
    ),
    const SizedBox(height: 14),
    card('HİKÂYENİN BAŞLANGICI', [
      text(
        '${s.profile.birthplace} şehrinde, ${s.profile.birthdayText} günü doğdun. ${s.profile.personality} birisin. ${s.profile.dream}.',
      ),
    ]),
    for (final e in s.journal.reversed.take(_memories))
      card('${e.age} yaş · ${e.title}', [
        if (e.choice.isNotEmpty) text(e.choice, caption: true),
        text(e.memory),
      ]),
    if (s.journal.length > _memories)
      button('Daha eski anılar', () => setState(() => _memories += 20)),
  ];
  List<Widget> life() {
    final w = s.simulation.wedding;
    return [
      Text('Hayatının izleri', style: VitaType.title(context.vita)),
      const SizedBox(height: 14),
      card('KARARLARININ BİRİKİMİ', [
        for (final e in qualityNames.entries)
          StatBar(
            label: e.value,
            value: s.simulation.qualities[e.key] ?? 50,
            color: context.vita.social,
          ),
        if (s.simulation.lastDecisionEcho.isNotEmpty)
          text(s.simulation.lastDecisionEcho, caption: true),
      ]),
      if (w.pending)
        card('EVLİLİK HAZIRLIĞIN', [
          text(
            'Teklifiniz bir başlangıçtı. Şimdi törenin nasıl olacağını ve ödeyebileceğiniz bütçeyi seçmeniz gerekiyor. Takı geliri garanti değildir.',
          ),
          button('Hikâyemde planla', () => go('story')),
        ]),
      if (w.day >= 0)
        card('BİRLİKTE BAŞLADIĞINIZ GÜN', [
          info('Tören', w.ceremony),
          info('Masraf', formatMoney(w.cost)),
          info('Nakit takı', formatMoney(w.cashGifts)),
          info('Gelen oyun altını', '${w.goldUnits}'),
          for (final g in w.contributors) text(g, caption: true),
          if (w.contributors.isEmpty)
            text('Bu törene para veya altın takılmadı.', caption: true),
        ]),
    ];
  }
}
