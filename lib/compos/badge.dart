// lib/compos/badge.dart
import 'package:flutter/material.dart';

class BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color badgeColor;  // Couleur du badge personnalisable

  const BadgeIcon({
    super.key,
    required this.icon,
    required this.count,
    required this.onPressed,
    this.backgroundColor,
    this.badgeColor = Colors.red,  // Rouge par défaut
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(icon, color: Colors.black),
          style: backgroundColor != null
              ? IconButton.styleFrom(
                  backgroundColor: backgroundColor,
                  foregroundColor: Colors.black,
                )
              : null,
              onPressed: onPressed,
        ),
        if (count > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              constraints: BoxConstraints(
                minWidth: 25,
                minHeight: 18,
              ),
              decoration: BoxDecoration(
                color: badgeColor,  // Utilise la couleur du badge
                borderRadius: BorderRadius.circular(102),  // Forme pilule
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
