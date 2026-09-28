import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';

class CoursTimeline extends StatefulWidget {
  final DateTime selectedDate;
  final String etablissement;
  final String niveau;
  final String filiere;

  const CoursTimeline({
    super.key,
    required this.selectedDate,
    this.etablissement = 'Tous',
    this.niveau = 'Tous',
    this.filiere = 'Toutes',
  });

  @override
  State<CoursTimeline> createState() => _CoursTimelineState();
}

class _CoursTimelineState extends State<CoursTimeline> {
  List<dynamic> _cours = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCours();
  }

  @override
  void didUpdateWidget(CoursTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedDate != widget.selectedDate ||
        oldWidget.etablissement != widget.etablissement ||
        oldWidget.niveau != widget.niveau ||
        oldWidget.filiere != widget.filiere) {
      _fetchCours();
    }
  }

  Future<void> _fetchCours() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getCours(
      day: widget.selectedDate.weekday,
      etablissement: widget.etablissement,
      niveau: widget.niveau,
      filiere: widget.filiere,
    );
    if (mounted) {
      setState(() {
        _cours = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool hasActiveFilter = widget.etablissement != 'Tous' ||
        widget.niveau != 'Tous' ||
        widget.filiere != 'Toutes';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Indicateur subtil des filtres actifs (au lieu de l'ancien gros bloc de texte)
        if (hasActiveFilter)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.filter_list_rounded,
                    size: 16, color: colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Text(
                  _getActiveFiltersText(),
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),

        // Chargement
        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          )

        // État vide
        else if (_cours.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.event_busy_rounded,
                      size: 60, color: colorScheme.outlineVariant),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun cours prévu',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Profitez de votre journée !',
                    style: TextStyle(fontSize: 13, color: colorScheme.outline),
                  ),
                ],
              ),
            ),
          )

        // La Timeline
        else
          ..._cours.asMap().entries.map((entry) {
            final index = entry.key;
            final cour = entry.value;
            return _buildTimelineItem(
              cour,
              colorScheme,
              isFirst: index == 0,
              isLast: index == _cours.length - 1,
            );
          }),
      ],
    );
  }

  // Génère le texte des filtres actifs
  String _getActiveFiltersText() {
    final filters = <String>[];
    if (widget.etablissement != 'Tous') filters.add(widget.etablissement);
    if (widget.niveau != 'Tous') filters.add(widget.niveau);
    if (widget.filiere != 'Toutes') filters.add(widget.filiere);
    return filters.join(' • ');
  }

  // Widget d'un élément de la timeline
  Widget _buildTimelineItem(Map<String, dynamic> cour, ColorScheme colorScheme,
      {required bool isFirst, required bool isLast}) {
    // Extrait l'heure de début (ex: "08:00" à partir de "08:00 - 10:00")
    final String startTime =
        cour['heure']?.toString().split(' - ')[0] ?? '--:--';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- COLONNE TIMELINE (Heure, Point, Ligne) ---
          SizedBox(
            width: 50,
            child: Column(
              children: [
                Text(
                  startTime,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.secondary, // Vert
                  ),
                ),
                const SizedBox(height: 6),

                // Ligne du haut
                if (!isFirst)
                  Container(
                      width: 2,
                      height: 12,
                      color: colorScheme.outlineVariant.withOpacity(0.5)),

                // Le Point
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary, // Vert
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                          color: colorScheme.secondary.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                ),

                // Ligne du bas (s'étire pour correspondre à la hauteur de la carte)
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: colorScheme.outlineVariant.withOpacity(0.5),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // --- CARTE DU COURS ---
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ligne 1 : Matière + Niveau
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          cour['matiere'] ?? 'Matière inconnue',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (cour['niveau'] != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            cour['niveau'],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Ligne 2 : Détails (Salle, Prof, Établissement)
                  Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    children: [
                      if (cour['heure'] != null)
                        _buildDetail(
                            Icons.schedule_rounded, cour['heure'], colorScheme,
                            highlight: true),
                      if (cour['salle'] != null)
                        _buildDetail(Icons.meeting_room_outlined, cour['salle'],
                            colorScheme),
                      if (cour['prof'] != null)
                        _buildDetail(Icons.person_outline_rounded, cour['prof'],
                            colorScheme),
                      if (cour['etablissement'] != null)
                        _buildDetail(Icons.domain_outlined,
                            cour['etablissement'], colorScheme),
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

  // Widget réutilisable pour les détails
  Widget _buildDetail(IconData icon, String text, ColorScheme colorScheme,
      {bool highlight = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: highlight ? colorScheme.secondary : colorScheme.outline),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: highlight
                ? colorScheme.secondary
                : colorScheme.onSurfaceVariant,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
