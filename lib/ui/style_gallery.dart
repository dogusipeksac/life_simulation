import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import 'shell.dart';

/// P0 stil galerisi: bütün tasarım bileşenleri gerçek bir oyun ekranının
/// iskeleti içinde (künye şeridi + yüzen sekme çubuğu) gösterilir.
class StyleGallery extends StatefulWidget {
  const StyleGallery({
    super.key,
    required this.dark,
    required this.motion,
    required this.onDarkChanged,
    required this.onMotionChanged,
  });

  final bool dark;
  final bool motion;
  final ValueChanged<bool> onDarkChanged;
  final ValueChanged<bool> onMotionChanged;

  @override
  State<StyleGallery> createState() => _StyleGalleryState();
}

class _StyleGalleryState extends State<StyleGallery> {
  int _tab = 0;
  int _stage = 2;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: p.groundBottom),
      child: Scaffold(
        backgroundColor: p.background,
        extendBody: true,
        body: Backdrop(
          child: SafeArea(
            bottom: false,
            child: Column(children: [
              const VitaKunye(name: 'Deniz Yılmaz', detail: '32 yaş · İzmir', money: '₺42.150'),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 120),
                  children: [
                    for (final (i, w) in _sections(context).indexed) EnterAnimation(index: i, child: w),
                  ],
                ),
              ),
            ]),
          ),
        ),
        bottomNavigationBar: VitaTabBar(
          index: _tab,
          onSelect: (i) => setState(() => _tab = i),
          onNewAge: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Yeni yaş — P2\'de bağlanacak'), behavior: SnackBarBehavior.floating),
          ),
        ),
      ),
    );
  }

  List<Widget> _sections(BuildContext context) {
    final p = context.vita;
    return [
      const SizedBox(height: 8),
      AtmosphereStrip(stage: _stage, numeral: '${[3, 16, 32, 68][_stage]}'),
      const SizedBox(height: 16),
      Text('BÖLÜM IV · YETİŞKİNLİK', style: VitaType.overline(p)),
      const SizedBox(height: 6),
      Text('Mutfaktaki mektup', style: VitaType.title(p)),
      const SizedBox(height: 10),
      Text(
        'Akşam eve döndüğünde masanın üstünde katlanmış bir zarf duruyor. '
        'Annenin el yazısını hemen tanıyorsun; mürekkep yer yer dağılmış.',
        style: VitaType.prose(p),
      ),
      const SectionHeader('Ne yaparsın?'),
      DecisionCard(index: 0, text: 'Zarfı hemen açıp okursun.', hint: 'Merakın her zaman ağır basar.', onTap: _showResult),
      const SizedBox(height: 10),
      DecisionCard(index: 1, text: 'Annenle yüz yüze konuşmaya gidersin.', cost: '₺250 · yol masrafı', onTap: _showResult),
      const SizedBox(height: 10),
      const DecisionCard(index: 2, text: 'Avukata danışırsın.', lockedReason: 'Önce bir işin olmalı'),
      const SectionHeader('Durum'),
      VitaCard(
        child: Column(children: [
          StatBar(label: 'Sağlık', value: 82, color: p.health),
          StatBar(label: 'Mutluluk', value: 61, color: p.happiness),
          StatBar(label: 'Eğitim', value: 47, color: p.education),
          StatBar(label: 'Sosyal', value: 73, color: p.social),
        ]),
      ),
      const SectionHeader('İlişkiler'),
      SizedBox(
        height: 112,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: const [
            _Person('Ayşe', 'Anne', female: true),
            _Person('Mehmet', 'Baba'),
            _Person('Nermin', 'Büyükanne', female: true, grandparent: true),
            _Person('Can', 'Arkadaş'),
            _Person('Hasan', 'Dede', alive: false, grandparent: true),
          ],
        ),
      ),
      const SectionHeader('Çipler'),
      const Wrap(spacing: 8, runSpacing: 8, children: [
        VitaChip('Meraklı', icon: Icons.auto_awesome),
        VitaChip('Dönem önceliği: Aile'),
        VitaChip('12 aksiyon hakkı'),
      ]),
      const SectionHeader('Menü'),
      VitaCard(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(children: [
          MenuRow(icon: Icons.menu_book_outlined, title: 'Hayat günlüğü', caption: 'Yaşadıkların, yıl yıl', onTap: () {}),
          MenuRow(icon: Icons.account_balance_outlined, title: 'Finans & banka', caption: 'Aylık bütçe, birikim', onTap: () {}),
          MenuRow(icon: Icons.auto_stories_outlined, title: 'Hikâye kütüphanesi', caption: '3 kitap', onTap: () {}),
        ]),
      ),
      const SectionHeader('Ayarlar'),
      VitaCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        child: Column(children: [
          _SwitchRow('Koyu tema', widget.dark, widget.onDarkChanged),
          _SwitchRow('Animasyonlar', widget.motion, widget.onMotionChanged),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Expanded(child: Text('Hayat evresi', style: VitaType.body(p))),
              SegmentedButton<int>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedBackgroundColor: p.accentSoft,
                  selectedForegroundColor: p.accent,
                  foregroundColor: p.muted,
                  side: BorderSide(color: p.border),
                ),
                segments: const [
                  ButtonSegment(value: 0, label: Text('0')),
                  ButtonSegment(value: 1, label: Text('1')),
                  ButtonSegment(value: 2, label: Text('2')),
                  ButtonSegment(value: 3, label: Text('3')),
                ],
                selected: {_stage},
                onSelectionChanged: (s) => setState(() => _stage = s.first),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 20),
      VitaButton(label: 'Hikâyeye devam et', onPressed: _showResult),
      const SizedBox(height: 10),
      VitaButton(label: 'Derin bir nefes al', secondary: true, onPressed: () {}),
    ];
  }

  void _showResult() {
    final p = context.vita;
    showVitaSheet<void>(
      context,
      title: 'Sonuç',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Satırları okudukça içinde bir şeyin yumuşadığını hissediyorsun.', style: VitaType.prose(p)),
        const SizedBox(height: 14),
        const Wrap(spacing: 14, runSpacing: 6, children: [
          StatDelta(label: 'Mutluluk', delta: 6),
          StatDelta(label: 'Sosyal', delta: 3),
          StatDelta(label: 'Para', delta: -250),
        ]),
        const SizedBox(height: 14),
        Text('3 hafta geçti · +₺18.400 gelir · −₺12.900 gider', style: VitaType.caption(p)),
        const SizedBox(height: 18),
        VitaButton(label: 'Hikâyeye devam et', onPressed: () => Navigator.pop(context)),
      ]),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person(this.name, this.role, {this.female = false, this.alive = true, this.grandparent = false});
  final String name, role;
  final bool female, alive, grandparent;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return SizedBox(
      width: 78,
      child: Column(children: [
        PersonMedallion(name: name, female: female, alive: alive, grandparent: grandparent, size: 60),
        const SizedBox(height: 6),
        Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: VitaType.serif(13.5, p.ink)),
        Text(role, maxLines: 1, overflow: TextOverflow.ellipsis, style: VitaType.caption(p).copyWith(fontSize: 11)),
      ]),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow(this.label, this.value, this.onChanged);
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => MergeSemantics(
        child: SizedBox(
          height: 52,
          child: Row(children: [
            Expanded(child: Text(label, style: VitaType.body(context.vita))),
            Switch(value: value, onChanged: onChanged),
          ]),
        ),
      );
}
