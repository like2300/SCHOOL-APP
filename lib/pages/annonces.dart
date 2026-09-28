import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/school_service.dart';
import 'package:intl/intl.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class AnnoncesPage extends StatefulWidget {
  const AnnoncesPage({super.key});

  @override
  State<AnnoncesPage> createState() => _AnnoncesPageState();
}

class _AnnoncesPageState extends State<AnnoncesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'Tous';
  List<dynamic> _annonces = [];
  bool _isLoading = true;

  final List<String> _filters = [
    'Tous',
    'Événements',
    'Cours',
    'Examens',
    'Divers'
  ];

  @override
  void initState() {
    super.initState();
    _fetchAnnonces();
  }

  Future<void> _fetchAnnonces() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getAnnonces();
    if (mounted) {
      setState(() {
        _annonces = data;
        _isLoading = false;
      });
    }
  }

  void _sharePost(Map<String, dynamic> post) async {
    final text =
        '📢 ${post['title']}\n\n${post['description']}\n\nPartagé depuis ${SchoolService.name}';

    await Share.share(
      text,
      subject: post['title'],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final DateTime dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('dd/MM/yyyy à HH:mm').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final filteredAnnonces = _annonces.where((a) {
      final matchesFilter =
          _selectedFilter == 'Tous' || a['type'] == _selectedFilter;
      final matchesSearch = _searchController.text.isEmpty ||
          a['title']!
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()) ||
          a['description']!
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('Annonces',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded,
                color: colorScheme.onSurfaceVariant),
            onPressed: _fetchAnnonces,
          ),
        ],
      ),
      body: Column(
        children: [
          // ZONE DE RECHERCHE ET FILTRES
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: colorScheme.surface,
            child: Column(
              children: [
                // Barre de recherche moderne
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Rechercher une annonce...',
                    prefixIcon: Icon(Icons.search_rounded,
                        color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor:
                        colorScheme.surfaceContainerHighest.withOpacity(0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 0), // Rend le champ plus fin
                  ),
                ),
                const SizedBox(height: 12),

                // Filtres animés (ChoiceChips)
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _filters.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final filter = _filters[index];
                      final isSelected = _selectedFilter == filter;
                      return ChoiceChip(
                        label: Text(
                          filter,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedFilter = filter);
                        },
                        // Configuration des couleurs dynamiques
                        selectedColor:
                            colorScheme.primary, // Jaune si sélectionné
                        labelStyle: TextStyle(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurfaceVariant,
                        ),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        side: BorderSide.none,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        showCheckmark:
                            false, // Enlève la coche pour garder l'interface épurée
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // SÉPARATEUR SUBTIL
          Divider(
              height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),

          // LISTE DES ANNONCES
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: colorScheme.primary))
                : RefreshIndicator(
                    color: colorScheme.primary,
                    onRefresh: _fetchAnnonces,
                    child: filteredAnnonces.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredAnnonces.length,
                            itemBuilder: (context, index) => _buildPostCard(
                                filteredAnnonces[index], colorScheme),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // État vide moderne
  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined,
              size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Aucune annonce trouvée',
            style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // Carte d'annonce moderne (Style Réseau Social)
  Widget _buildPostCard(Map<String, dynamic> annonce, ColorScheme colorScheme) {
    final String? rawUrl = (annonce['image_display'] != null &&
            annonce['image_display'].toString().isNotEmpty)
        ? annonce['image_display']
        : annonce['image_url'];

    final String? displayImage = ApiService.formatImageUrl(rawUrl);
    final bool hasImage = displayImage != null && displayImage.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      // Design "Flat" (pas d'ombre, juste une fine bordure) -> C'est le standard 2024
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.5)),
      ),
      // Utilise ClipRRect pour que l'image respecte les bordures arrondies
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // EN-TÊTE (Avatar, Nom, Date, Type)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.primaryContainer, // Fond jaune très clair
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.campaign_rounded,
                      size: 20, color: colorScheme.onPrimaryContainer),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SchoolService.name,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            fontSize: 14),
                      ),
                      Text(
                        _formatDate(annonce['date']),
                        style: TextStyle(
                            color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Badge Type
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        colorScheme.secondaryContainer, // Fond vert très clair
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    annonce['type'] ?? '',
                    style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 11,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                // Bouton Partager
                IconButton(
                  icon: Icon(Icons.share_outlined,
                      color: colorScheme.onSurfaceVariant, size: 20),
                  onPressed: () => _sharePost(annonce),
                  tooltip: 'Partager',
                ),
              ],
            ),
          ),

          // IMAGE
          if (hasImage)
            Image.network(
              displayImage,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 120,
                color: colorScheme.surfaceContainerHighest,
                child: Center(
                    child: Icon(Icons.image_not_supported_outlined,
                        color: colorScheme.outline)),
              ),
            ),

          // CONTENU TEXTE
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  annonce['title'] ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: colorScheme.onSurface,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  annonce['description'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
