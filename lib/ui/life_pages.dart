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
  int _relTab = 0;
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
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 2, child: text(label, caption: true)),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: Text(value, textAlign: TextAlign.end, style: VitaType.body(context.vita)),
        ),
      ],
    ),
  );
  Widget card(String title, List<Widget> children) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: LifeSimulationCard(
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
      'profile' || 'menu' => profile(),
      'activities' => relationships(showActivities: true),
      'finance' => finance(),
      'bank' => bank(),
      'world' => world(),
      'journal' => journal(),
      'life' => life(),
      _ => profile(),
    };
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 128),
      children: [
        if (![
          'career',
          'relationships',
          'activities',
        ].contains(widget.page))
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => go(switch (widget.page) {
                'person' => 'relationships',
                'bank' => 'finance',
                'profile' || 'menu' => 'story',
                _ => 'profile',
              }),
              icon: const Icon(Icons.chevron_left),
              label: Text(switch (widget.page) {
                'person' => 'İlişkiler',
                'bank' => 'Finans',
                'profile' || 'menu' => 'Hikâye',
                _ => 'Profil',
              }),
            ),
          ),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Semantics(
              liveRegion: true,
              child: LifeSimulationCard(child: text(_message)),
            ),
          ),
        ...children,
      ],
    );
  }

  List<Widget> career() {
    final p = context.vita;
    final c = game.session.content.careers[s.careerId];
    final goals = game.session.content.goals.where((g) => s.activeGoalIds.contains(g.id)).toList();
    final done = goals.where((g) => s.completedGoalIds.contains(g.id)).length;
    final jobs = (_allJobs ? rules.views(s) : rules.openings(s))
        .where((v) => lowerInvariant('${v.career.name} ${v.career.theme}').contains(lowerInvariant(_query)))
        .toList();
    final lines = rules.budget(s);
    final net = lines.fold(0, (v, l) => v + l.$2);
    return [
      // Kahraman kart: şu anki iş ya da okul, basamak ilerlemesi.
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.education.withValues(alpha: p.isDark ? .22 : .14), p.surface],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: p.education.withValues(alpha: .2), borderRadius: BorderRadius.circular(14)),
              child: Icon(c != null ? Icons.work : s.studyLevel != null ? Icons.school : Icons.explore_outlined, color: p.education),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(upperTr(c != null ? 'Şu anki işin' : s.studyLevel != null ? 'Öğrenimin' : 'Yolun'), style: VitaType.overline(p)),
                Text(game.session.describeOccupation(), style: VitaType.title(p).copyWith(fontSize: 21)),
                if (c != null) Text(c.theme, style: VitaType.caption(p)),
              ]),
            ),
          ]),
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: [
            VitaChip(educationDisplay(s.educationLevel), icon: Icons.school_outlined),
            if (c != null) VitaChip('${formatMoney(rules.salary(s))} / ay', icon: Icons.payments_outlined),
            if (s.studyLevel != null)
              VitaChip('${educationDisplay(s.studyLevel!)} · ${s.age - s.studyStartAge + 1}. yıl', icon: Icons.menu_book_outlined),
          ]),
          if (c != null) ...[
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: Text('Kariyer basamağı', style: VitaType.caption(p))),
              Text('${s.careerLevel} / ${c.levels.length}', style: VitaType.caption(p).copyWith(color: p.ink)),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: s.careerLevel / c.levels.length,
                minHeight: 8,
                color: p.education,
                backgroundColor: p.surfaceSunken,
              ),
            ),
            if (s.careerLevel < c.levels.length) ...[
              const SizedBox(height: 6),
              Text('Sıradaki: ${c.levels[s.careerLevel]}', style: VitaType.caption(p)),
            ],
          ] else ...[
            const SizedBox(height: 12),
            text(
              s.age < 16
                  ? 'Çalışmak için henüz çok küçüksün. Şimdilik okul ve oyun zamanı.'
                  : s.studyLevel != null
                  ? 'Okuyorsun. Mezun olunca daha çok kapı açılır; yine de ilanlara bakabilirsin.'
                  : 'Şu an çalışmıyorsun. Aşağıdaki ilanlara başvurabilir ya da kaderine güvenebilirsin.',
              caption: true,
            ),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      AppTileGrid(children: [
        AppTile(
          icon: Icons.flag_outlined,
          title: 'Hedefler',
          caption: '$done / ${goals.length} tamamlandı',
          color: p.happiness,
        ),
        AppTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Aylık net',
          caption: '${formatMoney(net)} · ayrıntı için dokun',
          color: net >= 0 ? p.positive : p.negative,
          onTap: () => go('finance'),
        ),
      ]),
      const SectionHeader('Hayat hedeflerin'),
      LifeSimulationCard(
        child: Column(children: [
          for (final g in goals)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                  s.completedGoalIds.contains(g.id) ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 20,
                  color: s.completedGoalIds.contains(g.id) ? p.positive : p.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g.title, style: VitaType.serif(15.5, p.ink, weight: FontWeight.w500)),
                    Text(g.description, style: VitaType.caption(p)),
                  ]),
                ),
              ]),
            ),
        ]),
      ),
      if (c != null) ...[
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () async {
              if (await confirm(
                'İstifa etmek istiyor musun?',
                'Maaşın kesilecek. Bu işe yeniden başvurmak için 90 gün beklemen gerekecek.',
              )) {
                if (!mounted) return;
                game.quitCareer();
                setState(() => _message = 'İşinden ayrıldın.');
              }
            },
            style: TextButton.styleFrom(foregroundColor: p.negative, minimumSize: const Size(48, 48)),
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('İşinden istifa et'),
          ),
        ),
      ],
      const SectionHeader('İş ilanları'),
      text('İlanlar ${180 - s.day % 180} gün sonra yenilenir. Başvurular zamanı ilerletmez.', caption: true),
      const SizedBox(height: 10),
      AppTile(
        icon: Icons.casino_outlined,
        title: 'Kaderine güven',
        caption: 'Uygun bir işe rastgele, kabul garantili gir',
        color: p.accent,
        onTap: s.isGameOver ? null : () => result(game.trustFate()),
      ),
      const SizedBox(height: 12),
      Wrap(spacing: 8, children: [
        for (final (label, all) in [('Sana uygun', false), ('Tüm meslekler', true)])
          ChoiceChip(
            label: Text(label),
            selected: _allJobs == all,
            onSelected: (_) => setState(() => _allJobs = all),
          ),
      ]),
      const SizedBox(height: 10),
      TextField(
        decoration: InputDecoration(
          hintText: 'Meslek veya alan ara',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: p.surfaceSunken,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
        onChanged: (v) => setState(() => _query = v),
      ),
      const SizedBox(height: 12),
      if (jobs.isEmpty) text('Bu aramayla eşleşen ilan yok.', caption: true),
      for (final v in jobs)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: LifeSimulationCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(v.career.name, style: VitaType.cardTitle(p)),
                    Text(v.career.theme, style: VitaType.caption(p)),
                  ]),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (v.chance >= 60 ? p.positive : v.chance >= 30 ? p.happiness : p.negative).withValues(alpha: .15),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text('%${v.chance}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: v.chance >= 60 ? p.positive : v.chance >= 30 ? p.ink : p.negative,
                      )),
                ),
              ]),
              const SizedBox(height: 8),
              Text(v.career.description, style: VitaType.body(p)),
              const SizedBox(height: 8),
              VitaChip('${formatMoney(salaryAt(v.career, 1))} başlangıç', icon: Icons.payments_outlined),
              if (v.blockers.isNotEmpty) ...[
                const SizedBox(height: 8),
                for (final b in v.blockers)
                  Row(children: [
                    Icon(Icons.lock_outline, size: 14, color: p.muted),
                    const SizedBox(width: 6),
                    Expanded(child: Text(b, style: VitaType.caption(p))),
                  ]),
              ],
              const SizedBox(height: 10),
              VitaButton(
                label: v.current ? 'Şu anki mesleğin' : 'Başvur',
                secondary: !v.canApply,
                onPressed: !s.isGameOver && v.canApply ? () => result(game.applyCareer(v.career.id)) : null,
              ),
            ]),
          ),
        ),
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

  /// Profil: eski Kişisel ve Menü sayfaları bir arada.
  List<Widget> profile() {
    final p = context.vita;
    final ach = game.session.achievements;
    final people = s.relationships.where((r) => r.alive).length;
    final lastMemory = s.journal.isEmpty ? 'Henüz bir anı yok' : s.journal.last.title;
    final focusDays = 90 - (s.day - s.focusChangedDay);
    final focusIcon = switch (s.lifeFocus) {
      'Öğrenme' => Icons.school_outlined,
      'İlişkiler' => Icons.people_outline,
      'Sağlık' => Icons.favorite_outline,
      _ => Icons.balance,
    };
    return [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.border),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [p.accent.withValues(alpha: p.isDark ? .22 : .14), p.surface],
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            PersonMedallion(name: s.playerName, female: s.profile.gender == 'Kadın', size: 66),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.playerName, maxLines: 1, overflow: TextOverflow.ellipsis, style: VitaType.title(p).copyWith(fontSize: 21)),
                const SizedBox(height: 2),
                Text('${s.ageText} · ${game.session.describeOccupation()}',
                    maxLines: 2, overflow: TextOverflow.ellipsis, style: VitaType.caption(p)),
                const SizedBox(height: 6),
                VitaChip(formatMoney(s.money + s.bankBalance), icon: Icons.account_balance_wallet_outlined),
              ]),
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            for (final (label, value, color) in [
              ('Sağlık', s.health, p.health),
              ('Mutluluk', s.happiness, p.happiness),
              ('Eğitim', s.education, p.education),
              ('Sosyal', s.social, p.social),
            ])
              Expanded(child: StatRing(label: label, value: value, color: color)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      LifeSimulationCard(
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: p.accentSoft, borderRadius: BorderRadius.circular(12)),
            child: Icon(focusIcon, color: p.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(upperTr('Bu dönemin önceliği'), style: VitaType.overline(p)),
              Text(s.lifeFocus, style: VitaType.cardTitle(p)),
              Text('Hayat seçti; ${focusDays.clamp(1, 90)} gün sonra yeni bir dönem başlar.', style: VitaType.caption(p)),
            ]),
          ),
        ]),
      ),
      const SectionHeader('Kimliğin'),
      LifeSimulationCard(
        child: Column(children: [
          info('Doğum', '${s.profile.birthdayText} · ${s.profile.birthplace}'),
          info('Cinsiyet', s.profile.gender),
          info('Mizaç', s.profile.personality),
          info('Hayalin', s.profile.dream),
          info('Aile', '${s.profile.family} · ${s.profile.caregiver}'),
          info('Köken', game.session.familyOf(s)?.name ?? wealthDisplay(s.profile.wealth)),
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
          if ([
            if (s.flags.contains('owns_house')) 'Ev',
            if (s.flags.contains('owns_car')) 'Araba',
            if (s.flags.contains('pet_owner')) 'Evcil dost',
          ] case final things when things.isNotEmpty)
            info('Sahip oldukların', things.join(' · ')),
          info('Görünüm · takipçi', '${s.appearance} · ${s.followers}'),
        ]),
      ),
      const SectionHeader('Hayat hikâyen'),
      LifeSimulationCard(
        child: Text(
          lifeStory(s, game.session.describeOccupation(), origin: game.session.familyOf(s)),
          style: VitaType.prose(p).copyWith(fontSize: 16),
        ),
      ),
      const SectionHeader('Hayatın'),
      AppTileGrid(children: [
        AppTile(
          icon: Icons.history_edu,
          title: 'Hayat günlüğü',
          caption: '${s.journal.length} anı · son: $lastMemory',
          color: p.education,
          onTap: () => go('journal'),
        ),
        AppTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Finans & banka',
          caption: 'Nakit ${formatMoney(s.money)} · banka ${formatMoney(s.bankBalance)}',
          color: p.positive,
          onTap: () => go('finance'),
        ),
        AppTile(
          icon: Icons.public,
          title: 'Ülke',
          caption: 'Hayat pahalılığı ${s.simulation.costIndex} · ${s.simulation.country}',
          color: p.social,
          onTap: () => go('world'),
        ),
        AppTile(
          icon: Icons.favorite_outline,
          title: 'Hayatının izleri',
          caption: '$people yakının · ${s.totalChoices} karar',
          color: p.health,
          onTap: () => go('life'),
        ),
        AppTile(
          icon: Icons.workspace_premium_outlined,
          title: 'Rozetler',
          caption: '${ach.unlockedCount} / ${ach.definitions.length} başarım',
          color: p.happiness,
          onTap: () => openAchievements(context, game),
        ),
      ]),
      const SectionHeader('Bir mola'),
      LifeSimulationCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.air, color: p.accent),
            const SizedBox(width: 10),
            Expanded(child: Text('Derin bir nefes', style: VitaType.cardTitle(p))),
            for (var i = 0; i < 3; i++)
              Container(
                width: 10,
                height: 10,
                margin: const EdgeInsets.only(left: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < game.session.breathsRemaining ? p.accent : p.surfaceSunken,
                ),
              ),
          ]),
          const SizedBox(height: 6),
          text('Bu hayatta ${game.session.breathsRemaining} / 3 nefes hakkın var. İsteğe bağlı reklamı tamamla: +6 mutluluk.', caption: true),
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
        ]),
      ),
      const SectionHeader('Mağaza'),
      LifeSimulationCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          text(game.storyStore.status, caption: true),
          if (game.storyStore.notice.isNotEmpty) text(game.storyStore.notice),
          button(
            game.storyStore.adsRemoved
                ? 'Reklamlar kapalı'
                : game.storyStore.price('remove_ads').isEmpty
                ? 'Reklamları kaldır · mağaza hazır değil'
                : "Reklamları kaldır · ${game.storyStore.price('remove_ads')}",
            game.storyStore.canPurchase('remove_ads') ? () => result(game.purchaseStory('remove_ads')) : null,
          ),
          text('Reklamları kaldırmak ara reklamları kapatır. Ödüllü reklamlar isteğe bağlı kalır.', caption: true),
          button('Satın alımları geri yükle', game.storyStore.busy ? null : () => result(game.restoreStories())),
        ]),
      ),
      const SectionHeader('Ayarlar'),
      SettingGroup(children: [
        for (final (key, icon, title, value) in [
          ('sound', Icons.volume_up_outlined, 'Dokunma sesleri', preferences.sound),
          ('haptics', Icons.vibration, 'Titreşim', preferences.haptics),
          ('motion', Icons.animation, 'Animasyonlar', preferences.motion),
          ('dark', Icons.dark_mode_outlined, 'Karanlık tema', preferences.dark),
        ])
          SettingRow(
            icon: icon,
            title: title,
            value: value,
            onChanged: (v) {
              preferences.set(key, v);
              setState(() {});
            },
          ),
      ]),
      const SizedBox(height: 12),
      SettingGroup(children: [
        SettingRow(icon: Icons.privacy_tip_outlined, title: 'Gizlilik ve bağlantılar', onTap: () => openPrivacy(context)),
        if (game.ads.privacyOptionsRequired)
          SettingRow(icon: Icons.ads_click, title: 'Reklam gizlilik seçenekleri', onTap: game.showAdPrivacyOptions),
        SettingRow(
          icon: Icons.home_outlined,
          title: 'Açılış ekranına dön',
          caption: 'Hayatın kaydedilir',
          onTap: () async {
            if (await confirm(
              'Açılış ekranına dön?',
              'Hayatın kaydedilecek. Kaldığın yerden devam edebilir veya yeni bir hayat başlatabilirsin.',
            )) {
              if (mounted) game.leaveToTitle();
            }
          },
        ),
      ]),
      const SizedBox(height: 14),
      Center(
        child: text(
          'Bütün karakterler, kurumlar ve olaylar kurgusaldır · ${s.profile.detailedLife ? 'Uzun hayat' : 'Klasik'} tempo',
          caption: true,
        ),
      ),
    ];
  }

  /// İlişkiler: insanlar ve birlikte/yalnız yapılan aktiviteler aynı yerde.
  List<Widget> relationships({bool showActivities = false}) {
    final p = context.vita;
    final tab = showActivities ? 1 : _relTab;
    final meet = Social.activities.firstWhere((a) => a.id == 'meet');
    return [
      Row(children: [
        Expanded(child: Text(tab == 0 ? 'Hayatındaki insanlar' : 'Bugün ne yapmak istersin?', style: VitaType.title(p))),
      ]),
      const SizedBox(height: 10),
      SegmentedButton<int>(
        showSelectedIcon: false,
        segments: const [
          ButtonSegment(value: 0, icon: Icon(Icons.people_outline), label: Text('Kişiler')),
          ButtonSegment(value: 1, icon: Icon(Icons.local_activity_outlined), label: Text('Aktiviteler')),
        ],
        selected: {tab},
        onSelectionChanged: (v) => showActivities ? go('relationships') : setState(() => _relTab = v.first),
      ),
      const SizedBox(height: 12),
      LifeSimulationCard(
        child: Row(children: [
          Icon(Icons.event_available_outlined, color: p.accent),
          const SizedBox(width: 10),
          Expanded(child: Text('Bu yıl ${Social.remaining(s)} / 12 etkinlik hakkın var', style: VitaType.body(p))),
          for (var i = 0; i < 12; i++)
            Container(
              width: 4,
              height: 14,
              margin: const EdgeInsets.only(left: 2),
              decoration: BoxDecoration(
                color: i < Social.remaining(s) ? p.accent : p.surfaceSunken,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      if (tab == 0) ...[
        for (final person in s.relationships)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LifeSimulationCard(
              onTap: () => go('person:${person.id}'),
              child: Row(children: [
                PersonMedallion(
                  name: person.name,
                  female: person.gender == 'Kadın',
                  alive: person.alive,
                  grandparent: person.role == 'Büyükanne',
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(person.name, style: VitaType.cardTitle(p)),
                    text('${person.role} · ${person.alive ? '${person.ageNow(s)} yaş' : 'Anısı yaşıyor'}', caption: true),
                    StatBar(label: 'Bağınız', value: person.bond, color: p.social),
                  ]),
                ),
                Icon(Icons.chevron_right, color: p.muted),
              ]),
            ),
          ),
        AppTile(
          icon: Icons.person_add_alt,
          title: 'Yeni biriyle tanış',
          caption: Social.blocked(s, meet) ?? 'Bir etkinlik hakkı kullanır',
          color: p.social,
          onTap: Social.blocked(s, meet) == null ? () => result(game.doAction('meet')) : null,
        ),
      ] else
        ...activities(),
    ];
  }
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
