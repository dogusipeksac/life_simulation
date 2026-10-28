import '../content/models.dart';
import 'state.dart';

class LifeSummary {
  const LifeSummary({
    required this.name,
    required this.age,
    required this.money,
    required this.educationLevel,
    required this.career,
    required this.reason,
    required this.health,
    required this.happiness,
    required this.education,
    required this.social,
    required this.eventsLived,
    required this.highlights,
    required this.endingTitle,
    required this.endingText,
    required this.goals,
    required this.completedGoals,
    required this.achievements,
    required this.portrait,
    required this.story,
    required this.memories,
  });
  final String name, career, endingTitle, endingText, portrait, story;
  final int age, money, health, happiness, education, social, eventsLived;
  final Education educationLevel;
  final GameOverReason? reason;
  final List<String> highlights, achievements, memories;
  final List<Goal> goals;
  final Set<String> completedGoals;
}
