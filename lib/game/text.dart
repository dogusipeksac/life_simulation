// Türkçe adlar ve sayı biçimi. (Godot: Core/DisplayNames.cs, Core/TextFormat.cs)

import '../content/models.dart';
import 'state.dart';

String _group(int n) {
  final s = n.toString();
  final b = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write('.');
    b.write(s[i]);
  }
  return b.toString();
}

/// 1234567 → "₺1.234.567"
String formatMoney(int amount) => amount < 0 ? '-₺${_group(-amount)}' : '₺${_group(amount)}';

String statDisplay(Stat s) => const ['Sağlık', 'Mutluluk', 'Eğitim', 'Sosyal', 'Para'][s.index];

String educationDisplay(Education e) =>
    const ['Eğitimsiz', 'İlkokul', 'Lise', 'Üniversite', 'Yüksek lisans'][e.index];

String wealthDisplay(Wealth w) => const ['Yoksul', 'Dar gelirli', 'Orta halli', 'Varlıklı', 'Zengin'][w.index];

String categoryDisplay(EventCategory c) => const ['Çocukluk', 'Okul', 'Kariyer', 'Sağlık', 'Sosyal', 'Hayat'][c.index];

String gameOverDisplay(GameOverReason r) => switch (r) {
      GameOverReason.healthDepleted => 'Sağlığın tükendi.',
      GameOverReason.oldAge => 'Uzun bir ömrün sonunda huzurla gözlerini yumdun.',
    };

/// "+₺500" veya "−5 Sağlık".
String formatChange(StatChange c) {
  final sign = c.applied >= 0 ? '+' : '−';
  final abs = c.applied.abs();
  return c.stat == Stat.money ? '$sign${formatMoney(abs)}' : '$sign$abs ${statDisplay(c.stat)}';
}

/// C# ToLowerInvariant karşılığı: Dart 'İ'yi "i̇" (noktalı iki karakter) yapar, C# 'i' yapar.
String lowerInvariant(String s) => s.replaceAll('İ', 'i').toLowerCase();
