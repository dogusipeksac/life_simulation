# Hikâye kitapları · etkileşimler ve görünümler

Kitaplar `assets/content/stories/*.json`. Bir sahne (`Nodes.<id>`) iki yeni alan alabilir.
Doğrulama `lib/content/content_validator.dart`; her son, `test/story_library_test.dart` ile gerçek
stat/bayrak kurallarıyla ve bütün etkileşim sonuçlarıyla ulaşılabilir olmalı.

## Görünüm · `Style`

| Değer | Görünüm | Metin biçimi |
|---|---|---|
| boş | düz anlatı | serbest |
| `chat` | mesajlaşma balonları | `Ad: mesaj` satırları; `Sen:` sağda; iki nokta içermeyen satır sistem notu |
| `note` | el yazısı not / mektup | serbest |
| `radio` | kayıt / telsiz dökümü | eşit aralıklı yazı |

## Etkileşim · `Interaction`

Sonuçlar sahnenin `Choices` dizinine bağlanır; etkileşim bitince o seçenek uygulanır (kayıt,
etkiler, bayraklar, bölüm kilidi aynen). `timer` dışındaki türlerde seçenekler kart olarak
gösterilmez ve `NeedFlag`/`NeedStat` taşıyamaz; her seçenek bir sonuca bağlı olmalı.

| `Type` | Ne yapar | Alanlar | Sonuçlar |
|---|---|---|---|
| `code` | rakam çarkları | `Answer` (3–6 rakam), `Attempts`, `Hint` (zorunlu) | `Success`, `Fail` |
| `order` | sürükle ya da ↑↓ ile sırala | `Items` (doğru sıra, 3–6), `Attempts` | `Success`, `Fail` |
| `tune` | kaydırıcıyla hedefi bul, `HoldMs` tut | `Min`, `Max`, `Target`, `Tolerance`, `HoldMs`, `Seconds`, `Hint` | `Success`, `Fail` |
| `timing` | hareketli işaret bölgedeyken dokun | `Rounds`, `Need`, `Zone` (0,08–0,5), `Speed` | `Success`, `Fail` |
| `search` | noktalara bak, sınırlı hak | `Spots[{Label, Text, Flag}]`, `Picks` | `Done` (bakılan noktaların bayrakları eklenir) |
| `timer` | seçenek kartları + geri sayım | `Seconds` (≥ 8) | `Timeout` (koşulsuz seçenek) |

Her türde `Prompt` zorunlu. Ekran okuyucu açıkken süreler durur, `tune` toleransı iki katına,
`timing` bölgesi 1,6 katına çıkar ve hız yarıya iner.
