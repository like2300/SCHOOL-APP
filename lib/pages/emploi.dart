import 'package:flutter/material.dart';
import 'package:estim_campus/compos/emploi/days.dart';
import 'package:estim_campus/compos/emploi/cours_timeline.dart';
import 'package:estim_campus/compos/emploi/filter_modal.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class EmploiPage extends StatefulWidget {
  const EmploiPage({super.key});

  @override
  State<EmploiPage> createState() => _EmploiPageState();
}

class _EmploiPageState extends State<EmploiPage> {
  DateTime _selectedDay = DateTime.now();
  late EmploiFilter _filter;

  @override
  void initState() {
    super.initState();
    // Récupérer les filtres par défaut depuis le profil de l'utilisateur
    _filter = EmploiFilter(
      etablissement: StorageService.getString('user_etab') ?? 'Tous',
      niveau: StorageService.getString('user_niveau') ?? 'Tous',
      filiere: StorageService.getString('user_filiere') ?? 'Toutes',
    );
  }

  void _openFilterModal() {
    FilterModal.show(
      context: context,
      currentFilter: _filter,
      onFilterApplied: (filter) {
        setState(() {
          _filter = filter;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text(
          'Emploi du temps',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(
                Icons.tune_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Filtrer',
              style: IconButton.styleFrom(
                backgroundColor: (_filter.etablissement != 'Tous' ||
                        _filter.niveau != 'Tous' ||
                        _filter.filiere != 'Toutes')
                    ? colorScheme.primaryContainer
                    : Colors.transparent,
              ),
              onPressed: _openFilterModal,
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélecteur de jours
                Days(
                  onDaySelected: (date) {
                    setState(() {
                      _selectedDay = date;
                    });
                  },
                ),

                const SizedBox(height: 24),

                // En-tête et Timeline avec animation de transition
                TweenAnimationBuilder(
                  key: ValueKey<DateTime>(_selectedDay),
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, (1 - value) * 20),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 16),
                        child: Text(
                          _getFormattedDayHeader(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      CoursTimeline(
                        selectedDate: _selectedDay,
                        etablissement: _filter.etablissement,
                        niveau: _filter.niveau,
                        filiere: _filter.filiere,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Formate l'en-tête (ex: "Lundi 15 Janvier")
  String _getFormattedDayHeader() {
    const jours = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche'
    ];
    const mois = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    return "${jours[_selectedDay.weekday - 1]} ${_selectedDay.day} ${mois[_selectedDay.month - 1]}";
  }
}
