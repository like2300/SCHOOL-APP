import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:estim_campus/compos/bottom_nav.dart';
import 'package:estim_campus/compos/annonces.dart';
import 'package:estim_campus/compos/badge.dart';
import 'package:estim_campus/compos/racourci.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/school_service.dart';
import 'package:estim_campus/services/notification_service.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:estim_campus/compos/emploi/quick_schedule.dart';

import 'package:estim_campus/pages/chatbot_page.dart';
import 'package:estim_campus/compos/chatbot_icon.dart';
import 'package:estim_campus/compos/app_scaffold.dart';

class HomePages extends StatefulWidget {
  const HomePages({super.key});

  @override
  State<HomePages> createState() => _HomePagesState();
}

class _HomePagesState extends State<HomePages> {
  int _notifCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchNotifCount();
    _checkUserProfile();
    _timer = Timer.periodic(const Duration(seconds: 15), (timer) {
      _fetchNotifCount();
    });
  }

  void _checkUserProfile() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final matricule = StorageService.getString('user_matricule');
      if ((matricule == null || matricule.isEmpty) && mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchNotifCount() async {
    final notifs = await ApiService.getNotifications();
    final unread = notifs.where((n) => n['is_read'] == false).toList();

    if (mounted) {
      final bool notificationsEnabled =
          StorageService.getBool('notifications_enabled') ?? true;

      if (unread.length > _notifCount && notificationsEnabled) {
        final lastNotif = unread.first;
        NotificationService.showNativeNotification(
          id: lastNotif['id'],
          title: lastNotif['title'],
          body: lastNotif['message'],
          type: lastNotif['notification_type'],
          relatedId: lastNotif['related_id'],
        );
      }
      setState(() {
        _notifCount = unread.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final schoolName = SchoolService.name;

    return AppScaffold(
      selectedIndex: 0, // INDEX CORRECT : 0 pour Accueil
      appBar: AppBar(
        title: Text(
          schoolName, // Nom de l'école de l'étudiant connecté
          style: TextStyle(
            color: colorScheme.onSurface, // S'adapte au mode sombre
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface, // Plus de blanc en dur
        automaticallyImplyLeading: false,
        toolbarHeight: 90,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 7.0),
            child: ChatbotIcon(
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const ChatbotPage(),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      var tween = Tween(begin: 0.0, end: 1.0)
                          .chain(CurveTween(curve: Curves.easeInOutQuart));

                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: animation.drive(tween),
                          child: child,
                        ),
                      );
                    },
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                );
              },
            ),
          ),
          BadgeIcon(
            icon: Icons.notifications_none_outlined,
            count: _notifCount,
            backgroundColor:
                colorScheme.surfaceContainerHighest, // Plus de grey[200]
            onPressed: () {
              Navigator.pushNamed(context, '/notifications')
                  .then((_) => _fetchNotifCount());
            },
          ),
        ],
      ),
      // CORRIGÉ : Plus de 12 !
      bottomNavigationBar: const NavbarCompo(selectedIndex: 0),
      body: Center(
        // Obligatoire pour le PC pour ne pas étirer la page sur 2 mètres
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Bienvenue, brillant\n',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: 'Etudiant(e) ',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'de $schoolName', // École de l'étudiant connecté
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // CORRIGÉ : Plus de SizedBox(height: 220) !
                const Annonces(),

                const SizedBox(height: 24),
                if (StorageService.getString('user_etab') != null) ...[
                  const QuickSchedule(),
                  const SizedBox(height: 24),
                ],
                Text(
                  'Raccourcis',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width > 900 ? 5 : 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 16,
                  children: [
                    Racourcicompo(
                      text: 'Emploi du temps',
                      icon: Icons.calendar_today,
                      onTap: () => Navigator.pushNamed(context, '/emploi'),
                    ),
                    Racourcicompo(
                      text: 'Calendrier',
                      icon: Icons.event_note,
                      onTap: () => Navigator.pushNamed(context, '/calendrier'),
                    ),
                    Racourcicompo(
                      text: 'Sites Web',
                      icon: Icons.language,
                      onTap: () => Navigator.pushNamed(context, '/sites'),
                    ),
                    Racourcicompo(
                      text: 'Examens',
                      icon: Icons.book,
                      onTap: () => Navigator.pushNamed(context, '/examens'),
                    ),
                    Racourcicompo(
                      text: 'Annonces',
                      icon: Icons.notifications,
                      onTap: () => Navigator.pushNamed(context, '/annonces'),
                    ),
                    Racourcicompo(
                      text: 'Mes Resultats',
                      icon: Icons.assignment,
                      onTap: () => Navigator.pushNamed(context, '/resultats'),
                    ),
                    Racourcicompo(
                      text: 'Profil',
                      icon: Icons.person,
                      onTap: () =>
                          Navigator.pushReplacementNamed(context, '/settings'),
                    ),
                    Racourcicompo(
                      text: 'Inscription',
                      icon: Icons.assignment_ind_outlined,
                      onTap: () async {
                        final Uri url =
                            Uri.parse('${ApiService.rootUrl}/inscription/');
                        if (!await launchUrl(url,
                            mode: LaunchMode.inAppBrowserView)) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Impossible d'ouvrir le lien")),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20), // Espace de sécurité en bas
              ],
            ),
          ),
        ),
      ),
    );
  }
}
