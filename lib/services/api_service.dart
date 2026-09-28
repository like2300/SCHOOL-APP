import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:estim_campus/services/storage_service.dart';

class ApiService {
  /// true = API locale (dev), false = production.
  /// Émulateur Android -> 10.0.2.2 automatique ; Windows/navigateur -> 127.0.0.1.
  /// Téléphone physique : remplace [_localRoot] par http://<IP-LAN-du-PC>:8000
  static const bool isLocal = true;

  static const String _prodRoot = 'https://estim-campus.alwaysdata.net';

  static String get _localRoot {
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  static String get rootUrl => isLocal ? _localRoot : _prodRoot;

  static String get baseUrl => '$rootUrl/api';

  static Future<List<dynamic>> getAnnonces() async {
    try {
      final uri = Uri.parse('$baseUrl/annonces/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_annonces', data);
        return data;
      }
    } catch (e) {
      // Log error silently in production or use a logging service
    }
    return StorageService.getData('cache_annonces') ?? [];
  }

  static Future<List<dynamic>> getHeroImages() async {
    try {
      final uri = Uri.parse('$baseUrl/hero/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_hero', data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData('cache_hero') ?? [];
  }

  static Future<List<dynamic>> getCours(
      {int? day,
      String? etablissement,
      String? niveau,
      String? filiere}) async {
    String cacheKey = 'cache_cours_${day}_${etablissement}_${niveau}_$filiere';
    try {
      String url = '$baseUrl/cours/?';
      if (day != null) url += 'day=$day&';
      if (etablissement != null && etablissement != 'Tous')
        url += 'etablissement=$etablissement&';
      if (niveau != null && niveau != 'Tous') url += 'niveau=$niveau&';
      if (filiere != null && filiere != 'Toutes') url += 'filiere=$filiere&';

      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData(cacheKey, data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData(cacheKey) ?? [];
  }

  static Future<List<dynamic>> getApps() async {
    try {
      final uri = Uri.parse('$baseUrl/apps/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_apps', data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData('cache_apps') ?? [];
  }

  static Future<List<dynamic>> getNotifications() async {
    try {
      String? userMatricule = StorageService.getString('user_matricule');
      String? anonymousId = StorageService.getString('anonymous_id');

      String url = '$baseUrl/notifications/';
      final Map<String, String> queryParams = {};

      // Matricule de la fiche -> seules ses notifs + les générales scopées.
      if (userMatricule != null && userMatricule.isNotEmpty) {
        queryParams['matricule'] = userMatricule.trim().toUpperCase();
      } else if (anonymousId != null && anonymousId.isNotEmpty) {
        // Si pas de matricule, on peut essayer avec l'ID anonyme
        // mais ce n'est pas idéal pour les notifications de résultats
        queryParams['matricule'] = anonymousId;
      }

      // Scope fiche : établissement / niveau / filière de l'étudiant.
      final etab = StorageService.getString('user_etab');
      final niveau = StorageService.getString('user_niveau');
      final filiere = StorageService.getString('user_filiere');
      if (etab != null && etab.isNotEmpty && etab != 'Tous') {
        queryParams['etablissement'] = etab;
      }
      if (niveau != null && niveau.isNotEmpty && niveau != 'Tous') {
        queryParams['niveau'] = niveau;
      }
      if (filiere != null && filiere.isNotEmpty && filiere != 'Toutes') {
        queryParams['filiere'] = filiere;
      }

      if (queryParams.isNotEmpty) {
        url += '?${Uri(queryParameters: queryParams).query}';
      }

      final uri = Uri.parse(url);
      print('[ApiService] Fetching notifications from: $uri');
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      print('[ApiService] Response status: ${response.statusCode}');
      print('[ApiService] Response body: ${response.body}');
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_notifications', data);
        return data;
      }
    } catch (e) {
      print('[ApiService] Error fetching notifications: $e');
    }
    return StorageService.getData('cache_notifications') ?? [];
  }

  static Future<List<dynamic>> getExamens(
      {String? etablissement, String? niveau, String? filiere}) async {
    String cacheKey = 'cache_examens_${etablissement}_${niveau}_$filiere';
    try {
      String url = '$baseUrl/examens/?';
      if (etablissement != null && etablissement != 'Tous')
        url += 'etablissement=$etablissement&';
      if (niveau != null && niveau != 'Tous') url += 'niveau=$niveau&';
      if (filiere != null && filiere != 'Toutes') url += 'filiere=$filiere&';

      final uri = Uri.parse(url);
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData(cacheKey, data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData(cacheKey) ?? [];
  }

  static Future<List<dynamic>> getCalendrier() async {
    try {
      final uri = Uri.parse('$baseUrl/calendrier/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_calendrier', data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData('cache_calendrier') ?? [];
  }

  static Future<List<dynamic>> getSitesWeb() async {
    try {
      final uri = Uri.parse('$baseUrl/sites-web/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_sites_web', data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData('cache_sites_web') ?? [];
  }

  static Future<void> markNotificationAsRead(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/notifications/$id/');
      await http.patch(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'is_read': true}),
      );
    } catch (e) {}
  }

  static Future<List<dynamic>> getEtablissementsRaw() async {
    try {
      final uri = Uri.parse('$baseUrl/etablissements/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_etabs_raw', data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData('cache_etabs_raw') ?? [];
  }

  static Future<List<String>> getEtablissements() async {
    try {
      final uri = Uri.parse('$baseUrl/etablissements/');
      print('Appel API: GET $uri'); // Log pour diagnostiquer l'appel API
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      print(
          'Réponse API: ${response.statusCode}'); // Log pour diagnostiquer la réponse
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        final list = ['Tous'] + data.map((e) => e['nom'].toString()).toList();
        StorageService.saveData('cache_etabs', list);
        return list;
      }
    } catch (e) {
      print('Erreur API: $e'); // Log pour diagnostiquer les erreurs
    }
    return List<String>.from(StorageService.getData('cache_etabs') ?? ['Tous']);
  }

  static Future<List<String>> getNiveaux() async {
    try {
      final uri = Uri.parse('$baseUrl/niveaux/');
      print('Appel API: GET $uri'); // Log pour diagnostiquer l'appel API
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      print(
          'Réponse API: ${response.statusCode}'); // Log pour diagnostiquer la réponse
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        final list = ['Tous'] + data.map((e) => e['nom'].toString()).toList();
        StorageService.saveData('cache_niveaux', list);
        return list;
      }
    } catch (e) {
      print('Erreur API: $e'); // Log pour diagnostiquer les erreurs
    }
    return List<String>.from(
        StorageService.getData('cache_niveaux') ?? ['Tous']);
  }

  static Future<List<String>> getFilieres() async {
    try {
      final uri = Uri.parse('$baseUrl/filieres/');
      print('Appel API: GET $uri'); // Log pour diagnostiquer l'appel API
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      print(
          'Réponse API: ${response.statusCode}'); // Log pour diagnostiquer la réponse
      if (response.statusCode == 200) {
        final List data = json.decode(utf8.decode(response.bodyBytes));
        final list = ['Toutes'] + data.map((e) => e['nom'].toString()).toList();
        StorageService.saveData('cache_filieres', list);
        return list;
      }
    } catch (e) {
      print('Erreur API: $e'); // Log pour diagnostiquer les erreurs
    }
    return List<String>.from(
        StorageService.getData('cache_filieres') ?? ['Toutes']);
  }

  static Future<List<dynamic>> getSessions() async {
    try {
      final uri = Uri.parse('$baseUrl/sessions/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_sessions', data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData('cache_sessions') ?? [];
  }

  static Future<Map<String, dynamic>?> getInscription(int id) async {
    try {
      String? userMatricule = StorageService.getString('user_matricule');
      String? anonymousId = StorageService.getString('anonymous_id');

      final queryParams = {
        'pk': id.toString(),
      };
      if (userMatricule != null && userMatricule.isNotEmpty)
        queryParams['payer_matricule'] = userMatricule;
      if (anonymousId != null && anonymousId.isNotEmpty)
        queryParams['anonymous_id'] = anonymousId;

      final uri = Uri.parse('$rootUrl/inscription/api/inscriptions/consulter/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return null;
  }

  static Future<Map<String, dynamic>?> getResultat(
      String matricule, int sessionId) async {
    try {
      String? userMatricule = StorageService.getString('user_matricule');
      String? anonymousId = StorageService.getString('anonymous_id');

      final queryParams = {
        'matricule': matricule.toUpperCase(),
        'session': sessionId.toString(),
      };
      if (userMatricule != null && userMatricule.isNotEmpty)
        queryParams['payer_matricule'] = userMatricule;
      if (anonymousId != null && anonymousId.isNotEmpty)
        queryParams['anonymous_id'] = anonymousId;

      final uri = Uri.parse('$baseUrl/resultats/consulter/')
          .replace(queryParameters: queryParams);

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {}
    return null;
  }

  static Future<Map<String, dynamic>?> createPaymentLink(
      String targetMatricule, dynamic sessionId) async {
    try {
      String? payerMatricule = StorageService.getString('user_matricule') ??
          StorageService.getString('anonymous_id');
      final uri = Uri.parse('$baseUrl/transactions/create_pay_link/');
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'payer_matricule': payerMatricule,
              'target_matricule': targetMatricule,
              'session_id': sessionId,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = json.decode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      } else {
        return {
          'error': data['error'] ?? 'Erreur lors de la création du paiement'
        };
      }
    } catch (e) {}
    return {'error': 'Impossible de contacter le serveur de paiement'};
  }

  static Future<Map<String, dynamic>?> getFormConfig() async {
    try {
      final uri = Uri.parse('$rootUrl/inscription/api/form-config/current/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_form_config', data);
        return data;
      }
    } catch (e) {}
    return StorageService.getData('cache_form_config');
  }

  /// Nom + personnalité de l'assistant IA, modifiables depuis /admin/.
  /// {nom, personnalite} — null si l'API est injoignable et sans cache.
  static Future<Map<String, dynamic>?> getAssistant() async {
    try {
      final uri = Uri.parse('$baseUrl/assistant/current/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_assistant', data);
        return Map<String, dynamic>.from(data);
      }
      if (response.statusCode == 404) {
        // Assistant désactivé côté admin : purge le cache pour masquer le bouton.
        await StorageService.removeData('cache_assistant');
        return null;
      }
    } catch (e) {}
    final cached = StorageService.getData('cache_assistant');
    if (cached is Map) return Map<String, dynamic>.from(cached);
    return null;
  }

  /// Logo + nom de l'app, modifiables depuis /admin/ (AppBranding).
  /// Retourne `logo_display` (URL absolue) avec fallback cache.
  static Future<Map<String, dynamic>?> getBranding() async {
    try {
      final uri = Uri.parse('$baseUrl/branding/current/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_branding', data);
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {}
    final cached = StorageService.getData('cache_branding');
    return cached == null ? null : Map<String, dynamic>.from(cached);
  }

  /// Slides d'onboarding modifiables depuis /admin/ (OnboardingSlide).
  /// Chaque slide: {title, description, image, image_display, ordre, is_active}.
  static Future<List<dynamic>> getOnboardingSlides() async {
    try {
      final uri = Uri.parse('$baseUrl/onboarding/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        final list = data is List ? data : (data['results'] ?? []);
        StorageService.saveData('cache_onboarding', list);
        return list;
      }
    } catch (e) {}
    return StorageService.getData('cache_onboarding') ?? [];
  }

  /// Couleurs de l'app pilotées depuis /admin/ (Thème de l'admin).
  /// {primary_color: '#...', accent_color: '#...'} — null si injoignable et sans cache.
  static Future<Map<String, dynamic>?> getTheme() async {
    try {
      final uri = Uri.parse('$baseUrl/theme/current/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        StorageService.saveData('cache_theme', data);
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {}
    final cached = StorageService.getData('cache_theme');
    return cached == null ? null : Map<String, dynamic>.from(cached);
  }

  static Future<String> getChatbotPrompt() async {
    try {
      final uri = Uri.parse('$baseUrl/chatbot-prompt/');
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        String basePrompt = data['prompt'] ??
            'Tu es un assistant utile pour les étudiants de ESTIM.';
        return '$basePrompt\n\nDirectives: Sois très concis. Optimise tes réponses pour consommer le moins de tokens possible. Ne répète pas les informations inutiles.';
      }
    } catch (e) {}
    return 'Tu es un assistant utile pour les étudiants de ESTIM. Sois concis.';
  }

  static Future<Map<String, dynamic>> getChatbotContext(
      {String? etablissement, String? niveau, String? filiere}) async {
    try {
      final annonces = await getAnnonces();
      final calendrier = await getCalendrier();
      final formConfig = await getFormConfig();

      final now = DateTime.now();
      final cours = await getCours(
        day: now.weekday,
        etablissement: etablissement,
        niveau: niveau,
        filiere: filiere,
      );

      final annoncesSummary = annonces
          .take(5)
          .map((a) => "- ${a['title']} (${a['date']})")
          .join('\n');
      final calendrierSummary = calendrier
          .take(5)
          .map((c) => "- ${c['title']} : ${c['date_debut']}")
          .join('\n');
      final coursSummary = cours
          .map((c) => "- ${c['matiere']} à ${c['heure']} (Salle ${c['salle']})")
          .join('\n');

      return {
        'annonces': annoncesSummary,
        'calendrier': calendrierSummary,
        'cours':
            coursSummary.isEmpty ? "Aucun cours aujourd'hui" : coursSummary,
        'app_download_url': formConfig?['app_download_url'] ?? '',
        'school_website':
            formConfig?['school_website'] ?? 'https://www.estim-ecole.com',
        'school_phone': formConfig?['school_phone'] ?? '',
        'school_whatsapp': formConfig?['school_whatsapp'] ?? '',
      };
    } catch (e) {
      return {'annonces': '', 'calendrier': '', 'cours': ''};
    }
  }

  static String? formatImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    if (url.startsWith('http')) {
      return url.replaceFirst('http://', 'https://');
    }

    final String rootUrl = ApiService.rootUrl;

    String cleanUrl = url;
    if (!cleanUrl.startsWith('/')) {
      cleanUrl = '/$cleanUrl';
    }

    if (cleanUrl.contains('/media/')) {
      int mediaIndex = cleanUrl.indexOf('/media/');
      cleanUrl = cleanUrl.substring(mediaIndex);
    } else if (!cleanUrl.startsWith('/static/')) {
      cleanUrl = '/media$cleanUrl';
    }

    return '$rootUrl$cleanUrl';
  }
}
