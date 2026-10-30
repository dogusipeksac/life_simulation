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
| `memory` | kartları çevir, çiftleri bul | `Items` (3–6 çift), `Attempts` (hata hakkı) | `Success`, `Fail` |
| `budget` | birimleri kalemlere paylaştır | `Total`, `Buckets[{Label, Min}]`, `Hint` | `Success` (hepsi dağıtıldı, alt sınırlar tuttu), `Fail` |
| `hold` | halka dolana kadar basılı tut | `HoldMs` (≥ 600), `Rounds`, `Attempts` (erken bırakma hakkı) | `Success`, `Fail` |
| `quiz` | tek doğru şıklı soru | `Items` (2–4 şık), `AnswerIndex` | `Success`, `Fail` |

`tune` için isteğe bağlı `Unit` (varsayılan `MHz`; ör. `cm/sn`, `%`, `Hz`).

Her türde `Prompt` zorunlu. Ekran okuyucu açıkken süreler durur, `tune` toleransı iki katına,
`timing` bölgesi 1,6 katına çıkar ve hız yarıya iner.

## Ana hayat anları · `assets/content/moments.json`

Bir yaşam sahnesinin (`life_scenes.json`) ya da olayın (`events/*.json`) başına eklenen kısa
etkileşim. Kararlar değişmez: an önce oynanır, sonucu küçük bir etki ve kendi cümlesiyle sahneye
eklenir ("BU ANDA" kartı), sonra her zamanki seçenekler gelir. Her hedefe en fazla bir an.

```json
{"Id": "m_rest", "Target": "lived_rest", "Type": "hold", "Prompt": "…", "HoldMs": 1800, "Rounds": 3, "Attempts": 2,
 "Success": {"Text": "…", "Stats": {"Health": 2}}, "Fail": {"Text": "…", "Stats": {}}}
```

- Bütün türler kullanılabilir. Etkiler stat başına ±4 ile sınırlı; para etkisi yok.
- `search`: en az bir noktada `"Key": true` olmalı; anahtar nokta bulunursa an başarılı.
- `tune`: hedef `Goal` alanıyla verilir (`Target` anın hedef sahnesidir).
- `timer`: `Success`/`Fail` yok; `TimeoutChoice` hedefteki ücretsiz ve koşulsuz bir seçenek olmalı.
- Metinlerde `{caregiver}`, `{mother}`, `{partner}` gibi yer tutucular çalışır.
- “Bu anı geç” her zaman vardır ve başarısız sonucu uygular. Oynanmış an kayda yazılır (kayıt v8).
