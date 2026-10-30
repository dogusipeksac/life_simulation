// Oyuncunun bütün kalıcı durumu. Godot: Core/GameState.cs, Core/LifeSimulationState.cs,
// Core/CharacterProfile.cs, Core/RelationshipPerson.cs, Systems/SavedMoment.cs, TurnReport.cs.
// Kayıt alan adları C# ile birebir (PascalCase); enum'lar string olarak yazılır.

import '../content/models.dart';

typedef J = Map<String, dynamic>;

int _i(J j, String k, [int fb = 0]) => (j[k] as num?)?.toInt() ?? fb;
String _s(J j, String k, [String fb = '']) => j[k] as String? ?? fb;
bool _b(J j, String k, [bool fb = false]) => j[k] as bool? ?? fb;
List<String> _ls(J j, String k) => [...?(j[k] as List?)?.whereType<String>()];
Map<String, int> _mi(J j, String k) => {...?(j[k] as Map?)?.map((a, b) => MapEntry(a as String, (b as num).toInt()))};
List<T> _lo<T>(J j, String k, T Function(J) f) => [...?(j[k] as List?)?.whereType<Map>().map((e) => f(e.cast()))];
J _o(J j, String k) => (j[k] as Map?)?.cast<String, dynamic>() ?? {};

String statName(Stat s) => const ['Health', 'Happiness', 'Education', 'Social', 'Money'][s.index];
String educationName(Education e) => const ['None', 'Primary', 'HighSchool', 'University', 'Master'][e.index];
String wealthName(Wealth w) => const ['Poor', 'Low', 'Middle', 'Wealthy', 'Rich'][w.index];

enum GameOverReason { healthDepleted, oldAge }

String gameOverName(GameOverReason r) => r == GameOverReason.healthDepleted ? 'HealthDepleted' : 'OldAge';

int _clamp(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);

const lifeFocuses = ['Dengeli', 'Öğrenme', 'İlişkiler', 'Sağlık'];

class CharacterProfile {
  String birthplace = 'İstanbul';
  String family = 'Çekirdek aile';
  String caregiver = 'Ailem';
  String dream = 'Kendi yolumu bulmak';
  String personality = 'Meraklı';
  int skinTone = 1, hairStyle = 0, outfit = 0;
  bool detailedLife = false;
  String gender = 'Belirtilmedi';
  int birthDay = 1, birthMonth = 1;
  String familyId = '';
  Wealth wealth = Wealth.middle;

  static const genders = ['Kadın', 'Erkek', 'Belirtilmedi'];
  static const monthNames = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran', //
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
  ];
  static const _monthDays = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  static int daysInMonth(int month) => _monthDays[_clamp(month, 1, 12) - 1];

  String get birthdayText => '$birthDay ${monthNames[birthMonth - 1]}';

  String get birthSeason => switch (birthMonth) {
        12 || 1 || 2 => 'winter',
        >= 3 && <= 5 => 'spring',
        >= 6 && <= 8 => 'summer',
        _ => 'autumn',
      };

  CharacterProfile();

  CharacterProfile.fromJson(J j) {
    birthplace = _s(j, 'Birthplace', birthplace);
    family = _s(j, 'Family', family);
    caregiver = _s(j, 'Caregiver', caregiver);
    dream = _s(j, 'Dream', dream);
    personality = _s(j, 'Personality', personality);
    skinTone = _i(j, 'SkinTone', 1);
    hairStyle = _i(j, 'HairStyle');
    outfit = _i(j, 'Outfit');
    detailedLife = _b(j, 'DetailedLife');
    gender = _s(j, 'Gender', gender);
    birthDay = _i(j, 'BirthDay', 1);
    birthMonth = _i(j, 'BirthMonth', 1);
    familyId = _s(j, 'FamilyId');
    wealth = enumByName(Wealth.values, j['Wealth'] as String?) ?? Wealth.middle;
  }

  J toJson() => {
        'Birthplace': birthplace, 'Family': family, 'Caregiver': caregiver, 'Dream': dream,
        'Personality': personality, 'SkinTone': skinTone, 'HairStyle': hairStyle, 'Outfit': outfit,
        'DetailedLife': detailedLife, 'Gender': gender, 'BirthDay': birthDay, 'BirthMonth': birthMonth,
        'FamilyId': familyId, 'Wealth': wealthName(wealth),
      };

  void ensureValid() {
    birthplace = _clean(birthplace, 'Belirtilmedi', 32);
    family = _clean(family, 'Ailem', 32);
    caregiver = _clean(caregiver, 'Ailem', 24);
    dream = _clean(dream, 'Kendi yolumu bulmak', 40);
    personality = _clean(personality, 'Meraklı', 24);
    skinTone = _clamp(skinTone, 0, 3);
    hairStyle = _clamp(hairStyle, 0, 2);
    outfit = _clamp(outfit, 0, 3);
    if (!genders.contains(gender)) gender = 'Belirtilmedi';
    birthMonth = _clamp(birthMonth, 1, 12);
    birthDay = _clamp(birthDay, 1, daysInMonth(birthMonth));
  }

  static String _clean(String value, String fallback, int max) {
    final t = value.trim().replaceAll('\n', ' ').replaceAll('\r', ' ');
    return t.isEmpty ? fallback : t.substring(0, t.length < max ? t.length : max);
  }
}

class JournalEntry {
  JournalEntry({this.age = 0, this.day = 0, this.title = '', this.choice = '', this.memory = ''});
  JournalEntry.fromJson(J j)
      : age = _i(j, 'Age'),
        day = _i(j, 'Day'),
        title = _s(j, 'Title'),
        choice = _s(j, 'Choice'),
        memory = _s(j, 'Memory');
  int age, day;
  String title, choice, memory;
  J toJson() => {'Age': age, 'Day': day, 'Title': title, 'Choice': choice, 'Memory': memory};
}

class RelationshipPerson {
  RelationshipPerson({
    this.id = '',
    this.name = '',
    this.role = 'Arkadaş',
    this.gender = 'Belirtilmedi',
    this.city = 'İstanbul',
    this.occupation = 'Çalışan',
    this.education = 'Lise',
    this.personality = 'Sıcakkanlı',
    this.ageAtBirth = 0,
    this.lifespan = 90,
    this.bond = 65,
    this.generosity = 50,
    this.wealth = 50,
    this.health = 80,
    this.alive = true,
  });

  RelationshipPerson.fromJson(J j)
      : id = _s(j, 'Id'),
        name = _s(j, 'Name'),
        role = _s(j, 'Role', 'Arkadaş'),
        gender = _s(j, 'Gender', 'Belirtilmedi'),
        city = _s(j, 'City', 'İstanbul'),
        occupation = _s(j, 'Occupation', 'Çalışan'),
        education = _s(j, 'Education', 'Lise'),
        personality = _s(j, 'Personality', 'Sıcakkanlı'),
        ageAtBirth = _i(j, 'AgeAtBirth'),
        lifespan = _i(j, 'Lifespan', 90),
        bond = _i(j, 'Bond', 65),
        generosity = _i(j, 'Generosity', 50),
        wealth = _i(j, 'Wealth', 50),
        health = _i(j, 'Health', 80),
        alive = _b(j, 'Alive', true);

  String id, name, role, gender, city, occupation, education, personality;
  int ageAtBirth, lifespan, bond, generosity, wealth, health;
  bool alive;

  int ageNow(GameState s) => (ageAtBirth + s.age) < 0 ? 0 : ageAtBirth + s.age;

  bool get isPartner => role == 'Partner' || role == 'Nişanlı' || role == 'Eş';
  bool get isParent => id == 'mother' || id == 'father';

  J toJson() => {
        'Id': id, 'Name': name, 'Role': role, 'Gender': gender, 'City': city, 'Occupation': occupation,
        'Education': education, 'Personality': personality, 'AgeAtBirth': ageAtBirth, 'Lifespan': lifespan,
        'Bond': bond, 'Generosity': generosity, 'Wealth': wealth, 'Health': health, 'Alive': alive,
      };

  void ensureValid() {
    ageAtBirth = _clamp(ageAtBirth, -120, 65);
    lifespan = _clamp(lifespan, 65, 110);
    bond = _clamp(bond, 0, 100);
    generosity = _clamp(generosity, 0, 100);
    wealth = _clamp(wealth, 0, 100);
    health = _clamp(health, 0, 100);
  }
}

/// Seçimin uygulanmış stat değişimi. [applied] sınırlar sonrası gerçek değişim (UI bunu gösterir).
class StatChange {
  const StatChange(this.stat, this.requested, this.applied, this.newValue);
  StatChange.fromJson(J j)
      : stat = enumByName(Stat.values, j['Stat'] as String?) ?? Stat.health,
        requested = _i(j, 'Requested'),
        applied = _i(j, 'Applied'),
        newValue = _i(j, 'NewValue');

  final Stat stat;
  final int requested, applied, newValue;

  J toJson() => {'Stat': statName(stat), 'Requested': requested, 'Applied': applied, 'NewValue': newValue};
}

class TurnReport {
  TurnReport({this.days = 0});
  TurnReport.fromJson(J j)
      : days = _i(j, 'Days'),
        income = _i(j, 'Income'),
        expenses = _i(j, 'Expenses'),
        notes = _ls(j, 'Notes');

  int days;
  int income = 0, expenses = 0;
  List<String> notes = [];
  int get net => income - expenses;

  J toJson() => {'Days': days, 'Income': income, 'Expenses': expenses, 'Notes': notes};
}

/// "Devam et" bekleyen, etkileri zaten uygulanmış an. Yeniden açmak etkileri ikinci kez uygulamaz.
class SavedMoment {
  SavedMoment({this.title = '', this.text = '', List<StatChange>? changes, TurnReport? turn})
      : changes = changes ?? [],
        turn = turn ?? TurnReport();
  SavedMoment.fromJson(J j)
      : title = _s(j, 'Title'),
        text = _s(j, 'Text'),
        changes = _lo(j, 'Changes', StatChange.fromJson),
        turn = TurnReport.fromJson(_o(j, 'Turn'));

  String title, text;
  List<StatChange> changes;
  TurnReport turn;

  J toJson() => {'Title': title, 'Text': text, 'Changes': [for (final c in changes) c.toJson()], 'Turn': turn.toJson()};
}

class CivicRecord {
  CivicRecord.fromJson(J j)
      : election = _i(j, 'Election'),
        year = _i(j, 'Year'),
        vote = _s(j, 'Vote'),
        winner = _s(j, 'Winner');
  int election, year;
  String vote, winner;
  J toJson() => {'Election': election, 'Year': year, 'Vote': vote, 'Winner': winner};
}

class WeddingRecord {
  WeddingRecord();
  WeddingRecord.fromJson(J j)
      : pending = _b(j, 'Pending'),
        partnerId = _s(j, 'PartnerId'),
        ceremony = _s(j, 'Ceremony'),
        day = _i(j, 'Day', -1),
        cost = _i(j, 'Cost'),
        cashGifts = _i(j, 'CashGifts'),
        goldUnits = _i(j, 'GoldUnits'),
        goldValueAtWedding = _i(j, 'GoldValueAtWedding'),
        contributors = _ls(j, 'Contributors');

  bool pending = false;
  String partnerId = '', ceremony = '';
  int day = -1, cost = 0, cashGifts = 0, goldUnits = 0, goldValueAtWedding = 0;
  List<String> contributors = [];

  J toJson() => {
        'Pending': pending, 'PartnerId': partnerId, 'Ceremony': ceremony, 'Day': day, 'Cost': cost,
        'CashGifts': cashGifts, 'GoldUnits': goldUnits, 'GoldValueAtWedding': goldValueAtWedding,
        'Contributors': contributors,
      };

  void ensureValid() {
    cost = cost < 0 ? 0 : cost;
    cashGifts = cashGifts < 0 ? 0 : cashGifts;
    goldUnits = _clamp(goldUnits, 0, 100);
    goldValueAtWedding = goldValueAtWedding < 0 ? 0 : goldValueAtWedding;
  }
}

class DelayedLifeScene {
  DelayedLifeScene({required this.sceneId, required this.dueDay, this.cause = ''});
  DelayedLifeScene.fromJson(J j)
      : sceneId = _s(j, 'SceneId'),
        dueDay = _i(j, 'DueDay'),
        cause = _s(j, 'Cause');
  String sceneId;
  int dueDay;
  String cause;
  J toJson() => {'SceneId': sceneId, 'DueDay': dueDay, 'Cause': cause};
}

const qualityKeys = ['autonomy', 'family', 'purpose', 'community', 'resilience'];

/// Kalıcı dünya ve anlatı hafızası. Bütün rakamlar kurgusal bir oyun modeline aittir.
class LifeSimulationState {
  LifeSimulationState();

  bool initialized = false;
  int birthYear = 2026, lastWorldAge = -1;
  int costIndex = 100, employment = 55, publicServices = 55, socialTension = 25;
  String country = 'Vita Cumhuriyeti', government = 'Ortak yönetim';
  int electionNumber = 0, electionOpenedAge = -1, electionClosesDay = -1, lastVotedElection = -1;
  String lastVote = '';
  List<CivicRecord> elections = [];
  WeddingRecord wedding = WeddingRecord();
  Map<String, int> qualities = {for (final k in qualityKeys) k: 50};
  List<DelayedLifeScene> followUps = [];
  Map<String, String> domainEcho = {};
  Map<String, int> domainLastDay = {};
  int directedAge = -1, directedThisAge = 0, lastDirectedDay = -365;
  String currentSceneId = '', currentSceneReason = '', lastDecisionEcho = '';
  String occupation = '', careerTheme = '', lastCareerId = '';
  int goldWallet = 0;
  Set<String> weddingGivers = {};
  int yearsInCare = 0;

  int year(GameState s) => birthYear + s.age;

  LifeSimulationState.fromJson(J j) {
    initialized = _b(j, 'Initialized');
    birthYear = _i(j, 'BirthYear', 2026);
    lastWorldAge = _i(j, 'LastWorldAge', -1);
    costIndex = _i(j, 'CostIndex', 100);
    employment = _i(j, 'Employment', 55);
    publicServices = _i(j, 'PublicServices', 55);
    socialTension = _i(j, 'SocialTension', 25);
    country = _s(j, 'Country', country);
    government = _s(j, 'Government', government);
    electionNumber = _i(j, 'ElectionNumber');
    electionOpenedAge = _i(j, 'ElectionOpenedAge', -1);
    electionClosesDay = _i(j, 'ElectionClosesDay', -1);
    lastVotedElection = _i(j, 'LastVotedElection', -1);
    lastVote = _s(j, 'LastVote');
    elections = _lo(j, 'Elections', CivicRecord.fromJson);
    wedding = WeddingRecord.fromJson(_o(j, 'Wedding'));
    if (j['Qualities'] is Map) qualities = _mi(j, 'Qualities');
    followUps = _lo(j, 'FollowUps', DelayedLifeScene.fromJson);
    domainEcho = {...?(j['DomainEcho'] as Map?)?.map((a, b) => MapEntry(a as String, b as String))};
    domainLastDay = _mi(j, 'DomainLastDay');
    directedAge = _i(j, 'DirectedAge', -1);
    directedThisAge = _i(j, 'DirectedThisAge');
    lastDirectedDay = _i(j, 'LastDirectedDay', -365);
    currentSceneId = _s(j, 'CurrentSceneId');
    currentSceneReason = _s(j, 'CurrentSceneReason');
    lastDecisionEcho = _s(j, 'LastDecisionEcho');
    occupation = _s(j, 'Occupation');
    careerTheme = _s(j, 'CareerTheme');
    lastCareerId = _s(j, 'LastCareerId');
    goldWallet = _i(j, 'GoldWallet');
    weddingGivers = _ls(j, 'WeddingGivers').toSet();
    yearsInCare = _i(j, 'YearsInCare');
  }

  J toJson() => {
        'Initialized': initialized, 'BirthYear': birthYear, 'LastWorldAge': lastWorldAge, 'CostIndex': costIndex,
        'Employment': employment, 'PublicServices': publicServices, 'SocialTension': socialTension,
        'Country': country, 'Government': government, 'ElectionNumber': electionNumber,
        'ElectionOpenedAge': electionOpenedAge, 'ElectionClosesDay': electionClosesDay,
        'LastVotedElection': lastVotedElection, 'LastVote': lastVote,
        'Elections': [for (final e in elections) e.toJson()], 'Wedding': wedding.toJson(),
        'Qualities': qualities, 'FollowUps': [for (final f in followUps) f.toJson()], 'DomainEcho': domainEcho,
        'DomainLastDay': domainLastDay, 'DirectedAge': directedAge, 'DirectedThisAge': directedThisAge,
        'LastDirectedDay': lastDirectedDay, 'CurrentSceneId': currentSceneId,
        'CurrentSceneReason': currentSceneReason, 'LastDecisionEcho': lastDecisionEcho, 'Occupation': occupation,
        'CareerTheme': careerTheme, 'LastCareerId': lastCareerId, 'GoldWallet': goldWallet,
        'WeddingGivers': weddingGivers.toList(), 'YearsInCare': yearsInCare,
      };

  void ensureValid() {
    birthYear = _clamp(birthYear, 1900, 2400);
    costIndex = _clamp(costIndex, 80, 220);
    employment = _clamp(employment, 10, 90);
    publicServices = _clamp(publicServices, 10, 90);
    socialTension = _clamp(socialTension, 0, 100);
    goldWallet = _clamp(goldWallet, 0, 10000);
    wedding.ensureValid();
    if (elections.length > 30) elections.removeRange(0, elections.length - 30);
    for (final k in qualityKeys) {
      qualities[k] = _clamp(qualities[k] ?? 50, 0, 100);
    }
    followUps.removeWhere((f) => f.sceneId.isEmpty);
    directedThisAge = _clamp(directedThisAge, 0, 8);
  }
}

class GameState {
  static const currentSaveVersion = 8;
  static const statMin = 0, statMax = 100;

  int saveVersion = currentSaveVersion;
  LifeSimulationState simulation = LifeSimulationState();
  SavedMoment? pendingMoment;
  String playerName = '';
  int age = 0;
  CharacterProfile profile = CharacterProfile();
  List<JournalEntry> journal = [];
  List<RelationshipPerson> relationships = [];
  bool relationshipsInitialized = false;
  Map<String, int> actionLastDay = {};
  int actionBudgetAge = -1, actionsUsed = 0;
  int bankBalance = 0;
  int appearance = 60, luck = 50, followers = 0;
  String miniGameSession = '';
  int miniGamesWon = 0, totalChoices = 0;

  /// Bu hayatta kullanılan ödüllü "derin nefes" hakkı. En fazla 3.
  int rewardedBreathsUsed = 0;
  bool secondChanceUsed = false;

  /// Ayrıntılı tempoda küçük etkilerin kaybolmaması için üçte bir artıklar.
  Map<Stat, int> effectRemainders = {};
  String lifeFocus = 'Dengeli';
  int focusChangedDay = -365;

  /// Oyun başından beri geçen toplam gün; [dayOfYear] 0..364, 0 = doğum günü.
  int day = 0, dayOfYear = 0;

  /// Tam ₺ (64 bit).
  int money = 0;
  int health = 0, happiness = 0, education = 0, social = 0;
  Education educationLevel = Education.none;
  String? careerId;
  int careerLevel = 0, careerStartDay = 0, careerLevelStartDay = 0;
  String? lastCareerId;
  Map<String, int> careerApplicationDay = {};
  int pensionMonthly = 0;
  Education? studyLevel;
  int studyStartAge = 0;
  List<String> completedEventIds = [];
  Map<String, int> eventLastSeenDay = {};

  /// Olay/sahne kimliği → bu hayatta kaç kez sunuldu (v7). Tekrar sınırı bunu okur.
  Map<String, int> eventShowCounts = {};

  /// Ekrandaki olayın anı oynandıysa "olay@gün" (v8); not ve etkiler karar sonucuna eklenir.
  String momentKey = '';
  String momentNote = '';
  List<StatChange> momentChanges = [];
  Set<String> flags = {};
  List<String> recentEventIds = [];
  String? pendingEventId;
  String? currentEventId;
  int lastEconomyProcessedMonth = -1;

  /// RNG tohum ve durumu (64 bit; Dart'ta işaretli tutulur).
  int rngSeed = 0, rngState = 0;
  List<String> activeGoalIds = [], completedGoalIds = [], achievementsThisLife = [];
  String? endingId;
  bool isGameOver = false;
  GameOverReason? gameOverReason;

  GameState();

  factory GameState.createNew(String playerName, int startAge, int seed) => GameState()
    ..playerName = playerName
    ..age = startAge
    ..health = 80
    ..happiness = 70
    ..education = 10
    ..social = 50
    ..rngSeed = seed;

  String get ageText => age < 2 ? '${age * 12 + dayOfYear * 12 ~/ 365} aylık' : '$age yaşında';

  String get lifeStage => switch (age) {
        < 2 => 'Bebeklik',
        < 6 => 'İlk keşifler',
        < 13 => 'Çocukluk',
        < 18 => 'Gençlik',
        < 35 => 'Kendi yolun',
        < 65 => 'Hayatın ortasında',
        _ => 'Biriken anılar',
      };

  int getStat(Stat stat) => switch (stat) {
        Stat.health => health,
        Stat.happiness => happiness,
        Stat.education => education,
        Stat.social => social,
        // Para int32 aralığını aşabilir; koşul karşılaştırmaları için sınırla (C# ile aynı).
        Stat.money => money > 2147483647 ? 2147483647 : money,
      };

  GameState.fromJson(J j) {
    saveVersion = _i(j, 'SaveVersion', currentSaveVersion);
    simulation = LifeSimulationState.fromJson(_o(j, 'Simulation'));
    pendingMoment = j['PendingMoment'] is Map ? SavedMoment.fromJson(_o(j, 'PendingMoment')) : null;
    playerName = _s(j, 'PlayerName');
    age = _i(j, 'Age');
    profile = CharacterProfile.fromJson(_o(j, 'Profile'));
    journal = _lo(j, 'Journal', JournalEntry.fromJson);
    relationships = _lo(j, 'Relationships', RelationshipPerson.fromJson);
    relationshipsInitialized = _b(j, 'RelationshipsInitialized');
    actionLastDay = _mi(j, 'ActionLastDay');
    actionBudgetAge = _i(j, 'ActionBudgetAge', -1);
    actionsUsed = _i(j, 'ActionsUsed');
    bankBalance = _i(j, 'BankBalance');
    appearance = _i(j, 'Appearance', 60);
    luck = _i(j, 'Luck', 50);
    followers = _i(j, 'Followers');
    miniGameSession = _s(j, 'MiniGameSession');
    miniGamesWon = _i(j, 'MiniGamesWon');
    totalChoices = _i(j, 'TotalChoices');
    rewardedBreathsUsed = _i(j, 'RewardedBreathsUsed');
    secondChanceUsed = _b(j, 'SecondChanceUsed');
    effectRemainders = {
      for (final e in _mi(j, 'EffectRemainders').entries)
        ?enumByName(Stat.values, e.key): e.value,
    };
    lifeFocus = _s(j, 'LifeFocus', 'Dengeli');
    focusChangedDay = _i(j, 'FocusChangedDay', -365);
    day = _i(j, 'Day');
    dayOfYear = _i(j, 'DayOfYear');
    money = _i(j, 'Money');
    health = _i(j, 'Health');
    happiness = _i(j, 'Happiness');
    education = _i(j, 'Education');
    social = _i(j, 'Social');
    educationLevel = enumByName(Education.values, j['EducationLevel'] as String?) ?? Education.none;
    careerId = j['CareerId'] as String?;
    careerLevel = _i(j, 'CareerLevel');
    careerStartDay = _i(j, 'CareerStartDay');
    careerLevelStartDay = _i(j, 'CareerLevelStartDay');
    lastCareerId = j['LastCareerId'] as String?;
    careerApplicationDay = _mi(j, 'CareerApplicationDay');
    pensionMonthly = _i(j, 'PensionMonthly');
    studyLevel = enumByName(Education.values, j['StudyLevel'] as String?);
    studyStartAge = _i(j, 'StudyStartAge');
    completedEventIds = _ls(j, 'CompletedEventIds');
    eventLastSeenDay = _mi(j, 'EventLastSeenDay');
    eventShowCounts = _mi(j, 'EventShowCounts');
    momentKey = _s(j, 'MomentKey');
    momentNote = _s(j, 'MomentNote');
    momentChanges = _lo(j, 'MomentChanges', StatChange.fromJson);
    flags = _ls(j, 'Flags').toSet();
    recentEventIds = _ls(j, 'RecentEventIds');
    pendingEventId = j['PendingEventId'] as String?;
    currentEventId = j['CurrentEventId'] as String?;
    lastEconomyProcessedMonth = _i(j, 'LastEconomyProcessedMonth', -1);
    rngSeed = _i(j, 'RngSeed');
    rngState = _i(j, 'RngState');
    activeGoalIds = _ls(j, 'ActiveGoalIds');
    completedGoalIds = _ls(j, 'CompletedGoalIds');
    achievementsThisLife = _ls(j, 'AchievementsThisLife');
    endingId = j['EndingId'] as String?;
    isGameOver = _b(j, 'IsGameOver');
    gameOverReason = switch (j['GameOverReason']) {
      'HealthDepleted' => GameOverReason.healthDepleted,
      'OldAge' => GameOverReason.oldAge,
      _ => null,
    };
  }

  J toJson() => {
        'SaveVersion': saveVersion, 'Simulation': simulation.toJson(), 'PendingMoment': pendingMoment?.toJson(),
        'PlayerName': playerName, 'Age': age, 'Profile': profile.toJson(),
        'Journal': [for (final e in journal) e.toJson()],
        'Relationships': [for (final p in relationships) p.toJson()],
        'RelationshipsInitialized': relationshipsInitialized, 'ActionLastDay': actionLastDay,
        'ActionBudgetAge': actionBudgetAge, 'ActionsUsed': actionsUsed, 'BankBalance': bankBalance,
        'Appearance': appearance, 'Luck': luck, 'Followers': followers, 'MiniGameSession': miniGameSession,
        'MiniGamesWon': miniGamesWon, 'TotalChoices': totalChoices, 'RewardedBreathsUsed': rewardedBreathsUsed,
        'SecondChanceUsed': secondChanceUsed,
        'EffectRemainders': {for (final e in effectRemainders.entries) statName(e.key): e.value},
        'LifeFocus': lifeFocus, 'FocusChangedDay': focusChangedDay, 'Day': day, 'DayOfYear': dayOfYear,
        'Money': money, 'Health': health, 'Happiness': happiness, 'Education': education, 'Social': social,
        'EducationLevel': educationName(educationLevel), 'CareerId': careerId, 'CareerLevel': careerLevel,
        'CareerStartDay': careerStartDay, 'CareerLevelStartDay': careerLevelStartDay, 'LastCareerId': lastCareerId,
        'CareerApplicationDay': careerApplicationDay, 'PensionMonthly': pensionMonthly,
        'StudyLevel': studyLevel == null ? null : educationName(studyLevel!), 'StudyStartAge': studyStartAge,
        'CompletedEventIds': completedEventIds, 'EventLastSeenDay': eventLastSeenDay, 'EventShowCounts': eventShowCounts,
        'MomentKey': momentKey, 'MomentNote': momentNote, 'MomentChanges': [for (final c in momentChanges) c.toJson()], 'Flags': flags.toList(),
        'RecentEventIds': recentEventIds, 'PendingEventId': pendingEventId, 'CurrentEventId': currentEventId,
        'LastEconomyProcessedMonth': lastEconomyProcessedMonth, 'RngSeed': rngSeed, 'RngState': rngState,
        'ActiveGoalIds': activeGoalIds, 'CompletedGoalIds': completedGoalIds,
        'AchievementsThisLife': achievementsThisLife, 'EndingId': endingId, 'IsGameOver': isGameOver,
        'GameOverReason': gameOverReason == null ? null : gameOverName(gameOverReason!),
      };

  /// Kayıttan okunan durumu onarır: sınır dışı değerler oyunu çökertmesin.
  void ensureValid() {
    simulation.ensureValid();
    profile.ensureValid();
    if (journal.length > 300) journal.removeRange(0, journal.length - 300);
    for (final p in relationships) {
      p.ensureValid();
    }
    actionsUsed = _clamp(actionsUsed, 0, 12);
    bankBalance = _clamp(bankBalance, 0, 1000000000000);
    appearance = _clamp(appearance, 0, 100);
    luck = _clamp(luck, 0, 100);
    followers = _clamp(followers, 0, 100000000);
    if (miniGamesWon < 0) miniGamesWon = 0;
    if (totalChoices < 0) totalChoices = 0;
    rewardedBreathsUsed = _clamp(rewardedBreathsUsed, 0, 3);
    effectRemainders.updateAll((_, v) => _clamp(v, -2, 2));
    if (!lifeFocuses.contains(lifeFocus)) lifeFocus = 'Dengeli';
    if (age < 0) age = 0;
    if (day < 0) day = 0;
    dayOfYear = _clamp(dayOfYear, 0, 364);
    health = _clamp(health, statMin, statMax);
    happiness = _clamp(happiness, statMin, statMax);
    education = _clamp(education, statMin, statMax);
    social = _clamp(social, statMin, statMax);
    careerLevel = (careerId ?? '').isEmpty ? 0 : (careerLevel < 1 ? 1 : careerLevel);
    if (pensionMonthly < 0) pensionMonthly = 0;
  }
}
