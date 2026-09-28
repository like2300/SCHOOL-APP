import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/school_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class AidePage extends StatefulWidget {
  const AidePage({super.key});

  @override
  State<AidePage> createState() => _AidePageState();
}

class _AidePageState extends State<AidePage> {
  Map<String, dynamic>? _config;
  Map<String, dynamic>? _branding;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      // Logo + nom de l'école depuis l'API branding, le reste depuis la fiche.
      final results = await Future.wait([
        ApiService.getBranding(),
        ApiService.getFormConfig(),
      ]);
      if (mounted) {
        setState(() {
          _branding = results[0];
          _config = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Logo de l'école depuis l'API (branding actif), sans passer par les assets.
  String? get _logoUrl {
    final b = _branding?['logo_display']?.toString();
    if (b != null && b.isNotEmpty) return b;
    final f = _config?['logo']?.toString();
    if (f != null && f.isNotEmpty) return ApiService.formatImageUrl(f);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Récupération du thème pour s'adapter au mode clair/sombre
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('À propos'),
        centerTitle: true,
        // L'AppBar s'intègre mieux sans bordure inférieure en mode épuré
        surfaceTintColor: Colors.transparent,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : SingleChildScrollView(
              physics:
                  const BouncingScrollPhysics(), // Effet rebond iOS très moderne
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                children: [
                  // --- LOGO ---
                  Container(
                    height: 110,
                    width: 110,
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _logoUrl != null
                          ? Image.network(
                              _logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Image.asset('assets/imgs/logo.png',
                                      fit: BoxFit.contain),
                            )
                          : Image.asset('assets/imgs/logo.png',
                              fit: BoxFit.contain),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- NOM & VERSION ---
                  Text(
                    _branding?['app_name'] ??
                        _config?['school_name'] ??
                        'ESTIM CAMPUS',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.surfaceContainerHighest.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Version 1.0.0',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40), // Espace important pour séparer

                  // --- SECTION DESCRIPTION ---
                  _buildModernSection(
                    context: context,
                    title: 'Description',
                    content:
                        '${SchoolService.name} est l\'application officielle de ton école. Elle permet aux étudiants de suivre leur cursus académique, consulter leurs emplois du temps, leurs résultats et recevoir des notifications importantes.',
                  ),

                  const SizedBox(height: 16),

                  // --- SECTION DÉVELOPPEURS ---
                  _buildModernSection(
                    context: context,
                    title: 'Développeurs du Projet',
                    content:
                        'Conçu et développé par l\'équipe technique d\'ESTIM.\n\nResponsable Tech : ELENGA OMER FILS\nDéveloppeur : EBANA PLAMEDI',
                  ),

                  const SizedBox(height: 16),

                  // --- SECTION CONTACT & SUPPORT ---
                  _buildModernSection(
                    context: context,
                    title: 'Contact & Support',
                    content:
                        'Email : support@estim-ecole.com\nTéléphone : ${_config?['school_phone'] ?? '+242 061167676'}',
                    trailing: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(_config?['school_website'] ??
                              'https://www.estim-ecole.com');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url,
                                mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.language, size: 16),
                        label: const Text('Site web',
                            style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colorScheme.primary,
                          side: BorderSide(
                              color: colorScheme.outline.withOpacity(0.5)),
                          shape: StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  // --- FOOTER ---
                  Text(
                    'Propulsé par ${SchoolService.name} Tech',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${DateTime.now().year} ${SchoolService.name}. Tous droits réservés.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  /// Widget réutilisable pour les cartes épurées
  Widget _buildModernSection({
    required BuildContext context,
    required String title,
    required String content,
    Widget? trailing,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface, // S'adapte au mode sombre
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), // Ombre très très légère
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Petit trait de couleur à gauche du titre (Très tendance)
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: colorScheme.primary, width: 3),
                  ),
                ),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colorScheme
                      .onSurfaceVariant, // Gris élégant au lieu du noir brut
                ),
          ),
        ],
      ),
    );
  }
}
