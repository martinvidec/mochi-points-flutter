import 'package:flutter/material.dart';

class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey[600],
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Übersicht',
        ),
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
    );
  }
}
