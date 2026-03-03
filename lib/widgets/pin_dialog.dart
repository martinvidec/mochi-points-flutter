import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';

/// A modal dialog for entering a 4-digit PIN.
///
/// Returns the entered PIN string, or null if cancelled.
class PinDialog extends StatefulWidget {
  const PinDialog({super.key});

  /// Show the PIN dialog and return the entered PIN or null.
  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black87,
      builder: (_) => const PinDialog(),
    );
  }

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  final List<String> _digits = [];
  static const int _pinLength = 4;

  void _addDigit(String digit) {
    if (_digits.length >= _pinLength) return;
    HapticFeedback.lightImpact();
    setState(() {
      _digits.add(digit);
    });
    if (_digits.length == _pinLength) {
      // Small delay so the user sees the last dot fill in
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          Navigator.of(context).pop(_digits.join());
        }
      });
    }
  }

  void _removeDigit() {
    if (_digits.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() {
      _digits.removeLast();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withAlpha(26),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'PIN eingeben',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (index) {
                  final filled = index < _digits.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? AppColors.teal : Colors.transparent,
                      border: Border.all(
                        color: filled
                            ? AppColors.teal
                            : AppColors.textSecondary,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Number pad
              ..._buildNumberPad(),
              const SizedBox(height: 8),

              // Cancel button
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: Text(
                  'Abbrechen',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNumberPad() {
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'del'],
    ];

    return rows.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((key) {
            if (key.isEmpty) {
              return const SizedBox(width: 72, height: 56);
            }
            if (key == 'del') {
              return _buildKey(
                child: const Icon(
                  Icons.backspace_outlined,
                  color: Colors.white,
                  size: 22,
                ),
                onTap: _removeDigit,
              );
            }
            return _buildKey(
              child: Text(
                key,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onTap: () => _addDigit(key),
            );
          }).toList(),
        ),
      );
    }).toList();
  }

  Widget _buildKey({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 56,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
