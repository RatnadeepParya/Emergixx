import 'package:flutter/material.dart';

/// Large, high-visibility, stress-tested emergency tap target.
class EmergencyButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final VoidCallback onPressed;
  final bool isPrimary;

  const EmergencyButton({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      elevation: isPrimary ? 6 : 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(18),
        splashColor: Colors.white24,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: isPrimary ? 24 : 18,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: isPrimary ? 32 : 24),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isPrimary ? 22 : 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
