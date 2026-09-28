// lib/compos/emploi/filter_modal.dart
import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';

class EmploiFilter {
  final String etablissement;
  final String niveau;
  final String filiere;

  const EmploiFilter({
    required this.etablissement,
    required this.niveau,
    required this.filiere,
  });
}

class FilterModal {
  static void show({
    required BuildContext context,
    required EmploiFilter currentFilter,
    required Function(EmploiFilter) onFilterApplied,
    bool showNiveau = true,
    bool showFiliere = true,
  }) {
    String selectedEtablissement = currentFilter.etablissement;
    String selectedNiveau = currentFilter.niveau;
    String selectedFiliere = currentFilter.filiere;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return FutureBuilder(
          future: Future.wait([
            ApiService.getEtablissements(),
            ApiService.getNiveaux(),
            ApiService.getFilieres(),
          ]),
          builder: (context, AsyncSnapshot<List<List<String>>> snapshot) {
            if (!snapshot.hasData) {
              return Container(height: 200, child: Center(child: CircularProgressIndicator()));
            }

            final etablissements = snapshot.data![0];
            final niveaux = snapshot.data![1];
            final filieres = snapshot.data![2];

            // S'assurer que les valeurs sélectionnées existent dans les listes
            // Et gérer les valeurs par défaut proprement
            selectedEtablissement = etablissements.contains(selectedEtablissement) ? selectedEtablissement : 'Tous';
            selectedNiveau = niveaux.contains(selectedNiveau) ? selectedNiveau : 'Tous';
            selectedFiliere = filieres.contains(selectedFiliere) ? selectedFiliere : 'Toutes';

            return StatefulBuilder(
              builder: (context, setModalState) {
                // Utiliser des variables locales au StatefulBuilder pour le tracking des changements
                return DraggableScrollableSheet(
                  initialChildSize: 0.7,
                  minChildSize: 0.5,
                  maxChildSize: 0.9,
                  expand: false,
                  builder: (context, scrollController) {
                    return SingleChildScrollView(
                      controller: scrollController,
                      child: Container(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
                            SizedBox(height: 20),
                            Text('Filtrer les cours', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(height: 24),
                            _buildLabel('Établissement'),
                            _buildDropdown(value: selectedEtablissement, items: etablissements, onChanged: (v) => setModalState(() => selectedEtablissement = v)),
                            if (showNiveau) ...[
                              SizedBox(height: 20),
                              _buildLabel('Niveau'),
                              _buildDropdown(value: selectedNiveau, items: niveaux, onChanged: (v) => setModalState(() => selectedNiveau = v)),
                            ],
                            if (showFiliere) ...[
                              SizedBox(height: 20),
                              _buildLabel('Filière'),
                              _buildDropdown(value: selectedFiliere, items: filieres, onChanged: (v) => setModalState(() => selectedFiliere = v)),
                            ],
                            SizedBox(height: 32),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => setModalState(() { selectedEtablissement = 'Tous'; selectedNiveau = 'Tous'; selectedFiliere = 'Toutes'; }),
                                    style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    child: Text('Réinitialiser'),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      onFilterApplied(EmploiFilter(etablissement: selectedEtablissement, niveau: selectedNiveau, filiere: selectedFiliere));
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                    child: Text('Appliquer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  static Widget _buildLabel(String text) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54));
  }

  static Widget _buildDropdown({required String value, required List<String> items, required Function(String) onChanged}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[300]!)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.toSet().toList().map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}
