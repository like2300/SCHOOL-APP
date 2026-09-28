import 'package:flutter/material.dart';
import 'package:estim_campus/pages/home.dart';
import 'package:estim_campus/pages/login_page.dart';
import 'package:estim_campus/compos/starter.dart';
import 'package:estim_campus/pages/apps.dart';
import 'package:estim_campus/pages/emploi.dart';
import 'package:estim_campus/pages/annonces.dart';
import 'package:estim_campus/pages/notifications.dart';
import 'package:estim_campus/pages/settings_page.dart';
import 'package:estim_campus/pages/resultat_page.dart';
import 'package:estim_campus/pages/examens.dart';
import 'package:estim_campus/pages/verify_page.dart';
import 'package:estim_campus/pages/payment_success_page.dart';
import 'package:estim_campus/pages/chatbot_page.dart';
import 'package:estim_campus/pages/calendrier_academique.dart';
import 'package:estim_campus/pages/sites_web_page.dart';
import 'package:estim_campus/pages/webview_page.dart';
import 'package:estim_campus/pages/aide_page.dart';
import 'package:estim_campus/services/storage_service.dart';
import 'package:estim_campus/compos/error_view.dart';
import 'package:estim_campus/services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:workmanager/workmanager.dart';
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/school_service.dart';
import 'dart:io' show Platform;

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await StorageService.init();
      final notifications = await ApiService.getNotifications();
      if (notifications.isNotEmpty) {
        final lastId = StorageService.getData('last_notif_id') ?? 0;
        final String? userMatricule =
            StorageService.getString('user_matricule');

        final relevantNotifs = notifications.where((n) {
          final target = n['target_matricule']?.toString().trim().toUpperCase();
          return target == null ||
              target == '' ||
              target == userMatricule?.trim().toUpperCase();
        }).toList();

        final newNotifs =
            relevantNotifs.where((n) => n['id'] > lastId).toList();

        for (var n in newNotifs) {
          await NotificationService.showNativeNotification(
            id: n['id'],
            title: n['title'],
            body: n['message'],
            type: n['notification_type'],
            relatedId: n['related_id'],
          );
        }

        if (relevantNotifs.isNotEmpty && relevantNotifs.first['id'] > lastId) {
          await StorageService.saveData(
              'last_notif_id', relevantNotifs.first['id']);
        }
      }
    } catch (e) {
      print("Background Task Error: $e");
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await StorageService.init();
  await NotificationService.init();

  try {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      "check-notifications",
      "fetchNotificationsTask",
      frequency: const Duration(minutes: 15),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  } catch (e) {
    print("Workmanager non initialisé (Normal lors d'un Hot Restart): $e");
  }

  await _requestPermissions();

  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (e) {
    print("Intl initialization error: $e");
  }

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Scaffold(
      body: ErrorView(
        message: "Une erreur inattendue de l'application s'est produite.",
        onRetry: () {},
      ),
    );
  };

  // Parcours : onboarding (1ère fois) -> page de connexion -> accueil.
  final bool seenOnboarding = StorageService.getBool('isFirstTime') == false;
  final bool loggedIn = StorageService.getString('user_matricule') != null;
  runApp(MyApp(
    isFirstTime: !seenOnboarding,
    loggedIn: loggedIn,
  ));
}

Future<void> _requestPermissions() async {
  Map<Permission, PermissionStatus> statuses = await [
    Permission.camera,
    Permission.notification,
  ].request();

  if (statuses[Permission.camera]!.isDenied) {
    print("Permission caméra refusée");
  }
}

class MyApp extends StatefulWidget {
  final bool isFirstTime;
  final bool loggedIn;
  const MyApp({super.key, required this.isFirstTime, this.loggedIn = false});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  Color? _primary;
  Color? _accent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTheme();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Recharge les couleurs DB quand on revient sur l'app (après modif /admin/).
    if (state == AppLifecycleState.resumed) _loadTheme();
  }

  /// Couleurs pilotées depuis /admin/ (Thème de l'admin) — fallback jaune/vert.
  Future<void> _loadTheme() async {
    try {
      final theme = await ApiService.getTheme();
      if (!mounted || theme == null) return;
      final p = _parseHex(theme['primary_color']?.toString());
      final a = _parseHex(theme['accent_color']?.toString());
      if (p != null || a != null) {
        setState(() {
          _primary = p;
          _accent = a;
        });
      }
    } catch (_) {}
  }

  static Color? _parseHex(String? hex) {
    if (hex == null) return null;
    final h = hex.trim().replaceFirst('#', '');
    if (h.length == 6 && int.tryParse(h, radix: 16) != null) {
      return Color(int.parse('FF$h', radix: 16));
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Couleur principale (DB) -> primary, couleur d'accent (DB) -> secondary.
    final primary = _primary ?? const Color(0xFF1A6B3C);
    final secondary = _accent ?? primary;
    return MaterialApp(
      navigatorKey: NotificationService.navigatorKey,
      title: SchoolService.name, // Nom de l'école de l'étudiant connecté
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Helvetica',
        useMaterial3: true,
        // --- COULEURS PILOTÉES PAR /admin/ (Thème : principale + accent) ---
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          primary: primary,
          secondary: secondary,
          brightness: Brightness.light, // Mode clair par défaut
        ),
        // Fond de page blanc pur (au lieu de la surface crème teintée de M3).
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          scrolledUnderElevation: 0,
        ),
      ),
      initialRoute: widget.isFirstTime
          ? '/starter'
          : (widget.loggedIn ? '/home' : '/login'),
      routes: {
        '/login': (context) => const LoginPage(),
        '/starter': (context) => const StarterPage(),
        '/home': (context) => const HomePages(),
        '/app': (context) => const Appstores(),
        '/emploi': (context) => const EmploiPage(),
        '/annonces': (context) => const AnnoncesPage(),
        '/notifications': (context) => const NotificationsPage(),
        '/settings': (context) => const SettingsPage(),
        '/resultats': (context) => const ResultatPage(),
        '/examens': (context) => const ExamensPage(),
        '/verify': (context) => const VerifyPage(),
        '/payment-success': (context) => const PaymentSuccessPage(),
        '/chatbot': (context) => const ChatbotPage(),
        '/calendrier': (context) => const CalendrierAcademiquePage(),
        '/sites': (context) => const SitesWebPage(),
        '/aide': (context) => const AidePage(),
        '/webview': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return WebViewPage(url: args['url'], title: args['title']);
        },
      },
      onGenerateRoute: (settings) {
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const HomePages(),
        );
      },
    );
  }
}

class StarterPage extends StatelessWidget {
  const StarterPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: StarterCompo());
  }
}
