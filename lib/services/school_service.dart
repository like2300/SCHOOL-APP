import 'package:estim_campus/services/api_service.dart';
import 'package:estim_campus/services/storage_service.dart';

/// Nom + logo de l'école de l'étudiant connecté.
///
/// Priorité : établissement de la fiche (user_etab, rempli au login),
/// puis branding admin, puis 'ESTIM'.
class SchoolService {
  static const String fallbackName = 'ESTIM';

  /// Nom de l'école de l'étudiant connecté (ex : ESTM BRAZZAVILLE).
  static String get name {
    final etab = StorageService.getString('user_etab');
    if (etab != null && etab.trim().isNotEmpty && etab.trim() != 'Tous') {
      return etab.trim();
    }
    final branding = StorageService.getData('cache_branding');
    final appName =
        branding is Map ? (branding['app_name'] ?? '').toString() : '';
    if (appName.isNotEmpty) return appName;
    return fallbackName;
  }

  /// Vrai si un étudiant est connecté avec une école connue.
  static bool get hasSchool {
    final etab = StorageService.getString('user_etab');
    return etab != null && etab.trim().isNotEmpty && etab.trim() != 'Tous';
  }

  /// Détails de l'école depuis /api/etablissements/ (logo...), mis en cache.
  /// Retourne null si introuvable ou hors-ligne (utilise alors le cache).
  static Future<Map<String, dynamic>?> fetchSchool() async {
    try {
      final res = await ApiService.getEtablissementsRaw();
      final want = (StorageService.getString('user_etab') ?? '').toUpperCase();
      for (final e in res) {
        if (e is Map && (e['nom'] ?? '').toString().toUpperCase() == want) {
          final map = Map<String, dynamic>.from(e);
          final img = (map['image'] ?? '').toString();
          map['logo_url'] =
              ApiService.formatImageUrl(img.isEmpty ? null : img);
          await StorageService.saveData('cache_school', map);
          return map;
        }
      }
    } catch (_) {}
    final cached = StorageService.getData('cache_school');
    if (cached is Map) return Map<String, dynamic>.from(cached);
    return null;
  }

  static String? get logoUrl {
    final cached = StorageService.getData('cache_school');
    if (cached is Map) {
      final u = (cached['logo_url'] ?? '').toString();
      if (u.isNotEmpty) return u;
    }
    return null;
  }
}
