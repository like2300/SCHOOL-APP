import 'package:flutter/material.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:estim_campus/compos/app_scaffold.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;
  List<int> _hiddenIds = [];
  String _selectedCategory = 'Tous';

  final List<String> _categories = [
    'Tous',
    'Annonce',
    'Cours',
    'Examen',
    'Résultat',
    'Calendrier'
  ];

  @override
  void initState() {
    super.initState();
    _loadHiddenIds();
    _fetchNotifications();
  }

  void _loadHiddenIds() {
    final data = StorageService.getData('hidden_notifications');
    if (data != null && data is List) {
      setState(() {
        _hiddenIds = List<int>.from(data);
      });
    }
  }

  Future<void> _hideNotification(int id) async {
    // Petite animation de sortie avant de retirer de la liste
    setState(() {
      _hiddenIds.add(id);
      _notifications.removeWhere((n) => n['id'] == id);
    });
    await StorageService.saveData('hidden_notifications', _hiddenIds);
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    final data = await ApiService.getNotifications();
    print('[NotificationsPage] API returned ${data.length} notifications');
    print('[NotificationsPage] Raw data: $data');
    print('[NotificationsPage] Hidden IDs: $_hiddenIds');
    if (mounted) {
      setState(() {
        _notifications =
            data.where((n) => !_hiddenIds.contains(n['id'])).toList();
        _isLoading = false;
      });
      print(
          '[NotificationsPage] After hidden filter: ${_notifications.length} notifications');
    }
  }

  List<dynamic> get _filteredNotifications {
    final String? userMatricule =
        StorageService.getString('user_matricule')?.trim().toUpperCase();

    final userNotifs = _notifications.where((n) {
      final String? target =
          n['target_matricule']?.toString().trim().toUpperCase();
      return target == null || target == '' || target == userMatricule;
    }).toList();

    print('[NotificationsPage] User matricule: $userMatricule');
    print(
        '[NotificationsPage] After target filter: ${userNotifs.length} notifications');

    if (_selectedCategory == 'Tous') return userNotifs;

    return userNotifs.where((n) {
      final type = (n['notification_type'] ?? '').toString().toLowerCase();
      final Map<String, List<String>> typeMap = {
        'Annonce': ['annonce'],
        'Cours': ['cours'],
        'Examen': ['examen'],
        'Résultat': ['resultat', 'resultats', 'résultat', 'résultats'],
        'Calendrier': ['calendrier'],
      };

      final allowedTypes = typeMap[_selectedCategory] ?? [];
      return allowedTypes.any((allowed) => type.contains(allowed));
    }).toList();
  }

  // Formateur de date intelligent
  String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      final DateTime dt = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();

      if (dt.day == now.day && dt.month == now.month && dt.year == now.year) {
        return "Aujourd'hui à ${DateFormat('HH:mm').format(dt)}";
      }
      return DateFormat('dd MMM, HH:mm', 'fr_FR').format(dt);
    } catch (e) {
      return dateStr.length > 16 ? dateStr.substring(0, 16) : dateStr;
    }
  }

  // Icône dynamique selon le type
  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'annonce':
        return Icons.campaign_outlined;
      case 'cours':
        return Icons.menu_book_outlined;
      case 'examen':
        return Icons.quiz_outlined;
      case 'resultat':
      case 'resultats':
        return Icons.verified_outlined;
      case 'calendrier':
        return Icons.calendar_month_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      selectedIndex: -1,
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.done_all_rounded,
                color: colorScheme.onSurfaceVariant),
            tooltip: 'Tout marquer comme lu',
            onPressed: _fetchNotifications, // Simule un rafraîchissement
          ),
        ],
      ),
      body: Column(
        children: [
          // FILTRES (ChoiceChips modernes)
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return ChoiceChip(
                  label: Text(category,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedCategory = category);
                  },
                  selectedColor: colorScheme.primary,
                  labelStyle: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant),
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                  showCheckmark: false,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              },
            ),
          ),

          Divider(
              height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),

          // LISTE DES NOTIFICATIONS
          Expanded(
            child: _isLoading
                ? Center(
                    child:
                        CircularProgressIndicator(color: colorScheme.primary))
                : RefreshIndicator(
                    color: colorScheme.primary,
                    onRefresh: _fetchNotifications,
                    child: _filteredNotifications.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: _filteredNotifications.length,
                            itemBuilder: (context, index) {
                              final notif = _filteredNotifications[index];
                              return _buildNotificationCard(notif, colorScheme);
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded,
              size: 80, color: colorScheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            'Tout est calme ici',
            style: TextStyle(
                fontSize: 16,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Vous n\'avez aucune notification',
            style: TextStyle(fontSize: 13, color: colorScheme.outline),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(dynamic notif, ColorScheme colorScheme) {
    final bool isRead = notif['is_read'] == true;
    final String type = notif['notification_type'] ?? '';

    // Le widget Dismissible permet de swiper pour supprimer
    return ClipRRect(
      borderRadius:
          BorderRadius.circular(16), // Arrondit les bords du fond rouge
      child: Dismissible(
        key: Key(notif['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.only(bottom: 8),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.delete_outline_rounded,
              color: colorScheme.onErrorContainer),
        ),
        onDismissed: (direction) => _hideNotification(notif['id']),
        // La carte elle-même
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // Fond coloré subtil si non lu
            color: isRead
                ? colorScheme.surface
                : colorScheme.primaryContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            // Bordure très subtile
            border: Border.all(
              color: isRead
                  ? colorScheme.outlineVariant.withOpacity(0.3)
                  : colorScheme.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône contextuelle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isRead
                      ? colorScheme.surfaceContainerHighest
                      : colorScheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getTypeIcon(type),
                  size: 20,
                  color: isRead
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 14),

              // Contenu texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Point discret pour non lu
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary, // Point jaune
                              shape: BoxShape.circle,
                            ),
                          ),
                        Expanded(
                          child: Text(
                            notif['title'] ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight:
                                  isRead ? FontWeight.w500 : FontWeight.w800,
                              color: colorScheme.onSurface,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      notif['message'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatTime(notif['created_at']?.toString()),
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).addGesture(
      // Gestion du clic pour marquer comme lu et naviguer
      onTap: () async {
        if (!isRead) {
          await ApiService.markNotificationAsRead(notif['id']);
          _fetchNotifications();
        }
        if (!context.mounted) return;

        if (type == 'annonce' || notif['annonce'] != null) {
          Navigator.pushNamed(context, '/annonces');
        } else if (type == 'cours') {
          Navigator.pushNamed(context, '/emploi');
        } else if (type == 'examen' || type == 'examens') {
          Navigator.pushNamed(context, '/examens');
        } else if (type == 'calendrier') {
          Navigator.pushNamed(context, '/calendrier');
        } else if (type == 'resultat' || type == 'resultats') {
          Navigator.pushNamed(context, '/resultats');
        }
      },
    );
  }
}

// Extension utilitaire pour ajouter un onTap proprement à n'importe quel widget
extension WidgetExtension on Widget {
  Widget addGesture({required Function() onTap}) {
    return GestureDetector(onTap: onTap, child: this);
  }
}
