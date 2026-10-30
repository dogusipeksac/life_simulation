import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';
import '../game/features.dart';

/// Web sitesine koyduğun gizlilik sayfasının adresi (Play / App Store formu için).
const privacyPolicyUrl = String.fromEnvironment(
  'PRIVACY_POLICY_URL',
  defaultValue: '',
);

void openPrivacy(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()));

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final p = context.vita;
    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(title: const Text('Gizlilik ve bağlantılar')),
      body: Backdrop(
        child: SafeArea(
          top: false,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Text('Hayatın bu cihazda', style: VitaType.title(p)),
              const SizedBox(height: 12),
              Text(
                'Hayat kaydın, hikâye ilerlemen, başarımların ve tercihlerin yalnızca bu telefonda durur. Hesap yok, bulut yok. Dosyalar AES-256-GCM ile kilitlenir; anahtar cihazın güvenli deposundadır. Birinin dosyayı kopyalaması düz metin okumaya yetmez.',
                style: VitaType.body(p),
              ),
              const SectionHeader('Şifreleme'),
              Text(
                'Kayıt anahtarı Android Keystore veya iOS Keychain’de üretilir ve oradan çıkmaz. Uygulamayı silersen kayıt ve anahtar da silinir. Kök alınmış cihazlarda işletim sistemi koruması zayıflayabilir.',
                style: VitaType.body(p),
              ),
              if (Features.fullAccess) ...[
                const SectionHeader('Reklamlar ve mağaza'),
                Text(
                  'Bu sürümde reklam ve uygulama içi satın alma kapalıdır. Tüm hikâyelere erişebilirsin; sonraki sürümlerde mağaza ve isteğe bağlı reklamlar açılabilir. Açılırsa Google reklam kimliği işleyebilir; o zaman bu metin güncellenir.',
                  style: VitaType.body(p),
                ),
              ] else ...[
                const SectionHeader('Reklamlar'),
                Text(
                  'Ödüllü reklamlar isteğe bağlıdır. Reklamı tamamlamadan ödül verilmez. Google Mobile Ads cihaz ve reklam kimliği işleyebilir. Gizlilik seçeneklerine oyun menüsünden ulaşabilirsin.',
                  style: VitaType.body(p),
                ),
                const SectionHeader('Satın almalar'),
                Text(
                  'Hikâyeler ve reklamları kaldırma tek seferliktir; abonelik yoktur. Ödeme bilgisi mağazadadır, oyuna gelmez.',
                  style: VitaType.body(p),
                ),
              ],
              if (privacyPolicyUrl.isNotEmpty) ...[
                const SectionHeader('Tam metin'),
                Text(privacyPolicyUrl, style: VitaType.caption(p)),
                VitaButton(
                  label: 'Adresi kopyala',
                  secondary: true,
                  onPressed: () async {
                    await Clipboard.setData(const ClipboardData(text: privacyPolicyUrl));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Gizlilik adresi kopyalandı.')),
                      );
                    }
                  },
                ),
              ],
              const SectionHeader('Lisanslar'),
              VitaButton(
                label: 'Açık kaynak lisansları',
                secondary: true,
                onPressed: () =>
                    showLicensePage(context: context, applicationName: 'Hayat Simülasyonu'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
