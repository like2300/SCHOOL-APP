import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/storage_service.dart';

/// Connexion app par fiche d'inscription : ID étudiant + n° téléphone.
/// En cas de succès, la fiche (nom, établissement, niveau, filière)
/// est stockée localement et les notifications sont scopées dessus.
class AuthService {
  static bool get isLoggedIn =>
      (StorageService.getString('user_matricule') ?? '').isNotEmpty ||
      (StorageService.getString('user_guest') ?? '').isNotEmpty;

  static bool get isGuest =>
      (StorageService.getString('user_guest') ?? '').isNotEmpty;

  /// Connexion invité : nom + téléphone uniquement, sans fiche validée.
  static Future<void> loginGuest({
    required String nom,
    required String phone,
  }) async {
    await StorageService.setString('user_guest', '1');
    await StorageService.setString('user_nom', nom.trim());
    await StorageService.setString('user_phone', phone.trim());
    await StorageService.setBool('isFirstTime', false);
  }

  static Future<Map<String, dynamic>> login({
    required String matricule,
    required String phone,
  }) async {
    final uri = Uri.parse('${ApiService.rootUrl}/inscription/api/inscriptions/login/');
    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'matricule': matricule.trim().toUpperCase(),
              'phone': phone.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));
      dynamic data;
      try {
        data = json.decode(utf8.decode(response.bodyBytes));
      } catch (_) {
        return {
          'ok': false,
          'error':
              'Le serveur a répondu une erreur (${response.statusCode}). Vérifie qu\'il est démarré.'
        };
      }
      if (response.statusCode == 200 && data is Map && data['ok'] == true) {
        final profile = Map<String, dynamic>.from(data['profile'] ?? {});
        await StorageService.setString(
            'user_matricule', (profile['matricule'] ?? matricule).toString());
        await StorageService.setString(
            'user_phone', (profile['phone'] ?? phone).toString());
        await StorageService.setString(
            'user_nom', (profile['nom'] ?? '').toString());
        final etab = (profile['etablissement'] ?? '').toString();
        final niveau = (profile['niveau'] ?? '').toString();
        final filiere = (profile['filiere'] ?? '').toString();
        if (etab.isNotEmpty) await StorageService.setString('user_etab', etab);
        if (niveau.isNotEmpty) {
          await StorageService.setString('user_niveau', niveau);
        }
        if (filiere.isNotEmpty) {
          await StorageService.setString('user_filiere', filiere);
        }
        final mats = profile['matricules_resultats'];
        if (mats is List) {
          await StorageService.saveData('user_matricules_resultats',
              mats.map((e) => e.toString()).toList());
        }
        await StorageService.setBool('isFirstTime', false);
        return {'ok': true, 'profile': profile, 'resultats': data['resultats']};
      }
      return {
        'ok': false,
        'error': (data is Map && data['error'] != null)
            ? data['error'].toString()
            : 'ID étudiant ou téléphone incorrect.'
      };
    } catch (e) {
      // Diagnostic précis : hôte visé + cause (connexion refusée, timeout...).
      final host = '${uri.host}:${uri.hasPort ? uri.port : ''}';
      debugPrint('[AuthService] login vers $uri : $e');
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out') ||
          e.toString().contains('No route to host') ||
          e.toString().contains('Network is unreachable')) {
        return {
          'ok': false,
          'error':
              'Serveur injoignable ($host). Vérifie que le backend tourne : `manage.py runserver 0.0.0.0:8000`.'
        };
      }
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timed out')) {
        return {
          'ok': false,
          'error': 'Le serveur ne répond pas ($host). Réessaie dans un instant.'
        };
      }
      return {
        'ok': false,
        'error': 'Impossible de contacter le serveur ($host).'
      };
    }
  }

  static Future<void> logout() async {
    await StorageService.removeData('user_matricule');
    await StorageService.removeData('user_phone');
    await StorageService.removeData('user_nom');
    await StorageService.removeData('user_guest');
    await StorageService.removeData('user_matricules_resultats');
    // On garde etab/niveau/filiere (préférences d'affichage).
  }
}
