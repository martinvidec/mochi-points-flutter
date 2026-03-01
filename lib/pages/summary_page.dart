import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/mochi_point_account_provider.dart';
import '../providers/mochi_point_provider.dart';
import 'mochi_points_page.dart';
import '../widgets/bottom_navigation.dart';
import '../widgets/wave_painter.dart';

class SummaryPage extends StatefulWidget {
  const SummaryPage({super.key});

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
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

  Widget _buildSummary() {
    final accountProvider = Provider.of<MochiPointAccountProvider>(context);
    final mochiPointProvider = Provider.of<MochiPointProvider>(context);
    final now = DateTime.now();
    final lastWeek = now.subtract(Duration(days: 7));

    final mochiPoints = mochiPointProvider.mochiPoints;
    final totalPoints = mochiPoints.map((m) => m.points).fold(0.0, (a, b) => a + b);

    final lastWeekPoints = mochiPoints
        .where((m) => m.date.isAfter(lastWeek))
        .map((m) => m.points)
        .fold(0.0, (a, b) => a + b);
    final lastWeekCount = mochiPoints
        .where((m) => m.date.isAfter(lastWeek))
        .length;

    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Konto', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Aktueller Kontostand', '${accountProvider.balance} Punkte'),
            ],
          ),
          SizedBox(height: 16),
          Text('Übersicht', 
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary)),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Gesamtpunkte', totalPoints.toStringAsFixed(1)),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryItem('Punkte letzte Woche', lastWeekPoints.toStringAsFixed(1)),
              _buildSummaryItem('Anzahl letzte Woche', lastWeekCount.toString()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Mochi Points',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
          ),
        ),
      ),
      body: Stack(
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
          SingleChildScrollView(
            child: Column(
              children: [
                _buildSummary(),
                // Hier können Sie weitere Widgets hinzufügen, falls benötigt
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0,
        onTap: (index) {
          if (index != 0) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation1, animation2) => MochiPointsPage(title: 'Mochi Points', initialIndex: index),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          }
        },
      ),
    );
  }
}
