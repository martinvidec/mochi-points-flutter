import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/mochi_point.dart';
import '../models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../providers/mochi_point_account_provider.dart';
import '../providers/mochi_point_provider.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import '../widgets/wave_painter.dart';
import '../widgets/bottom_navigation.dart';
import 'cart_item_page.dart';
import 'eaties_page.dart';
import 'challenges_page.dart';
import 'summary_page.dart';

class MochiPointsPage extends StatefulWidget {
  final String title;
  final int initialIndex;

  const MochiPointsPage({super.key, required this.title, this.initialIndex = 1});

  @override
  State<MochiPointsPage> createState() => _MochiPointsPageState();
}

class _MochiPointsPageState extends State<MochiPointsPage> with SingleTickerProviderStateMixin {
  late int _currentIndex;

  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _animationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == 0) {
      // Navigate to SummaryPage
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) => const SummaryPage(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _addNewMochiPoint() {
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    final accountProvider = Provider.of<MochiPointAccountProvider>(context, listen: false);
    final mochiPointProvider = Provider.of<MochiPointProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        Challenge? selectedChallenge;
        String errorText = '';
        return StatefulBuilder(
          builder: (context, setState) {
            final challenges = challengeProvider.challenges;
            return AlertDialog(
              title: Text('Neuen Mochi Point hinzufügen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (challenges.isEmpty)
                    Text('Keine Challenges verfügbar. Bitte erstellen Sie zuerst eine Challenge.')
                  else
                    DropdownButton<Challenge>(
                      value: selectedChallenge,
                      hint: Text('Challenge auswählen'),
                      onChanged: (Challenge? newValue) {
                        setState(() {
                          selectedChallenge = newValue;
                          errorText = '';
                        });
                      },
                      items: challenges.map<DropdownMenuItem<Challenge>>((Challenge challenge) {
                        return DropdownMenuItem<Challenge>(
                          value: challenge,
                          child: Text(challenge.name),
                        );
                      }).toList(),
                    ),
                  if (selectedChallenge != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('Punkte: ${selectedChallenge!.reward}'),
                    ),
                  if (errorText.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        errorText,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Abbrechen'),
                ),
                TextButton(
                  onPressed: challenges.isEmpty ? null : () {
                    if (selectedChallenge != null) {
                      Navigator.of(context).pop();
                      mochiPointProvider.addMochiPoint(MochiPoint(selectedChallenge!, selectedChallenge!.reward, DateTime.now()));
                      accountProvider.addPoints(selectedChallenge!.reward);
                    } else {
                      setState(() {
                        errorText = 'Bitte wählen Sie eine Challenge aus';
                      });
                    }
                  },
                  child: Text('Hinzufügen'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Widget _buildSummary() {
    final accountProvider = Provider.of<MochiPointAccountProvider>(context);
    final now = DateTime.now();
    final lastWeek = now.subtract(Duration(days: 7));

    final mochiPointProvider = Provider.of<MochiPointProvider>(context);
    final totalPoints = mochiPointProvider.mochiPoints.map((m) => m.points).sum;

    final lastWeekPoints = mochiPointProvider.mochiPoints
        .where((m) => m.date.isAfter(lastWeek))
        .map((m) => m.points)
        .sum;
    final lastWeekCount = mochiPointProvider.mochiPoints
        .where((m) => m.date.isAfter(lastWeek))
        .length;

    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.surface,
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return CustomPaint(
                painter: WavePainter(
                  animation: _animation,
                  waveColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                  secondWaveColor: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.2),
                ),
                size: Size.infinite,
              );
            },
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Zusammenfassung',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Aktueller Kontostand', '${accountProvider.balance} Punkte'),
                    _buildSummaryItem('Gesamtpunkte', totalPoints.toString()),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSummaryItem('Punkte letzte Woche', lastWeekPoints.toString()),
                    _buildSummaryItem('Anzahl letzte Woche', lastWeekCount.toString()),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _buildMochiPointsContent() {
    final mochiPointProvider = Provider.of<MochiPointProvider>(context);
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
    final pointFormatter = NumberFormat('0.0');

    return Column(
      children: [
        _buildSummary(),
        Expanded(
          child: mochiPointProvider.mochiPoints.isEmpty
              ? Center(
                  child: Text(
                    'Noch keine Mochi Points gesammelt.\nErstelle eine Challenge und sammle Punkte!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: mochiPointProvider.mochiPoints.length,
                  itemBuilder: (context, index) {
                    final mochiPoint = mochiPointProvider.mochiPoints[index];
                    return ListTile(
                      title: Text(mochiPoint.challenge.name),
                      subtitle: Text(dateFormatter.format(mochiPoint.date)),
                      trailing: Text('${pointFormatter.format(mochiPoint.points)} Punkte'),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _getBodyContent() {
    switch (_currentIndex) {
      case 1: // Mochi Points
        return _buildMochiPointsContent();
      case 2: // Eaties
        return const EatiesPage();
      case 3: // Challenges
        return const ChallengesPage();
      case 4: // Warenkorb
        return const CartItemPage();
      default:
        return _buildMochiPointsContent();
    }
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 1:
        return 'Mochi Points';
      case 2:
        return 'Eaties';
      case 3:
        return 'Challenges';
      case 4:
        return 'Warenkorb';
      default:
        return 'Mochi Points';
    }
  }

  Widget? _getFloatingActionButton() {
    switch (_currentIndex) {
      case 1: // Mochi Points - add new point
        return FloatingActionButton(
          onPressed: _addNewMochiPoint,
          child: Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _getTitle(),
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              setState(() {
                _currentIndex = 4;
              });
            },
          ),
        ],
      ),
      body: _getBodyContent(),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
      floatingActionButton: _getFloatingActionButton(),
    );
  }
}
