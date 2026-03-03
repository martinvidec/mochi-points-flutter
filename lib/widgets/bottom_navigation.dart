import 'dart:ui';

import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../theme/app_colors.dart';

/// Navigation item configuration
class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

/// Gaming-themed bottom navigation with role-based tabs
class BottomNavigation extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserRole role;
  final int pendingApprovals;
  final int pendingRewards;

  const BottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.role,
    this.pendingApprovals = 0,
    this.pendingRewards = 0,
  });

  List<NavItem> get _items {
    if (role == UserRole.child) {
      return [
        const NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
        ),
        const NavItem(
          icon: Icons.shield_outlined,
          activeIcon: Icons.shield,
          label: 'Quests',
        ),
        NavItem(
          icon: Icons.card_giftcard_outlined,
          activeIcon: Icons.card_giftcard,
          label: 'Rewards',
          badgeCount: pendingRewards > 0 ? pendingRewards : null,
        ),
        const NavItem(
          icon: Icons.storefront_outlined,
          activeIcon: Icons.storefront,
          label: 'Shop',
        ),
        const NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profil',
        ),
      ];
    } else {
      return [
        const NavItem(
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          label: 'Home',
        ),
        const NavItem(
          icon: Icons.shield_outlined,
          activeIcon: Icons.shield,
          label: 'Quests',
        ),
        NavItem(
          icon: Icons.card_giftcard_outlined,
          activeIcon: Icons.card_giftcard,
          label: 'Rewards',
          badgeCount: pendingRewards > 0 ? pendingRewards : null,
        ),
        NavItem(
          icon: Icons.check_circle_outline,
          activeIcon: Icons.check_circle,
          label: 'Approve',
          badgeCount: pendingApprovals > 0 ? pendingApprovals : null,
        ),
        const NavItem(
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          label: 'Profil',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withAlpha(153),
            border: Border(
              top: BorderSide(
                color: Colors.white.withAlpha(38),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(_items.length, (index) {
                  return _NavBarItem(
                    item: _items[index],
                    isSelected: currentIndex == index,
                    onTap: () => onTap(index),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Glow effect for selected item
                if (isSelected)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryStart.withAlpha(128),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                // Icon container
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isSelected
                        ? LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Icon(
                    isSelected ? item.activeIcon : item.icon,
                    size: 24,
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                // Badge
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: _Badge(count: item.badgeCount!),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primaryStart : AppColors.textSecondary,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryStart, AppColors.primaryEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryStart.withAlpha(128),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
