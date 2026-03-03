import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/enums.dart';
import 'theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/quest_provider.dart';
import 'providers/points_provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/hero_provider.dart';
import 'providers/achievement_provider.dart';
import 'services/background_service.dart';
import 'pages/splash_page.dart';
import 'pages/login_page.dart';
import 'pages/hero_home_page.dart';
import 'pages/parent_dashboard_page.dart';
import 'pages/setup/family_setup_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await BackgroundService().init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => QuestProvider()),
        ChangeNotifierProvider(create: (context) => PointsProvider()),
        ChangeNotifierProvider(create: (context) => ChallengeProvider()),
        ChangeNotifierProvider(create: (context) => RewardProvider()),
        ChangeNotifierProvider(create: (context) => HeroProvider()),
        ChangeNotifierProvider(create: (context) => AchievementProvider()),
      ],
      child: const ProviderConnector(child: MochiPointsApp()),
    ),
  );
}

/// Connects providers with callbacks for cross-provider communication
class ProviderConnector extends StatefulWidget {
  final Widget child;

  const ProviderConnector({super.key, required this.child});

  @override
  State<ProviderConnector> createState() => _ProviderConnectorState();
}

class _ProviderConnectorState extends State<ProviderConnector> {
  @override
  void initState() {
    super.initState();
    // Connect providers after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectProviders();
    });
  }

  void _connectProviders() {
    final questProvider = context.read<QuestProvider>();
    final pointsProvider = context.read<PointsProvider>();
    final heroProvider = context.read<HeroProvider>();
    final rewardProvider = context.read<RewardProvider>();

    // Connect RewardProvider to PointsProvider for purchases
    rewardProvider.setPointsProvider(pointsProvider);

    // When a quest is approved, award points and XP
    questProvider.onQuestApproved = ({
      required String childId,
      required int points,
      required int xp,
      required String questId,
      required String questName,
    }) {
      // First record activity to update streak
      heroProvider.recordActivity(childId);

      // Get streak bonus multiplier
      final bonusMultiplier = heroProvider.getStreakBonus(childId);
      final bonusPercent = heroProvider.getStreakBonusPercent(childId);

      // Calculate bonus points (only the extra amount)
      final bonusPoints = ((points * bonusMultiplier) - points).round();
      final totalPoints = points + bonusPoints;

      // Award base points
      pointsProvider.earn(
        childId,
        points,
        TransactionType.questComplete,
        referenceId: questId,
        description: 'Quest abgeschlossen: $questName',
      );

      // Award bonus points separately (if any)
      if (bonusPoints > 0) {
        final hero = heroProvider.heroForUser(childId);
        final streak = hero?.currentStreak ?? 0;
        pointsProvider.earn(
          childId,
          bonusPoints,
          TransactionType.bonus,
          referenceId: questId,
          description: 'Streak Bonus +$bonusPercent% (🔥 $streak)',
        );
      }

      // Award XP (no streak bonus on XP)
      heroProvider.addXP(childId, xp);

      // Log total for debugging
      debugPrint('Quest approved: $questName - $points MP + $bonusPoints Bonus = $totalPoints MP');
    };
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MochiPointsApp extends StatelessWidget {
  const MochiPointsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mochi Points',
      theme: AppTheme.darkTheme(),
      debugShowCheckedModeBanner: false,
      home: const SplashPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/family-setup': (context) => const FamilySetupPage(),
        '/hero-home': (context) => const HeroHomePage(),
        '/parent-dashboard': (context) => const ParentDashboardPage(),
      },
    );
  }
}
