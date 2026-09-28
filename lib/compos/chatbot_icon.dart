import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';

class ChatbotIcon extends StatefulWidget {
  final VoidCallback onPressed;
  const ChatbotIcon({super.key, required this.onPressed});

  @override
  State<ChatbotIcon> createState() => _ChatbotIconState();
}

class _ChatbotIconState extends State<ChatbotIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // API assistant désactivée/injoignable (et sans cache) : pas de bouton.
    return FutureBuilder<Map<String, dynamic>?>(
      future: ApiService.getAssistant(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final nom = (data['nom'] ?? 'Assistant').toString();
        return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.0 + (0.02 * _animation.value),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.4 * _animation.value),
                  blurRadius: 12 * _animation.value,
                  spreadRadius: 1 * _animation.value,
                ),
                BoxShadow(
                  color: Colors.greenAccent.withOpacity(0.2 * _animation.value),
                  blurRadius: 20 * _animation.value,
                  spreadRadius: 4 * _animation.value,
                ),
              ],
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    Colors.green[900]!, // Vert foncé
                    Colors.greenAccent[700]!, // Vert clair vibrant
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  borderRadius: BorderRadius.circular(30),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          nom,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
      },
    );
  }
}
