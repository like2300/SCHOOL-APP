import 'package:flutter/material.dart';

class NavbarCompo extends StatefulWidget {
  final int selectedIndex;
  const NavbarCompo({super.key, this.selectedIndex = 0});

  @override
  State<NavbarCompo> createState() => _NavbarCompoState();
}

class _NavbarCompoState extends State<NavbarCompo> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    // SÉCURITÉ : Flutter crash si selectedIndex est < 0 ou > 2.
    // .clamp(0, 2) force la valeur à rester entre 0 et 2.
    _selectedIndex = widget.selectedIndex.clamp(0, 2);
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/app');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Si la largeur est supérieure à 800px (PC / Grande Tablette)
        if (constraints.maxWidth >= 800) {
          return _buildSideBar(colorScheme);
        }
        // Sinon (Mobile / Petite Tablette)
        return _buildBottomNav(colorScheme);
      },
    );
  }

  /// SIDEBAR MODERNE POUR PC
  Widget _buildSideBar(ColorScheme colorScheme) {
    return NavigationRail(
      selectedIndex: _selectedIndex,
      onDestinationSelected: _onItemTapped,
      backgroundColor: colorScheme.surface, // S'adapte au mode sombre
      elevation: 2,
      minWidth: 72,
      labelType: NavigationRailLabelType.all, // Affiche l'icône ET le texte
      // Style de l'indicateur de sélection (Pilule moderne)
      indicatorShape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(16),
          right: Radius.circular(16),
        ),
      ),
      indicatorColor: colorScheme.primaryContainer,
      selectedIconTheme:
          IconThemeData(color: colorScheme.onPrimaryContainer, size: 24),
      unselectedIconTheme:
          IconThemeData(color: colorScheme.onSurfaceVariant, size: 24),
      selectedLabelTextStyle: TextStyle(
        color: colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Accueil'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.apps_outlined),
          selectedIcon: Icon(Icons.apps_rounded),
          label: Text('Apps'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('Profil'),
        ),
      ],
    );
  }

  /// BARRE DE NAVIGATION MODERNE POUR MOBILE
  Widget _buildBottomNav(ColorScheme colorScheme) {
    return SafeArea(
      bottom: true,
      child: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onItemTapped,
        backgroundColor: colorScheme.surface,
        elevation: 2,
        height: 65, // Hauteur confortable pour le tactile
        animationDuration:
            const Duration(milliseconds: 400), // Animation fluide
        indicatorShape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.all(Radius.circular(16)), // Pilule arrondie
        ),
        indicatorColor: colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.apps_outlined),
            selectedIcon: Icon(Icons.apps_rounded),
            label: 'Apps',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
