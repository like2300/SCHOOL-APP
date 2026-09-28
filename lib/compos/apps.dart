// lib/compos/apps.dart
import 'package:flutter/material.dart';

class Apps extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String image;
  final VoidCallback? onTap;

  const Apps({
    super.key,
    this.title = 'Application',
    this.description = 'Description',
    this.icon = Icons.apps,
    this.image = 'https://i.pinimg.com/736x/8e/a6/07/8ea607e34506a60c35373011540f02b7.jpg',
    this.onTap,
  });

  @override
  State<Apps> createState() => _AppsState();
}

class _AppsState extends State<Apps> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: Image.network(
                widget.image,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(color: Theme.of(context).colorScheme.secondary.withOpacity(0.12));
                },
              ),
            ),

            // Overlay sombre
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // Icône à gauche
            Positioned(
              top: 16,
              left: 16,
              child: CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white,
                child: Icon(widget.icon, color: Theme.of(context).colorScheme.secondary, size: 25),
              ),
            ),

            // Flèche à droite
            Positioned(
              top: 20,
              right: 16,
              child: Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

            // Titre et description en bas
            Positioned(
              bottom: 16,
              left: 16,
              right: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    widget.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
