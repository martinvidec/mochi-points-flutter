import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
import 'dart:math' as math;
import 'models/eaty.dart';
import 'views/eaties_view.dart';
import 'views/cart_view.dart';
import 'models/cart_item.dart';
import 'models/challenge.dart';
import 'views/challenges_view.dart';
import 'pages/challenge_edit_page.dart';
import 'package:provider/provider.dart';
import 'providers/challenge_provider.dart';
import 'providers/mochi_point_account_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChallengeProvider()),
        ChangeNotifierProvider(create: (context) => MochiPointAccountProvider()),
      ],
      child: MochiPointsApp(),
    ),
  );
}

class MochiPointsApp extends StatelessWidget {
  const MochiPointsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mochi Points',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFFF7E7E), // Sakura pink
          primary: Color(0xFFFF7E7E), // Sakura pink
          secondary: Color(0xFFFFD23F), // Yuzu yellow
          tertiary: Color(0xFF7EAE4E), // Matcha green
          background: Color(0xFFFFF3E0), // Light cream
        ),
        useMaterial3: true,
      ),
      home: const MochiPointsPage(title: 'Mochi Points'),
    );
  }
}

class MochiPoint {
  final Challenge challenge;
  final double points;
  final DateTime date;

  MochiPoint(this.challenge, this.points, this.date) {
    if (points % 0.5 != 0) {
      throw ArgumentError('Points must be a multiple of 0.5');
    }
  }
}

class MochiPointsPage extends StatefulWidget {
  final String title;

  const MochiPointsPage({super.key, required this.title});

  @override
  State<MochiPointsPage> createState() => _MochiPointsPageState();
}

class _MochiPointsPageState extends State<MochiPointsPage> with SingleTickerProviderStateMixin {
  final List<MochiPoint> mochiPoints = [];

  final List<Eaty> eaties = [];

  List<CartItem> cartItems = [];

  int _currentIndex = 0;

  String _sortCriteria = 'date'; // Default sort criteria

  late AnimationController _animationController;
  late Animation<double> _animation;

  double get totalPoints => mochiPoints.map((m) => m.points).sum;

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

  void _sortMochiPoints(String criteria) {
    setState(() {
      _sortCriteria = criteria;
      switch (criteria) {
        case 'name':
          mochiPoints.sort((a, b) => a.challenge.name.compareTo(b.challenge.name));
          break;
        case 'points':
          mochiPoints.sort((a, b) => b.points.compareTo(a.points));
          break;
        case 'date':
          mochiPoints.sort((a, b) => b.date.compareTo(a.date));
          break;
      }
    });
  }

  void _addNewMochiPoint() {
    final challengeProvider = Provider.of<ChallengeProvider>(context, listen: false);
    final accountProvider = Provider.of<MochiPointAccountProvider>(context, listen: false);
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
                  child: Text('Abbrechen'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Hinzufügen'),
                  onPressed: challenges.isEmpty ? null : () {
                    if (selectedChallenge != null) {
                      Navigator.of(context).pop();
                      setState(() {
                        mochiPoints.add(MochiPoint(selectedChallenge!, selectedChallenge!.reward, DateTime.now()));
                        accountProvider.addPoints(selectedChallenge!.reward);
                      });
                    } else {
                      setState(() {
                        errorText = 'Bitte wählen Sie eine Challenge aus';
                      });
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _addNewEaty() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = '';
        double newPrice = 0;
        String errorText = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Neues Eaty hinzufügen'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    onChanged: (value) => newName = value,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Preis',
                      errorText: errorText.isNotEmpty ? errorText : null,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          newPrice = parsed;
                          errorText = '';
                        } else {
                          newPrice = 0;
                          errorText = 'Bitte geben Sie einen gültigen Preis ein';
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Hinzufügen'),
                  onPressed: () {
                    if (newName.isNotEmpty && newPrice > 0) {
                      Navigator.of(context).pop();
                      this.setState(() {
                        eaties.add(Eaty(newName, newPrice));
                        eaties.sort((a, b) => b.price.compareTo(a.price));
                      });
                    } else {
                      setState(() {
                        errorText = 'Bitte geben Sie einen Namen und einen gültigen Preis ein';
                      });
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _editEaty(Eaty eaty) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newName = eaty.name;
        double newPrice = eaty.price;
        String errorText = '';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Eaty bearbeiten'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    controller: TextEditingController(text: newName),
                    onChanged: (value) => newName = value,
                  ),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Preis',
                      errorText: errorText.isNotEmpty ? errorText : null,
                    ),
                    controller: TextEditingController(text: newPrice.toString()),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        final parsed = double.tryParse(value);
                        if (parsed != null && parsed > 0) {
                          newPrice = parsed;
                          errorText = '';
                        } else {
                          errorText = 'Bitte geben Sie einen gültigen Preis ein';
                        }
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Abbrechen'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  child: Text('Speichern'),
                  onPressed: () {
                    if (newName.isNotEmpty && newPrice > 0) {
                      Navigator.of(context).pop();
                      this.setState(() {
                        int index = eaties.indexOf(eaty);
                        eaties[index] = Eaty(newName, newPrice);
                        eaties.sort((a, b) => b.price.compareTo(a.price));
                      });
                    } else {
                      setState(() {
                        errorText = 'Bitte geben Sie einen Namen und einen gültigen Preis ein';
                      });
                    }
                  },
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteEaty(Eaty eaty) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Eaty löschen'),
          content: Text('Möchten Sie "${eaty.name}" wirklich löschen?'),
          actions: [
            TextButton(
              child: Text('Abbrechen'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Löschen'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  eaties.remove(eaty);
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _addToCart(Eaty eaty) {
    setState(() {
      int index = cartItems.indexWhere((item) => item.eaty.name == eaty.name);
      if (index != -1) {
        cartItems[index].quantity++;
      } else {
        cartItems.add(CartItem(eaty));
      }
    });
  }

  void _removeFromCart(CartItem item) {
    setState(() {
      if (item.quantity > 1) {
        item.quantity--;
      } else {
        cartItems.remove(item);
      }
    });
  }

  void _addQuantityToCart(CartItem item) {
    setState(() {
      item.quantity++;
    });
  }

  Widget _buildSummary() {
    final accountProvider = Provider.of<MochiPointAccountProvider>(context);
    final now = DateTime.now();
    final lastWeek = now.subtract(Duration(days: 7));

    final totalPoints = mochiPoints.map((m) => m.points).sum;
    final totalCount = mochiPoints.length;

    final lastWeekPoints = mochiPoints
        .where((m) => m.date.isAfter(lastWeek))
        .map((m) => m.points)
        .sum;
    final lastWeekCount = mochiPoints
        .where((m) => m.date.isAfter(lastWeek))
        .length;

    return Container(
      height: 200, // Adjust this height as needed
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary, // Sakura pink
                  Theme.of(context).colorScheme.background, // Light cream
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
                  waveColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                  secondWaveColor: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
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
        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');
    final pointFormatter = NumberFormat('0.0');
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
        actions: [
          if (_currentIndex == 0) // Only show sort options for Mochi Points
            PopupMenuButton<String>(
              icon: Icon(Icons.sort),
              onSelected: _sortMochiPoints,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                PopupMenuItem<String>(
                  value: 'name',
                  child: Text('Nach Name sortieren'),
                ),
                PopupMenuItem<String>(
                  value: 'points',
                  child: Text('Nach Punkten sortieren'),
                ),
                PopupMenuItem<String>(
                  value: 'date',
                  child: Text('Nach Datum sortieren'),
                ),
              ],
            ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              setState(() {
                _currentIndex = 3; // Switch to cart view
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummary(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: [
                ListView.builder(
                  itemCount: mochiPoints.length,
                  itemBuilder: (context, index) {
                    final mochiPoint = mochiPoints[index];
                    return ListTile(
                      title: Text(mochiPoint.challenge.name),
                      subtitle: Text(dateFormatter.format(mochiPoint.date)),
                      trailing: Text('${pointFormatter.format(mochiPoint.points)} Punkte'),
                    );
                  },
                ),
                EatiesView(
                  eaties: eaties,
                  totalPoints: totalPoints,
                  onAddToCart: _addToCart,
                  onEdit: _editEaty,
                  onDelete: _deleteEaty,
                ),
                ChallengesPage(),
                CartView(
                  cartItems: cartItems,
                  onRemove: _removeFromCart,
                  onAdd: _addQuantityToCart,
                  totalPoints: totalPoints,
                )
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // Dies stellt sicher, dass alle vier Items angezeigt werden
        selectedItemColor: Theme.of(context).colorScheme.primary, // Farbe für ausgewählte Items
        unselectedItemColor: Colors.grey[600], // Dunklere Farbe für nicht ausgewählte Items
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Mochi Points',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Eaties',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events),
            label: 'Challenges',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Warenkorb',
          ),
        ],
      ),
      floatingActionButton: _currentIndex <= 1
          ? FloatingActionButton(
              onPressed: () {
                if (_currentIndex == 0) {
                  _addNewMochiPoint();
                } else if (_currentIndex == 1) {
                  _addNewEaty();
                }
              },
              child: Icon(Icons.add),
            )
          : null,
    );
  }
}

class WavePainter extends CustomPainter {
  final Animation<double> animation;
  final Color waveColor;
  final Color secondWaveColor;

  WavePainter({
    required this.animation,
    required this.waveColor,
    required this.secondWaveColor,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    _drawWave(canvas, size, waveColor, 1.0, 10.0, 5.0);
    _drawWave(canvas, size, secondWaveColor, -0.5, 15.0, 7.5);
  }

  void _drawWave(Canvas canvas, Size size, Color color, double phaseShift, double amplitude1, double amplitude2) {
    final paint = Paint()..color = color;
    final path = Path();
    final y = size.height * 0.8;
    path.moveTo(0, y);

    for (int i = 0; i < size.width; i++) {
      path.lineTo(
        i.toDouble(),
        y + math.sin((animation.value * 360 + phaseShift * i) * math.pi / 180) * amplitude1 +
            math.sin((animation.value * 720 + phaseShift * i) * math.pi / 180) * amplitude2
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => true;
}

class ChallengesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final challengeProvider = Provider.of<ChallengeProvider>(context);
    
    void _addNewChallenge() {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChallengeEditPage(
            onSave: (Challenge newChallenge) {
              challengeProvider.addChallenge(newChallenge);
            },
          ),
        ),
      );
    }

    void _editChallenge(Challenge challenge) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChallengeEditPage(
            challenge: challenge,
            onSave: (Challenge updatedChallenge) {
              challengeProvider.updateChallenge(updatedChallenge);
            },
          ),
        ),
      );
    }

    void _deleteChallenge(Challenge challenge) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Challenge löschen'),
            content: Text('Möchten Sie "${challenge.name}" wirklich löschen?'),
            actions: [
              TextButton(
                child: Text('Abbrechen'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text('Löschen'),
                onPressed: () {
                  Navigator.of(context).pop();
                  challengeProvider.deleteChallenge(challenge.id);
                },
              ),
            ],
          );
        },
      );
    }

    return ChallengesView(
      challenges: challengeProvider.challenges,
      onEdit: _editChallenge,
      onDelete: _deleteChallenge,
      onAdd: _addNewChallenge,
    );
  }
}
