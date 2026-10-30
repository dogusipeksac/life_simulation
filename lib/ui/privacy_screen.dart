import 'package:flutter/material.dart';

import '../design/components.dart';
import '../design/illustrations.dart';
import '../design/palette.dart';
import '../design/theme.dart';

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
                'Hayat kaydın, hikâye ilerlemen, başarımların ve tercihlerin bu cihazda saklanır. Hesap veya bulut kayıt sistemi yoktur. Ana oyun ve edinilmiş hikâyeler çevrimdışı kullanılabilir.',
                style: VitaType.body(p),
              ),
              const SectionHeader('Reklamlar'),
              Text(
                'Ödüllü reklamlar isteğe bağlıdır. Reklamı tamamlamadan ödül verilmez; reklam izlemek oyuna devam etmek için zorunlu değildir. Reklam ve gizlilik hizmetleri Google Mobile Ads üzerinden internet bağlantısı kullanır. Bu hizmetler reklam sunumu için cihaz ve bağlantı bilgilerini işleyebilir. Gerekli olduğunda reklam gizlilik seçeneklerine oyun menüsünden ulaşabilirsin.',
                style: VitaType.body(p),
              ),
              if (const bool.fromEnvironment(
                'AD_TEST_MODE',
                defaultValue: true,
              ))
                Text(
                  'Bu geliştirme sürümünde resmi test reklam kimlikleri kullanılır.',
                  style: VitaType.caption(p),
                ),
              const SectionHeader('Satın almalar'),
              Text(
                'Hikâyeler ve reklamları kaldırma ayrı, tek seferlik ürünlerdir; abonelik değildir. Fiyatı ve ödemeyi mağaza gösterir. Ödeme bilgilerini oyun almaz. Cihazda yalnızca doğrulanmış ürün kimlikleri önbelleğe alınır. Farklı bir cihazda aynı mağaza hesabıyla geri yükleme gerekir.',
                style: VitaType.body(p),
              ),
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
