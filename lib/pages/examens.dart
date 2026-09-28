import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/compos/emploi/filter_modal.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class ExamensPage extends StatefulWidget {
  const ExamensPage({super.key});

  @override
  State<ExamensPage> createState() => _ExamensPageState();
}

class _ExamensPageState extends State<ExamensPage>
    with SingleTickerProviderStateMixin {
  late EmploiFilter _filter;
  List<dynamic> _examens = [];
  bool _isLoading = true;
  late AnimationController _staggerController;

  @override
  void initState() {
    super.initState();
    _filter = EmploiFilter(
      etablissement: StorageService.getString('user_etab') ?? 'Tous',
      niveau: StorageService.getString('user_niveau') ?? 'Tous',
      filiere: StorageService.getString('user_filiere') ?? 'Toutes',
    );
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fetchExamens();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  Future<void> _fetchExamens() async {
    setState(() => _isLoading = true);

    final data = await ApiService.getExamens(
      etablissement: _filter.etablissement,
      niveau: _filter.niveau,
      filiere: _filter.filiere,
    );

    setState(() {
      _examens = data;
      _isLoading = false;
    });

    if (_examens.isNotEmpty) {
      _staggerController.forward(from: 0);
    }
  }

  void _openFilterModal() {
    FilterModal.show(
      context: context,
      currentFilter: _filter,
      onFilterApplied: (filter) {
        setState(() => _filter = filter);
        _fetchExamens();
      },
    );
  }

  bool get _hasActiveFilter =>
      _filter.etablissement != 'Tous' ||
      _filter.niveau != 'Tous' ||
      _filter.filiere != 'Toutes';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWide = MediaQuery.of(context).size.width > 900;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.quiz_rounded,
                size: 18,
                color: colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            // Utilisation de Flexible pour éviter le dépassement sur petit écran
            const Flexible(
              child: Text(
                'Planning des Examens',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        // ... le reste de tes actions reste identique
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: _hasActiveFilter
                    ? colorScheme.tertiaryContainer
                    : colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
                border: _hasActiveFilter
                    ? Border.all(
                        color: colorScheme.tertiary.withOpacity(0.3),
                        width: 1.5)
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: _openFilterModal,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: _hasActiveFilter
                              ? colorScheme.onTertiaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                        if (_hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Actif',
                              style: TextStyle(
                                color: colorScheme.onTertiary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              children: [
                if (_isLoading)
                  _buildLoadingState(colorScheme)
                else if (_examens.isEmpty)
                  _buildEmptyState(colorScheme)
                else
                  isWide
                      ? _buildWideTimeline(colorScheme)
                      : _buildMobileTimeline(colorScheme),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  LOADING
  // ═══════════════════════════════════════════
  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: List.generate(3, (index) {
          return Padding(
            padding: EdgeInsets.only(bottom: index < 2 ? 20 : 0),
            child: Container(
              height: 90,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  EMPTY
  // ═══════════════════════════════════════════
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 36,
              color: colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun examen prévu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Aucun examen ne correspond à vos filtres.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  MOBILE TIMELINE
  // ═══════════════════════════════════════════
  Widget _buildMobileTimeline(ColorScheme colorScheme) {
    return Column(
      children: List.generate(_examens.length, (index) {
        return _buildStaggeredItem(
          index,
          _buildExamenCard(_examens[index], colorScheme),
        );
      }),
    );
  }

  // ═══════════════════════════════════════════
  //  WIDE TIMELINE (PC)
  // ═══════════════════════════════════════════
  Widget _buildWideTimeline(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: List.generate(_examens.length, (index) {
          final exam = _examens[index];
          final isLast = index == _examens.length - 1;
          final examColor = _getExamColor(exam, colorScheme);

          return _buildStaggeredItem(
            index,
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Colonne Date/Heure
                SizedBox(
                  width: 80,
                  child: Column(
                    children: [
                      Text(
                        _formatDate(exam['date']),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exam['heure'] ?? '--:--',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Ligne Timeline
                SizedBox(
                  width: 32,
                  child: Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: examColor,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: colorScheme.surface, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: examColor.withOpacity(0.4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 2,
                            decoration: BoxDecoration(
                              color:
                                  colorScheme.outlineVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 20),

                // Carte
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
                    child: _buildExamenCard(exam, colorScheme),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  CARTE EXAMEN
  // ═══════════════════════════════════════════
  Widget _buildExamenCard(dynamic exam, ColorScheme colorScheme,
      {bool isFirst = false, bool isLast = false}) {
    final examColor = _getExamColor(exam, colorScheme);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- LA LIGNE ET LE POINT DE LA TIMELINE ---
          SizedBox(
            width: 24, // Largeur de la colonne timeline
            child: Column(
              children: [
                // Ligne du haut (cachée si c'est le premier élément)
                if (!isFirst)
                  Container(
                      width: 2,
                      height: 16,
                      color: colorScheme.outlineVariant.withOpacity(0.5)),

                // Le Point central
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: examColor,
                    shape: BoxShape.circle,
                    // Ombre colorée subtile pour faire ressortir le point
                    boxShadow: [
                      BoxShadow(
                          color: examColor.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                ),

                // Ligne du bas (cachée si c'est le dernier élément)
                if (!isLast)
                  Expanded(
                    child: Container(
                        width: 2,
                        color: colorScheme.outlineVariant.withOpacity(0.5)),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // --- LA CARTE CONTENU (ÉPURÉE) ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                // Bordure ultra subtile au lieu d'une ombre lourde
                border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LIGNE 1 : Matière + Badge Type
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          exam['matiere'] ?? 'Matière inconnue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (exam['type'] != null) ...[
                        const SizedBox(width: 10),
                        // Badge de type moderne
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: examColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            exam['type'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: examColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 10),

                  // LIGNE 2 : Date et Heure (Bien en évidence)
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        '${_formatDate(exam['date'])} à ${exam['heure'] ?? '--:--'}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // LIGNE 3 : Détails (Salle, Prof, Niveau) sur une ligne fluide
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      if (exam['salle'] != null)
                        _buildDetailText(Icons.meeting_room_outlined,
                            exam['salle'], colorScheme),
                      if (exam['prof'] != null)
                        _buildDetailText(Icons.person_outline_rounded,
                            exam['prof'], colorScheme),
                      if (exam['niveau'] != null)
                        _buildDetailText(
                            Icons.stairs_outlined, exam['niveau'], colorScheme),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget utilitaire ultra épuré pour les détails
  Widget _buildDetailText(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colorScheme.outline),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String type, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        type,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  STAGGER ANIMATION (Flutter natif)
  // ═══════════════════════════════════════════
  Widget _buildStaggeredItem(int index, Widget child) {
    final delay = (index * 0.12).clamp(0.0, 0.8);
    final end = (delay + 0.4).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, _) {
        final t = _staggerController.value;
        final progress = ((t - delay) / (end - delay)).clamp(0.0, 1.0);

        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1.0 - progress) * 16),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ═══════════════════════════════════════════
  //  UTILITAIRES
  // ═══════════════════════════════════════════
  Color _getExamColor(dynamic exam, ColorScheme colorScheme) {
    final type = (exam['type'] ?? '').toLowerCase();
    if (type.contains('tp') || type.contains('pratique')) return Colors.teal;
    if (type.contains('td')) return Colors.orange;
    if (type.contains('partial') || type.contains('partiel'))
      return Colors.deepPurple;
    return colorScheme.tertiary;
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '--/--';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr.length >= 5 ? dateStr.substring(0, 5) : dateStr;
    }
  }
}
