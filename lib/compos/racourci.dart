import 'package:flutter/material.dart';

class Racourcicompo extends StatefulWidget {
  const Racourcicompo({
    super.key,
    required this.text,
    required this.icon,
    this.color, // Si null : couleur principale du thème (DB)
    this.onTap, // Fonction au clic
  });

  final String text;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  State<Racourcicompo> createState() => _RacourcicompoState();
}

class _RacourcicompoState extends State<Racourcicompo> {
  @override
  Widget build(BuildContext context) {
    final Color c = widget.color ?? Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: widget.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(150),
              border: Border.all(
                color: c.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 28,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            widget.text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
