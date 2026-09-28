import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class CalendrierAcademiquePage extends StatefulWidget {
  const CalendrierAcademiquePage({super.key});

  @override
  State<CalendrierAcademiquePage> createState() =>
      _CalendrierAcademiquePageState();
}

class _CalendrierAcademiquePageState extends State<CalendrierAcademiquePage> {
  List<dynamic> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getCalendrier();
    // Tri des événements par date de début (du plus proche au plus lointain)
    data.sort(
        (a, b) => (a['date_debut'] ?? '').compareTo(b['date_debut'] ?? ''));
    setState(() {
      _events = data;
      _isLoading = false;
    });
  }

  String _formatDate(String dateStr) {
    try {
      final DateTime dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy', 'fr_FR').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  // Regroupe les événements par "Mois Année" (ex: "Janvier 2024")
  Map<String, List<dynamic>> _groupEventsByMonth() {
    final Map<String, List<dynamic>> groupedEvents = {};
    for (var event in _events) {
      try {
        final DateTime dt = DateTime.parse(event['date_debut']);
        // Format "Janvier 2024"
        String key = DateFormat('MMMM yyyy', 'fr_FR').format(dt);
        key = key.replaceFirst(
            key[0], key[0].toUpperCase()); // Met la 1ère lettre en majuscule
        groupedEvents.putIfAbsent(key, () => []).add(event);
      } catch (e) {
        groupedEvents.putIfAbsent('Date inconnue', () => []).add(event);
      }
    }
    return groupedEvents;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('Calendrier Académique',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : RefreshIndicator(
              color: colorScheme.primary,
              onRefresh: _fetchEvents,
              child: _events.isEmpty
                  ? _buildEmptyState(colorScheme)
                  : _buildCalendarView(colorScheme),
            ),
    );
  }

  // État vide moderne
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy_rounded,
              size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Aucun événement prévu',
            style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Vue principale avec animation et regroupement
  Widget _buildCalendarView(ColorScheme colorScheme) {
    final groupedEvents = _groupEventsByMonth();

    return Center(
      // Compatible PC : Limite la largeur
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: groupedEvents.entries.map((entry) {
            return _buildMonthSection(entry.key, entry.value, colorScheme);
          }).toList(),
        ),
      ),
    );
  }

  // En-tête du mois (Ex: "Janvier 2024")
  Widget _buildMonthSection(
      String monthYear, List<dynamic> events, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 12),
          child: Text(
            monthYear,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: colorScheme.primary, // En Jaune ESTIM
              letterSpacing: -0.5,
            ),
          ),
        ),
        // Animation d'entrée pour la liste des événements du mois
        TweenAnimationBuilder(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          builder: (context, double value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, (1 - value) * 20), // Slide vers le haut
                child: child,
              ),
            );
          },
          child: Column(
            children: events
                .map((event) => _buildEventCard(event, colorScheme))
                .toList(),
          ),
        ),
        const Divider(height: 32),
      ],
    );
  }

  // Carte d'événement style "Calendrier"
  Widget _buildEventCard(dynamic event, ColorScheme colorScheme) {
    final bool isImportant = event['is_important'] ?? false;
    DateTime? startDate;
    try {
      startDate = DateTime.parse(event['date_debut']);
    } catch (e) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: isImportant
            ? Border.all(color: colorScheme.error.withOpacity(0.3))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Le "Chip" visuel du calendrier (Chiffre + Mois)
            Container(
              width: 64,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isImportant
                    ? colorScheme.error
                    : colorScheme.primary, // Rouge si important, Jaune sinon
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (startDate != null)
                    Text(
                      DateFormat('dd', 'fr_FR').format(startDate),
                      style: TextStyle(
                        color: isImportant
                            ? colorScheme.onError
                            : colorScheme.onPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                  const SizedBox(height: 2),
                  if (startDate != null)
                    Text(
                      DateFormat('MMM', 'fr_FR')
                          .format(startDate)
                          .toUpperCase(),
                      style: TextStyle(
                        color: isImportant
                            ? colorScheme.onError.withOpacity(0.9)
                            : colorScheme.onPrimary.withOpacity(0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),

            // Le contenu de l'événement
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isImportant)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.priority_high_rounded,
                                color: colorScheme.error, size: 16),
                          ),
                        Expanded(
                          child: Text(
                            event['title'] ?? 'Événement',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.schedule_rounded,
                            size: 14, color: colorScheme.onSurfaceVariant),
                        const SizedBox(width: 6),
                        Text(
                          event['date_fin'] != null
                              ? 'Du ${_formatDate(event['date_debut'])} au ${_formatDate(event['date_fin'])}'
                              : 'Le ${_formatDate(event['date_debut'])}',
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    if (event['description'] != null &&
                        event['description'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        event['description'],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
