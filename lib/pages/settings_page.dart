import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/auth_service.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:estim_campus/compos/bottom_nav.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _selectedEtab;
  String? _selectedNiveau;
  String? _selectedFiliere;
  String? _matricule;
  bool _notificationsEnabled = true;
  bool _isMatriculeLocked = false;
  final TextEditingController _matriculeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _matriculeController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _selectedEtab = StorageService.getString('user_etab');
      _selectedNiveau = StorageService.getString('user_niveau');
      _selectedFiliere = StorageService.getString('user_filiere');
      _matricule = StorageService.getString('user_matricule');
      _matriculeController.text = _matricule ?? '';
      _isMatriculeLocked = _matricule != null && _matricule!.isNotEmpty;
      _notificationsEnabled =
          StorageService.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    await StorageService.setString('user_etab', _selectedEtab ?? '');
    await StorageService.setString('user_niveau', _selectedNiveau ?? '');
    await StorageService.setString('user_filiere', _selectedFiliere ?? '');
    await StorageService.setString('user_matricule', _matriculeController.text);
    await StorageService.setBool(
        'notifications_enabled', _notificationsEnabled);

    setState(() {
      _isMatriculeLocked = _matriculeController.text.isNotEmpty;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Profil mis à jour avec succès')
          ]),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  Future<void> _generateGuestMatricule() async {
    final String guestMatricule =
        "INV_${DateTime.now().millisecondsSinceEpoch % 10000}";
    setState(() {
      _matriculeController.text = guestMatricule;
    });
    await _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    // Récupération du thème pour s'adapter auclair/sombre
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      selectedIndex: 2,
      appBar: AppBar(
        title: const Text('Mon Profil',
            style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Aide', // Accessibilité
            onPressed: () => Navigator.pushNamed(context, '/aide'),
          ),
        ],
      ),
      bottomNavigationBar: const NavbarCompo(selectedIndex: 2),
      body: FutureBuilder(
        future: Future.wait([
          ApiService.getEtablissements(),
          ApiService.getNiveaux(),
          ApiService.getFilieres(),
        ]),
        builder: (context, AsyncSnapshot<List<List<String>>> snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(color: colorScheme.primary));
          }

          final etabs = snapshot.data![0];
          final nivs = snapshot.data![1];
          final fils = snapshot.data![2];

          String? safeEtab =
              (etabs.contains(_selectedEtab)) ? _selectedEtab : null;
          String? safeNiv =
              (nivs.contains(_selectedNiveau)) ? _selectedNiveau : null;
          String? safeFil =
              (fils.contains(_selectedFiliere)) ? _selectedFiliere : null;

          return Center(
            // --- LE SECRET POUR LE PC : Limiter la largeur ---
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- CARTE 1 : IDENTITE ---
                    _buildSectionCard(
                      context,
                      title: 'Identifiant',
                      icon: Icons.badge_outlined,
                      children: [
                        TextField(
                          controller: _matriculeController,
                          readOnly: _isMatriculeLocked,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2, // Effet "Code" moderne
                          ),
                          decoration: InputDecoration(
                            hintText: 'Ex: 2023001',
                            prefixIcon: Icon(Icons.fingerprint,
                                color: colorScheme.primary),
                            suffixIcon: _isMatriculeLocked
                                ? Container(
                                    margin: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.lock_outline,
                                        size: 18, color: colorScheme.outline),
                                  )
                                : null,
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest
                                .withOpacity(0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (_isMatriculeLocked)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 12.0, left: 12.0),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    size: 14, color: colorScheme.outline),
                                const SizedBox(width: 6),
                                Text(
                                  "Sécurisé. Non modifiable.",
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.outline,
                                      fontStyle: FontStyle.italic),
                                ),
                              ],
                            ),
                          ),
                        if (!_isMatriculeLocked) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _generateGuestMatricule,
                            icon: const Icon(Icons.person_add_alt_1_rounded,
                                size: 18),
                            label: const Text('Continuer en mode Invité'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.tertiary,
                              side: BorderSide(
                                  color: colorScheme.tertiary.withOpacity(0.5)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ]
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- CARTE 2 : PARCOURS ACADEMIQUE ---
                    _buildSectionCard(
                      context,
                      title: 'Parcours Académique',
                      icon: Icons.school_outlined,
                      children: [
                        _buildModernDropdown(
                          context,
                          label: 'Établissement',
                          value: safeEtab,
                          items: etabs,
                          icon: Icons.domain_outlined,
                          onChanged: (v) => setState(() => _selectedEtab = v),
                        ),
                        const SizedBox(height: 16),
                        _buildModernDropdown(
                          context,
                          label: 'Niveau',
                          value: safeNiv,
                          items: nivs,
                          icon: Icons.stairs_outlined,
                          onChanged: (v) => setState(() => _selectedNiveau = v),
                        ),
                        const SizedBox(height: 16),
                        _buildModernDropdown(
                          context,
                          label: 'Filière',
                          value: safeFil,
                          items: fils,
                          icon: Icons.menu_book_outlined,
                          onChanged: (v) =>
                              setState(() => _selectedFiliere = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // --- CARTE 3 : PREFERENCES ---
                    _buildSectionCard(
                      context,
                      title: 'Préférences',
                      icon: Icons.tune_rounded,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Notifications Push'),
                          subtitle: const Text(
                              'Alertes de cours, examens et résultats'),
                          value: _notificationsEnabled,
                          onChanged: (value) {
                            setState(() => _notificationsEnabled = value);
                            StorageService.setBool(
                                'notifications_enabled', value);
                          },
                          activeTrackColor:
                              colorScheme.primary.withOpacity(0.3),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // --- BOUTON VALIDER ---
                    FilledButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Enregistrer les modifications',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    const SizedBox(height: 40), // Espace de sécurité en bas

                    OutlinedButton.icon(
                      onPressed: () async {
                        await AuthService.logout();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/login');
                        }
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Se déconnecter'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(
                            color: colorScheme.error.withOpacity(0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    const SizedBox(height: 40), // Espace de sécurité en bas
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Widget réutilisable pour créer des sections stylisées
  Widget _buildSectionCard(BuildContext context,
      {required String title,
      required IconData icon,
      required List<Widget> children}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de la carte
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
              ),
              const SizedBox(width: 12),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          // Contenu
          ...children,
        ],
      ),
    );
  }

  /// Dropdown moderne utilisant DropdownButtonFormField
  Widget _buildModernDropdown(
    BuildContext context, {
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return DropdownButtonFormField<String>(
      value: (value != null && items.contains(value)) ? value : null,
      hint: Text("Sélectionner $label"),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down_rounded),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.onSurfaceVariant),
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
      ),
      items: items
          .toSet()
          .toList()
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
