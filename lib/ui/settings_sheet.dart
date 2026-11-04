import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/components.dart';
import '../design/palette.dart';
import '../design/preferences.dart';
import '../design/theme.dart';
import '../game/features.dart';
import 'game_controller.dart';
import 'intro_screen.dart';
import 'privacy_screen.dart';

abstract final class StoreAppUrls {
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.dogusipeksac.lifesimulation';
  static const appStoreUrl =
      'https://apps.apple.com/app/id6754897042';
  static const appStoreReviewUrl =
      'https://apps.apple.com/app/id6754897042?action=write-review';
  static const playStoreMarketUrl =
      'market://details?id=com.dogusipeksac.lifesimulation';

  static Future<void> openStoreReview() async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final reviewUri = Uri.parse(appStoreReviewUrl);
        if (await canLaunchUrl(reviewUri)) {
          await launchUrl(reviewUri, mode: LaunchMode.externalApplication);
          return;
        }
        await launchUrl(Uri.parse(appStoreUrl), mode: LaunchMode.externalApplication);
        return;
      }
      final marketUri = Uri.parse(playStoreMarketUrl);
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android && await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
        return;
      }
      await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
    } catch (_) {
      // Ignored
    }
  }

  static Future<void> shareApp(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box == null
          ? null
          : box.localToGlobal(Offset.zero) & box.size;

      final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
      final storeLink = isIos ? appStoreUrl : playStoreUrl;

      const message =
          'Hayat Simülasyonu — Kendi hayat hikâyeni yaz, kararlarını ver ve geleceğini şekillendir!\n\nSen de hemen oyna:\n';

      await SharePlus.instance.share(
        ShareParams(
          text: '$message$storeLink',
          subject: 'Hayat Simülasyonu',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );
    } catch (_) {
      // Ignored
    }
  }
}

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({
    super.key,
    required this.game,
    required this.preferences,
    this.onChanged,
  });

  final GameController game;
  final VitaPreferences preferences;
  final VoidCallback? onChanged;

  static Future<void> show(
    BuildContext context, {
    required GameController game,
    required VitaPreferences preferences,
    VoidCallback? onChanged,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SettingsSheet(
        game: game,
        preferences: preferences,
        onChanged: onChanged,
      ),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  GameController get game => widget.game;
  VitaPreferences get preferences => widget.preferences;

  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxSheetHeight),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: p.border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: p.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ayarlar', style: VitaType.title(p).copyWith(fontSize: 20)),
                        Text('Oyun tercihleri ve topluluk', style: VitaType.caption(p)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Kapat',
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: p.ink),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                shrinkWrap: true,
                children: [
                  const SectionHeader('Tercihler'),
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
                          widget.onChanged?.call();
                          setState(() {});
                        },
                      ),
                  ]),
                  const SizedBox(height: 16),
                  const SectionHeader('Uygulama & Topluluk'),
                  SettingGroup(children: [
                    SettingRow(
                      icon: Icons.star_rate_rounded,
                      title: 'Bizi Değerlendir',
                      caption: 'Uygulamaya puan vererek bize destek ol',
                      onTap: StoreAppUrls.openStoreReview,
                    ),
                    SettingRow(
                      icon: Icons.share_rounded,
                      title: 'Arkadaşlarınla Paylaş',
                      caption: 'Hayat Simülasyonu\'nu arkadaşlarına tavsiye et',
                      onTap: () => StoreAppUrls.shareApp(context),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  const SectionHeader('Rehber & Bilgi'),
                  SettingGroup(children: [
                    if (IntroDeck.current.pages.isNotEmpty)
                      SettingRow(
                        icon: Icons.help_outline,
                        title: 'Nasıl oynanır?',
                        onTap: () => openIntro(context),
                      ),
                    SettingRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Gizlilik ve bağlantılar',
                      onTap: () => openPrivacy(context),
                    ),
                    if (!Features.fullAccess && game.ads.privacyOptionsRequired)
                      SettingRow(
                        icon: Icons.ads_click,
                        title: 'Reklam gizlilik seçenekleri',
                        onTap: game.showAdPrivacyOptions,
                      ),
                  ]),
                  const SizedBox(height: 16),
                  const SectionHeader('Oyun'),
                  SettingGroup(children: [
                    SettingRow(
                      icon: Icons.home_outlined,
                      title: 'Açılış ekranına dön',
                      caption: 'Hayatın kaydedilir',
                      onTap: () async {
                        final shouldLeave = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Açılış ekranına dön?'),
                            content: const Text(
                              'Hayatın kaydedilecek. Kaldığın yerden devam edebilir veya yeni bir hayat başlatabilirsin.',
                            ),
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
                        );
                        if (shouldLeave == true && context.mounted) {
                          Navigator.pop(context);
                          game.leaveToTitle();
                        }
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'Hayat Simülasyonu · Bütün karakterler ve olaylar kurgusaldır',
                      textAlign: TextAlign.center,
                      style: VitaType.caption(p).copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
