import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

class UserAvatarButton extends StatelessWidget {
  final User user;
  final bool isSelected;
  final VoidCallback onTap;

  const UserAvatarButton({
    super.key,
    required this.user,
    this.isSelected = false,
    required this.onTap,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 3,
                    )
                  : null,
            ),
            child: CircleAvatar(
              radius: 38,
              backgroundColor: user.isParent
                  ? AppColors.rarityRare.withAlpha(102)
                  : AppColors.success.withAlpha(102),
              backgroundImage:
                  user.avatarUrl != null ? NetworkImage(user.avatarUrl!) : null,
              child: user.avatarUrl == null
                  ? Text(
                      _getInitials(user.name),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: user.isParent
                  ? AppColors.rarityRare.withAlpha(51)
                  : AppColors.success.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              user.isParent ? 'Eltern' : 'Kind',
              style: TextStyle(
                fontSize: 12,
                color: user.isParent ? AppColors.rarityRare : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
