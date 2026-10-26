import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_simulation/content/game_content.dart';
import 'package:life_simulation/content/models.dart';
import 'package:life_simulation/game/save.dart';
import 'package:life_simulation/game/session.dart';
import 'package:life_simulation/game/social.dart';
import 'package:life_simulation/game/state.dart';
import 'package:life_simulation/game/world.dart';
import 'package:life_simulation/game/wedding.dart';

import 'content_test.dart' show contentPaths, readFile;

void main() {
  late GameContent content;
  late Directory dir;
  late GameSession game;
  setUpAll(() async {
    content = await GameContent.load(contentPaths(), readFile);
  });
  setUp(() {
    dir = Directory.systemTemp.createTempSync('vita_p3_');
    game = GameSession(content, SaveService('${dir.path}/save.json'))
      ..startNewGame('Deniz', seed: 42);
  });
  tearDown(() => dir.deleteSync(recursive: true));
  GameState adult() => game.state!
    ..age = 25
    ..day = 9125
    ..pendingEventId = null
    ..educationLevel = Education.university
    ..education = 80
    ..money = 500000;

  test('activity cooldown, annual budget and save survive reload', () {
    final s = adult();
    expect(game.doAction('read').success, isTrue);
    final before = s.education;
    expect(game.doAction('read').success, isFalse);
    expect(s.education, before);
    final loaded = GameSession(content, game.saves)..continueGame();
    expect(Social.remaining(loaded.state!), 11);
    expect(loaded.doAction('read').success, isFalse);
    s.actionsUsed = 12;
    expect(game.doAction('walk').success, isFalse);
    s.age++;
    expect(game.doAction('walk').success, isTrue);
    expect(s.actionsUsed, 1);
  });
  test('bank rejects invalid transfers and preserves total savings', () {
    final s = adult();
    final total = s.money;
    expect(game.transferBank(1000, deposit: true).success, isTrue);
    expect(s.money + s.bankBalance, total);
    expect(game.transferBank(1001, deposit: false).success, isFalse);
    expect(game.transferBank(-1, deposit: true).success, isFalse);
    expect(game.transferBank(1000, deposit: false).success, isTrue);
    expect(s.money, total);
    s.age = 17;
    expect(game.transferBank(1, deposit: true).success, isFalse);
  });
  test('fate, salary budget, monthly idempotence and retirement', () {
    final s = adult();
    expect(game.trustFate().success, isTrue);
    expect(s.careerId, isNotNull);
    final salary = game.progression.salary(s);
    expect(salary, greaterThan(0));
    final expected = game.progression.budget(s).fold(0, (v, l) => v + l.$2);
    final before = s.money;
    final report = TurnReport();
    expect(game.progression.processMonth(s, 301, report), isTrue);
    expect(s.money - before, expected);
    expect(game.progression.processMonth(s, 301, report), isFalse);
    expect(report.net, expected);
    game.quitCareer();
    expect(game.trustFate().success, isFalse);
    s.age = 65;
    game.progression.careerBirthday(s, report);
    expect(s.flags, contains('retired'));
    expect(s.pensionMonthly, greaterThanOrEqualTo(7000));
    expect(game.trustFate().success, isFalse);
  });
  test('automatic school, graduation and voluntary university enrollment', () {
    final s = game.state!..age = 6;
    game.progression.enroll(s, null);
    expect(s.studyLevel, Education.primary);
    for (var age = 7; age <= 18; age++) {
      s.age = age;
      game.progression.schoolBirthday(s, null);
    }
    expect(s.educationLevel, Education.highSchool);
    expect(s.studyLevel, isNull);
    s.flags.add('enroll_university');
    game.progression.enroll(s, null);
    expect(s.studyLevel, Education.university);
    expect(s.flags, isNot(contains('enroll_university')));
    s.age = 22;
    game.progression.schoolBirthday(s, null);
    expect(s.educationLevel, Education.university);
  });
  test('goals reward only once; mini game rewards only once', () {
    final s = adult();
    expect(s.activeGoalIds.length, 3);
    final token = game.startMiniGame('balls');
    expect(token.success, isTrue);
    expect(game.finishMiniGame(token.message, 5).success, isTrue);
    final education = s.education;
    expect(game.finishMiniGame(token.message, 5).success, isFalse);
    expect(s.education, education);
    game.progression.checkGoals(s, null);
    final completed = [...s.completedGoalIds];
    final happiness = s.happiness;
    game.progression.checkGoals(s, null);
    expect(s.completedGoalIds, completed);
    expect(s.happiness, happiness);
  });
  test('election and wedding decisions restore and apply once', () {
    final s = adult();
    s.simulation
      ..electionNumber = 4
      ..electionClosesDay = s.day + 90;
    expect(game.requestNextEvent()!.id, World.electionId);
    game.save();
    final loaded = GameSession(content, game.saves)..continueGame();
    expect(loaded.requestNextEvent()!.id, World.electionId);
    expect(loaded.submitChoice('services'), isNotNull);
    expect(loaded.state!.simulation.lastVotedElection, 4);
    expect(loaded.submitChoice('services'), isNull);
    final p = RelationshipPerson(
      id: 'partner',
      name: 'Ekin',
      role: 'Partner',
      bond: 90,
    );
    s.relationships.add(p);
    expect(Wedding.plan(s, p).$1, isTrue);
    game.currentEvent = null;
    s.currentEventId = null;
    s.pendingMoment = null;
    s.simulation.lastVotedElection = 4;
    expect(game.requestNextEvent()!.id, Wedding.eventId);
    expect(game.submitChoice('civil'), isNotNull);
    expect(p.role, 'Eş');
    expect(s.flags, contains('married'));
    expect(s.simulation.wedding.cost, 8000);
    expect(game.submitChoice('civil'), isNull);
  });
}
