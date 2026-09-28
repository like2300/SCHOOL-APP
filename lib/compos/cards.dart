import 'package:flutter/material.dart';

class Cards extends StatefulWidget {
  final String name;
  final String email;
  final String image;
  final IconData avatarIcon;
  final VoidCallback? onTap;

  const Cards({
    super.key,
    this.name = 'John Doe',
    this.email = 'john.doe@example.com',
    this.image = 'assets/imgs/logo.png',
    this.avatarIcon = Icons.person,
    this.onTap,
  });

  @override
  State<Cards> createState() => _CardsState();
}

class _CardsState extends State<Cards> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap ?? () {
        print('${widget.name} cliquée');
      },
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: widget.image.startsWith('http')
                    ? Image.network(
                        widget.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.blue.shade50);
                        },
                      )
                    : Image.asset(
                        widget.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(color: Colors.blue.shade50);
                        },
                      ),
              ),
            ),

            // Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
            ),

            // Avatar
            Positioned(
              top: 16,
              left: 16,
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(widget.avatarIcon, color: Colors.blue, size: 28),
              ),
            ),

            // Flèche
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

            // Nom et email
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.email, size: 11, color: Colors.white70),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.email,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
