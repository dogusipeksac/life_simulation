// İş mülakatı: başvuruda bir genel ve iki meslek sorusu sorulur; cevaplar kabul şansını değiştirir.
import '../content/game_content.dart';
import '../content/models.dart';
import 'state.dart';

/// Verilen bir cevabın sonucu: blöf yakalandıysa puan -1 olur.
class InterviewReply {
  const InterviewReply(this.score, this.text, {this.bluff = false});
  final int score;
  final String text;
  final bool bluff;
}

class Interview {
  Interview(this.career, this.questions);
  final Career career;
  final List<InterviewQuestion> questions;
  final List<InterviewReply> replies = [];

  bool get done => replies.length >= questions.length;
  InterviewQuestion? get current => done ? null : questions[replies.length];
  int get total => replies.fold(0, (v, r) => v + r.score);

  /// Toplam puan kabul şansına eklenir. Çok kötü geçen mülakat doğrudan ret.
  int get bonus => (total * 6).clamp(-30, 30);
  bool get rejected => done && total <= -3;

  String get verdict => switch (total) {
    >= 7 => 'Görüşmeci ayağa kalkıp elini sıkıyor. Çok iyi geçti.',
    >= 4 => 'İyi bir görüşmeydi; seni hatırlayacaklar.',
    >= 1 => 'Fena değildi. Karar başka adaylara da bağlı.',
    >= -2 => 'Görüşme soğuk bitti. Umut az.',
    _ => 'Görüşmeci teşekkür edip kapıyı açıyor. Bu iş olmayacak.',
  };

  InterviewReply answer(GameState s, int index) {
    final a = current!.answers[index];
    final stat = a.stat;
    final reply = stat != null && s.getStat(stat) < a.min
        ? InterviewReply(-1, a.failReply, bluff: true)
        : InterviewReply(a.score, a.reply);
    replies.add(reply);
    return reply;
  }

  /// Sorular hayata, mesleğe ve döneme göre sabit seçilir: aynı dönemde
  /// tekrar açılan mülakat aynı soruları sorar.
  static Interview create(GameContent content, GameState s, Career c) {
    int key(String id) {
      var h = 0xCBF29CE484222325 ^ s.rngSeed ^ (s.day ~/ 90);
      for (final u in '${c.id}/$id'.codeUnits) {
        h = (h ^ u) * 1099511628211;
      }
      return h & 0x7FFFFFFF;
    }

    List<InterviewQuestion> pick(String theme, int n) =>
        (content.interviews.where((q) => q.theme == theme).toList()
              ..sort((a, b) => key(a.id).compareTo(key(b.id))))
            .take(n)
            .toList();
    final themed = pick(c.theme, 2);
    return Interview(c, [...pick('', 3 - themed.length), ...themed]);
  }
}
