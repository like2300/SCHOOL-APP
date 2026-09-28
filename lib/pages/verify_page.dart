import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class VerifyPage extends StatefulWidget {
  final int? inscriptionId;
  const VerifyPage({super.key, this.inscriptionId});

  @override
  State<VerifyPage> createState() => _VerifyPageState();
}

class _VerifyPageState extends State<VerifyPage> {
  final TextEditingController _idController = TextEditingController();
  Map<String, dynamic>? _inscription;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.inscriptionId != null) {
      _idController.text = widget.inscriptionId.toString();
      _fetchInscription(widget.inscriptionId!);
    }
  }

  Future<void> _fetchInscription(int id) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _inscription =
          null; // Réinitialise pour relancer l'animation au prochain résultat
    });

    try {
      final data = await ApiService.getInscription(id);
      if (data != null) {
        if (data['available'] == true) {
          setState(() => _inscription = data['data']);
        } else {
          setState(() => _error =
              data['error'] ?? "Aucune inscription trouvée avec l'ID #$id.");
        }
      } else {
        setState(() => _error = "Impossible de contacter le serveur.");
      }
    } catch (e) {
      setState(() => _error = "Une erreur inattendue est survenue.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onSearch() {
    String idStr = _idController.text.trim();
    if (idStr.isEmpty) return;

    idStr = idStr.replaceAll('#', '');
    final id = int.tryParse(idStr);

    if (id == null) {
      setState(() {
        _error = "Veuillez entrer un numéro de dossier valide.";
        _inscription = null;
      });
      return;
    }
    _fetchInscription(id);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('Vérification Inscription',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        // Compatible PC : Limite la largeur
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 550),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icône d'en-tête
                Icon(Icons.folder_shared_outlined,
                    size: 60, color: colorScheme.primary.withOpacity(0.8)),
                const SizedBox(height: 16),
                Text(
                  "Vérifiez votre statut d'inscription",
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  "Entrez votre numéro de dossier pour voir l'état de votre demande.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: colorScheme.onSurfaceVariant, height: 1.5),
                ),
                const SizedBox(height: 32),

                // BARRE DE RECHERCHE MODERNE
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _idController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: "Ex: 42",
                            prefixIcon: Icon(Icons.numbers_rounded,
                                color: colorScheme.onSurfaceVariant),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                          onSubmitted: (_) => _onSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Bouton de recherche avec animation de switch
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                          child: _isLoading
                              ? SizedBox(
                                  key: const ValueKey('loading'),
                                  width: 48,
                                  height: 48,
                                  child: CircularProgressIndicator(
                                      color: colorScheme.primary,
                                      strokeWidth: 3),
                                )
                              : IconButton(
                                  key: const ValueKey('button'),
                                  icon: Icon(Icons.arrow_forward_rounded,
                                      color: colorScheme.onPrimary),
                                  style: IconButton.styleFrom(
                                    backgroundColor: colorScheme.primary,
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(48, 48),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                  ),
                                  onPressed: _onSearch,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // CONTENU DYNAMIQUE (Erreur ou Succès)
                if (_error != null) _buildErrorAnimated(_error!, colorScheme),
                if (_inscription != null)
                  _buildSuccessCardAnimated(colorScheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- ANIMATION D'ERREUR ---
  Widget _buildErrorAnimated(String msg, ColorScheme colorScheme) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
              offset: Offset(0, (1 - value) * 20), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: colorScheme.error),
            const SizedBox(width: 16),
            Expanded(
                child: Text(msg,
                    style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                        height: 1.4))),
          ],
        ),
      ),
    );
  }

  // --- ANIMATION DE SUCCÈS PRINCIPALE ---
  Widget _buildSuccessCardAnimated(ColorScheme colorScheme) {
    return TweenAnimationBuilder(
      key: ValueKey(_inscription?['id']),
      tween: Tween(begin: 0.9, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, double scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border:
              Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            // ZONE PHOTO ET BADGE
            Stack(
              clipBehavior: Clip.none,
              children: [
                _buildPhoto(colorScheme),
                // Badge animé
                Positioned(
                  bottom: -10,
                  right: 0,
                  child: TweenAnimationBuilder(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.elasticOut,
                    builder: (context, double val, child) {
                      return Transform.scale(scale: val, child: child);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: colorScheme.secondary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.verified_rounded,
                              color: colorScheme.onSecondary, size: 18),
                          const SizedBox(width: 6),
                          Text("ENREGISTRÉ",
                              style: TextStyle(
                                  color: colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // NOM COMPLET
            Text(
              "${_inscription!['first_name'] ?? ''} ${_inscription!['last_name'] ?? ''}",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface),
            ),
            const SizedBox(height: 24),

            // GRILLE D'INFORMATIONS ANIMÉES
            _buildAnimatedRow(0, Icons.school_rounded, "Établissement",
                _inscription!['target_etablissement'] ?? "—", colorScheme),
            _buildAnimatedRow(
                1,
                Icons.auto_awesome, // ✅ CORRIGÉ ICI
                "Cycle & Filière",
                "${_inscription!['choix_cycle'] ?? ''} - ${_inscription!['choix_filiere'] ?? ''}",
                colorScheme),
            _buildAnimatedRow(
                2,
                Icons.calendar_month_rounded,
                "Année Académique",
                _inscription!['annee_academique'] ?? "2025-2026",
                colorScheme),
            _buildAnimatedRow(3, Icons.schedule_rounded, "Date d'inscription",
                _formatDate(_inscription!['created_at']), colorScheme),
            // Matricule généré à la validation -> injection directe vers Résultats.
            if ((_inscription!['statut'] ?? '') == 'VALIDEE' &&
                (_inscription!['matricule'] ?? '').toString().isNotEmpty)
              _buildMatriculeBlock(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMatriculeBlock(ColorScheme colorScheme) {
    final matricule = _inscription!['matricule'].toString();
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.secondary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.badge_rounded, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text('MATRICULE : $matricule',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              // Injecte le matricule dans Résultats : pré-rempli + recherche auto.
              StorageService.setString('user_matricule', matricule);
              Navigator.pushNamed(context, '/resultats');
            },
            icon: const Icon(Icons.arrow_forward_rounded),
            label: const Text('VOIR MES RÉSULTATS'),
          ),
        ],
      ),
    );
  }
  // --- WIDGETS UTILITAIRES ---

  Widget _buildPhoto(ColorScheme colorScheme) {
    final photoUrl = ApiService.formatImageUrl(_inscription?['photo']);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.primary, width: 3),
        boxShadow: [
          BoxShadow(
              color: colorScheme.primary.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: ClipOval(
        child: photoUrl != null
            ? Image.network(photoUrl,
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) =>
                    Icon(Icons.person, size: 60, color: colorScheme.outline))
            : Icon(Icons.person, size: 60, color: colorScheme.outline),
      ),
    );
  }

  // Ligne d'information avec animation décalée (Staggered Animation)
  Widget _buildAnimatedRow(int index, IconData icon, String title, String value,
      ColorScheme colorScheme) {
    return TweenAnimationBuilder(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(
          milliseconds: 400 +
              (index * 100)), // Chaque ligne apparait 100ms après la précédente
      curve: Curves.easeOut,
      builder: (context, double value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
                (1 - value) * 20, 0), // Glisse de la gauche vers la droite
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: colorScheme.primaryContainer, shape: BoxShape.circle),
              child:
                  Icon(icon, size: 20, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "—";
    try {
      final date = DateTime.parse(dateStr);
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return dateStr;
    }
  }
}
