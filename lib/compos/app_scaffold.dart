import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:estim_campus/compos/sidebar.dart';

class AppScaffold extends StatefulWidget {
  final Widget body;
  final int selectedIndex;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBar;

  const AppScaffold({
    super.key,
    required this.body,
    required this.selectedIndex,
    this.bottomNavigationBar,
    this.appBar,
  });

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  DateTime? _lastPressedAt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.selectedIndex == -1, // Autorise le retour pour les sous-pages (ex: examens)
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // Gestion Facebook-style : si on n'est pas sur l'accueil, on y retourne
        if (widget.selectedIndex > 0) {
          Navigator.pushReplacementNamed(context, '/home');
        } 
        // Si on est déjà sur l'accueil, on demande confirmation pour quitter
        else if (widget.selectedIndex == 0) {
          final now = DateTime.now();
          if (_lastPressedAt == null ||
              now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
            _lastPressedAt = now;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Appuyez à nouveau pour quitter l\'application'),
                duration: Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
              ),
            );
          } else {
            // Quitter réellement l'application
            SystemNavigator.pop();
          }
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 900) {
            return Scaffold(
              appBar: widget.appBar,
              body: widget.body,
              bottomNavigationBar: widget.bottomNavigationBar,
            );
          } else {
            return Scaffold(
              body: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SidebarCompo(selectedIndex: widget.selectedIndex),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: Scaffold(
                      appBar: widget.appBar,
                      body: widget.body,
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
