// İçerik modelleri. Alan adları ve varsayılanlar Godot tarafıyla birebir:
// olay/meslek/aile/hedef/başarım/son → tools/build_content.py,
// yaşam sahneleri → Core/LifeScene.cs, hikâye kitapları → Core/StoryBook.cs.
// Saf Dart: Flutter import'u yok.

typedef Json = Map<String, dynamic>;

int _int(Object? v, [int fallback = 0]) => v == null ? fallback : (v as num).toInt();
String _str(Object? v, [String fallback = '']) => v == null ? fallback : v as String;
bool _bool(Object? v) => v == true;
List<String> _strings(Object? v) => v == null ? const [] : List<String>.unmodifiable(v as List);
Map<String, int> _intMap(Object? v) =>
    v == null ? const {} : Map.unmodifiable((v as Map).map((k, x) => MapEntry(k as String, _int(x))));

/// GameEnums.cs ile aynı sıra.
enum Stat { health, happiness, education, social, money }

enum Education { none, primary, highSchool, university, master }

enum Wealth { poor, low, middle, wealthy, rich }

enum EventCategory { childhood, school, career, health, social, random }

/// JSON'daki adı ("HighSchool") enum'a çevirir; bilinmeyen ad için null.
T? enumByName<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  for (final v in values) {
    if (v.name.toLowerCase() == name.toLowerCase()) return v;
  }
  return null;
}

enum ConditionType {
  minStat,
  maxStat,
  hasFlag,
  notHasFlag,
  hasCareer,
  noCareer,
  minEducation,
  minAge,
  maxAge,
  minCareerLevel,
  hadCareer,
  minCompletedGoals,
}

/// "MinStat:Health:40" gibi bir koşulun yükleme anında çözülmüş hâli.
class Condition {
  const Condition(this.type, {this.stat = Stat.health, this.value = 0, this.key = '', required this.source});

  final ConditionType type;
  final Stat stat;
  final int value;
  final String key;
  final String source;

  /// Biçim hatasında [FormatException] fırlatır; mesajlar build_content.py ile aynı.
  factory Condition.parse(String text) {
    final parts = text.split(':');
    final type = enumByName(ConditionType.values, parts[0]);
    if (type == null) throw FormatException("bilinmeyen koşul '$text'");
    FormatException bad(String msg) => FormatException("koşul '$text': $msg");
    switch (type) {
      case ConditionType.minStat || ConditionType.maxStat:
        final stat = parts.length == 3 ? enumByName(Stat.values, parts[1]) : null;
        final value = parts.length == 3 ? int.tryParse(parts[2]) : null;
        if (stat == null || value == null) throw bad("biçim 'MinStat:<Stat>:<sayı>'");
        if (stat != Stat.money && (value < 0 || value > 100)) throw bad('stat eşiği 0–100 olmalı');
        return Condition(type, stat: stat, value: value, source: text);
      case ConditionType.hasFlag || ConditionType.notHasFlag:
        if (parts.length != 2) throw bad("biçim '${parts[0]}:<bayrak>'");
        return Condition(type, key: parts[1], source: text);
      case ConditionType.hasCareer || ConditionType.hadCareer:
        if (parts.length != 2) throw bad("biçim '${parts[0]}:<meslek>'");
        return Condition(type, key: parts[1], source: text);
      case ConditionType.noCareer:
        if (parts.length != 1) throw bad('NoCareer parametre almaz');
        return Condition(type, source: text);
      case ConditionType.minEducation:
        final edu = parts.length == 2 ? enumByName(Education.values, parts[1]) : null;
        if (edu == null) throw bad("biçim 'MinEducation:<None|Primary|HighSchool|University|Master>'");
        return Condition(type, value: edu.index, source: text);
      default:
        final value = parts.length == 2 ? int.tryParse(parts[1]) : null;
        if (value == null) throw bad("biçim '${parts[0]}:<sayı>'");
        return Condition(type, value: value, source: text);
    }
  }

  @override
  String toString() => source;
}

List<Condition> _conditions(Object? v) =>
    v == null ? const [] : List.unmodifiable((v as List).map((c) => Condition.parse(c as String)));

// ---------------------------------------------------------------- Klasik olaylar

class EventChoice {
  EventChoice.fromJson(Json j)
      : raw = j,
        id = _str(j['id']),
        text = _str(j['text']),
        result = _str(j['result']),
        effects = _intMap(j['effects']),
        cost = _int(j['cost']),
        requires = _conditions(j['requires']),
        set = _strings(j['set']),
        remove = _strings(j['remove']),
        next = _str(j['next']);

  final Json raw;
  final String id, text, result, next;
  final Map<String, int> effects;
  final int cost;
  final List<Condition> requires;
  final List<String> set, remove;
}

class GameEvent {
  GameEvent.fromJson(Json j, {required this.file})
      : raw = j,
        id = _str(j['id']),
        title = _str(j['title']),
        categoryName = _str(j['category']),
        description = _str(j['description']),
        minAge = _int(j['minAge']),
        maxAge = _int(j['maxAge'], 100),
        educationName = j['education'] as String?,
        conditions = _conditions(j['conditions']),
        choices = List.unmodifiable((j['choices'] as List? ?? const []).map((c) => EventChoice.fromJson(c as Json))),
        repeatable = _bool(j['repeatable']),
        cooldownDays = _int(j['cooldownDays']),
        weight = _int(j['weight'], 10),
        chainOnly = _bool(j['chainOnly']),
        turnDays = _int(j['turnDays']);

  final Json raw;
  final String file;
  final String id, title, categoryName, description;
  final String? educationName;
  final int minAge, maxAge, cooldownDays, weight, turnDays;
  final List<Condition> conditions;
  final List<EventChoice> choices;
  final bool repeatable, chainOnly;

  EventCategory? get category => enumByName(EventCategory.values, categoryName);
  Education? get requiredEducation => enumByName(Education.values, educationName);
}

// ---------------------------------------------------------------- Yaşam sahneleri

class LifeSceneOption {
  LifeSceneOption.fromJson(Json j)
      : raw = j,
        id = _str(j['Id']),
        text = _str(j['Text']),
        result = _str(j['Result']),
        cost = _int(j['Cost']),
        stats = _intMap(j['Stats']),
        qualities = _intMap(j['Qualities']),
        set = _strings(j['Set']),
        remove = _strings(j['Remove']),
        careerExit = _bool(j['CareerExit']),
        familyBond = _int(j['FamilyBond']),
        partnerBond = _int(j['PartnerBond']),
        next = _str(j['Next']),
        delayDays = _int(j['DelayDays'], 90);

  final Json raw;
  final String id, text, result, next;
  final int cost, familyBond, partnerBond, delayDays;
  final Map<String, int> stats, qualities;
  final List<String> set, remove;
  final bool careerExit;
}

class LifeScene {
  LifeScene.fromJson(Json j)
      : raw = j,
        id = _str(j['Id']),
        title = _str(j['Title']),
        text = _str(j['Text']),
        domain = _str(j['Domain'], 'personal'),
        minAge = _int(j['MinAge']),
        maxAge = _int(j['MaxAge'], 100),
        priority = _int(j['Priority'], 20),
        cooldownDays = _int(j['CooldownDays'], 1095),
        milestone = _bool(j['Milestone']),
        followUpOnly = _bool(j['FollowUpOnly']),
        context = _str(j['Context']),
        needs = _strings(j['Needs']),
        forbids = _strings(j['Forbids']),
        minQualities = _intMap(j['MinQualities']),
        maxQualities = _intMap(j['MaxQualities']),
        choices = List.unmodifiable((j['Choices'] as List? ?? const []).map((c) => LifeSceneOption.fromJson(c as Json)));

  final Json raw;
  final String id, title, text, domain, context;
  final int minAge, maxAge, priority, cooldownDays;
  final bool milestone, followUpOnly;
  final List<String> needs, forbids;
  final Map<String, int> minQualities, maxQualities;
  final List<LifeSceneOption> choices;
}

// ---------------------------------------------------------------- Meslek, aile, katalog

class Career {
  Career.fromJson(Json j)
      : raw = j,
        id = _str(j['id']),
        name = _str(j['name']),
        theme = _str(j['theme']),
        description = _str(j['description']),
        minAge = _int(j['minAge'], 18),
        educationName = _str(j['education'], 'None'),
        minEducationStat = _int(j['minEducationStat']),
        acceptChance = _int(j['acceptChance'], 50),
        salary = _int(j['salary']),
        raise = _int(j['raise']),
        levels = _strings(j['levels']),
        promotionMonths = _int(j['promotionMonths'], 24),
        promotionStatName = _str(j['promotionStat'], 'Education'),
        promotionMinStat = _int(j['promotionMinStat']),
        promotionChance = _int(j['promotionChance'], 10),
        healthPerYear = _int(j['healthPerYear']),
        happinessPerYear = _int(j['happinessPerYear']);

  final Json raw;
  final String id, name, theme, description, educationName, promotionStatName;
  final int minAge, minEducationStat, acceptChance, salary, raise;
  final int promotionMonths, promotionMinStat, promotionChance, healthPerYear, happinessPerYear;
  final List<String> levels;

  Education? get education => enumByName(Education.values, educationName);
  Stat? get promotionStat => enumByName(Stat.values, promotionStatName);
}

class Family {
  Family.fromJson(Json j)
      : raw = j,
        id = _str(j['id']),
        name = _str(j['name']),
        origin = _str(j['origin']),
        tierName = _str(j['tier']),
        description = _str(j['description']);

  final Json raw;
  final String id, name, origin, tierName, description;

  Wealth? get tier => enumByName(Wealth.values, tierName);

  /// Doğumda oyunun koyduğu köken bayrağı (FamilySystem.ApplyBirth).
  String get originFlag => 'origin_$origin';
}

class FlagInfo {
  FlagInfo.fromJson(Json j)
      : raw = j,
        key = _str(j['key']),
        requiredText = _str(j['required']),
        forbiddenText = _str(j['forbidden']),
        system = _bool(j['system']);

  final Json raw;
  final String key, requiredText, forbiddenText;
  final bool system;
}

class Goal {
  Goal.fromJson(Json j)
      : raw = j,
        id = _str(j['id']),
        title = _str(j['title']),
        description = _str(j['description']),
        conditions = _conditions(j['conditions']),
        rewardHappiness = _int(j['reward'], 5);

  final Json raw;
  final String id, title, description;
  final List<Condition> conditions;
  final int rewardHappiness;
}

class Achievement {
  Achievement.fromJson(Json j)
      : raw = j,
        id = _str(j['id']),
        title = _str(j['title']),
        description = _str(j['description']),
        conditions = _conditions(j['conditions']),
        onlyAtGameOver = _bool(j['atGameOver']),
        secret = _bool(j['secret']);

  final Json raw;
  final String id, title, description;
  final List<Condition> conditions;
  final bool onlyAtGameOver, secret;
}

class Ending {
  Ending.fromJson(Json j)
      : raw = j,
        id = _str(j['id']),
        title = _str(j['title']),
        text = _str(j['text']),
        priority = _int(j['priority']),
        conditions = _conditions(j['conditions']);

  final Json raw;
  final String id, title, text;
  final int priority;
  final List<Condition> conditions;
}

class LifeConfig {
  LifeConfig.fromJson(Json j)
      : raw = j,
        declineStartAge = _int(j['declineStartAge'], 35),
        baseYearlyLoss = _int(j['baseYearlyLoss'], 1),
        extraLossEveryYears = _int(j['extraLossEveryYears'], 12),
        recoveryPerYear = _int(j['recoveryPerYear'], 3),
        lowHappinessThreshold = _int(j['lowHappinessThreshold'], 30),
        lowHappinessExtraLoss = _int(j['lowHappinessExtraLoss'], 1),
        flagModifiers = _intMap(j['flagModifiers']);

  final Json raw;
  final int declineStartAge, baseYearlyLoss, extraLossEveryYears, recoveryPerYear;
  final int lowHappinessThreshold, lowHappinessExtraLoss;

  /// bayrak → yıllık sağlık kaybına eklenen değer.
  final Map<String, int> flagModifiers;
}

// ---------------------------------------------------------------- Hikâye kitapları

class StoryOption {
  StoryOption.fromJson(Json j)
      : raw = j,
        text = _str(j['Text']),
        next = _str(j['Next']),
        result = _str(j['Result']),
        needFlag = _str(j['NeedFlag']),
        needStat = _str(j['NeedStat']),
        minValue = _int(j['MinValue']),
        effects = _intMap(j['Effects']),
        setFlags = _strings(j['SetFlags']);

  final Json raw;
  final String text, next, result, needFlag, needStat;
  final int minValue;
  final Map<String, int> effects;
  final List<String> setFlags;
}

class StoryNode {
  StoryNode.fromJson(Json j)
      : raw = j,
        title = _str(j['Title']),
        text = _str(j['Text']),
        chapter = _int(j['Chapter'], 1),
        ending = _str(j['Ending']),
        choices = List.unmodifiable((j['Choices'] as List? ?? const []).map((c) => StoryOption.fromJson(c as Json)));

  final Json raw;
  final String title, text, ending;
  final int chapter;
  final List<StoryOption> choices;
}

class StoryBook {
  StoryBook.fromJson(Json j)
      : raw = j,
        id = _str(j['Id']),
        title = _str(j['Title']),
        subtitle = _str(j['Subtitle']),
        description = _str(j['Description']),
        genre = _str(j['Genre']),
        color = _str(j['Color'], '7960c8'),
        symbol = _str(j['Symbol'], '✦'),
        productId = _str(j['ProductId']),
        start = _str(j['Start'], 'start'),
        freeChapters = _int(j['FreeChapters'], 1),
        contentNote = _str(j['ContentNote']),
        chapters = _strings(j['Chapters']),
        statNames = j['StatNames'] == null
            ? const {}
            : Map.unmodifiable((j['StatNames'] as Map).map((k, v) => MapEntry(k as String, v as String))),
        nodes = Map.unmodifiable(
            (j['Nodes'] as Map? ?? const {}).map((k, v) => MapEntry(k as String, StoryNode.fromJson(v as Json))));

  final Json raw;
  final String id, title, subtitle, description, genre, color, symbol, productId, start, contentNote;
  final int freeChapters;
  final List<String> chapters;
  final Map<String, String> statNames;
  final Map<String, StoryNode> nodes;
}
