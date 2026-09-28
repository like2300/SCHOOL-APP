import 'package:flutter/material.dart';
import 'package:estim_campus/compos/indispo.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/school_service.dart';

class SidebarCompo extends StatefulWidget {
  final int selectedIndex;
  const SidebarCompo({super.key, required this.selectedIndex});

  @override
  State<SidebarCompo> createState() => _SidebarCompoState();
}

class _SidebarCompoState extends State<SidebarCompo> {
  String? _logoUrl;
  String _appName = 'Estim Campus';

  @override
  void initState() {
    super.initState();
    // Nom de l'école de l'étudiant connecté en priorité.
    _appName = SchoolService.name;
    _loadBranding();
  }

  /// Logo + nom modifiables depuis /admin/ (Logo / Branding de l'app).
  Future<void> _loadBranding() async {
    try {
      // Logo de l'école de l'étudiant (depuis /api/etablissements/).
      final school = await SchoolService.fetchSchool();
      if (!mounted) return;
      final schoolLogo = SchoolService.logoUrl;
      if (school != null && schoolLogo != null) {
        setState(() {
          _logoUrl = schoolLogo;
          _appName = SchoolService.name;
        });
        return;
      }
      final branding = await ApiService.getBranding();
      if (!mounted || branding == null) return;
      final raw = (branding['logo_display'] ?? branding['logo'] ?? '').toString();
      setState(() {
        _logoUrl = raw.isNotEmpty ? ApiService.formatImageUrl(raw) : null;
        // L'école connectée garde la priorité sur le branding global.
        if (!SchoolService.hasSchool) {
          final name = (branding['app_name'] ?? '').toString();
          if (name.isNotEmpty) _appName = name;
        }
      });
    } catch (_) {}
  }

  void _onItemTapped(BuildContext context, int index) {
    if (widget.selectedIndex == index) return;

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
      case 3:
        Navigator.pushNamed(context, '/aide');
        break;
      case 4:
        IndispoCompo.show(context: context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: double.infinity,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 40),
          _logoUrl != null && _logoUrl!.isNotEmpty
              ? Image.network(
                  _logoUrl!,
                  height: 80,
                  errorBuilder: (context, error, stackTrace) =>
                      Image.asset('assets/imgs/logo.png', height: 80),
                )
              : Image.asset('assets/imgs/logo.png', height: 80),
          const SizedBox(height: 8),
          Text(
            _appName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 40),
          _buildSidebarItem(context, 0, Icons.home, Icons.home_outlined, 'Accueil'),
          _buildSidebarItem(context, 1, Icons.apps, Icons.apps_outlined, 'Apps'),
          _buildSidebarItem(context, 2, Icons.settings, Icons.settings_outlined, 'Paramètres'),
          _buildSidebarItem(context, 3, Icons.help, Icons.help_outline, 'Aide'),
          _buildSidebarItem(context, 4, Icons.info_outline, Icons.info_outline, 'Indisponible'),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(BuildContext context, int index, IconData activeIcon, IconData icon, String label) {
    bool isSelected = widget.selectedIndex == index;
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Icon(
        isSelected ? activeIcon : icon,
        color: isSelected ? primary : Colors.black45,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? primary : Colors.black45,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () => _onItemTapped(context, index),
    );
  }
}
