import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Sauvegarder n'importe quel objet JSON (Map ou List)
  static Future<void> saveData(String key, dynamic data) async {
    if (_prefs == null) await init();
    await _prefs!.setString(key, json.encode(data));
  }

  // Récupérer des données sauvegardées
  static dynamic getData(String key) {
    if (_prefs == null) return null;
    String? rawData = _prefs!.getString(key);
    if (rawData == null) return null;
    return json.decode(rawData);
  }

  // Sauvegarder une simple chaîne ou booléen
  static Future<void> setString(String key, String value) async =>
      await _prefs?.setString(key, value);
  static String? getString(String key) {
    if (_prefs == null) return null;
    final value = _prefs!.getString(key);
    print('[StorageService] getString($key): $value');
    return value;
  }

  static Future<void> setBool(String key, bool value) async =>
      await _prefs?.setBool(key, value);
  static bool? getBool(String key) => _prefs?.getBool(key);

  static Future<void> removeData(String key) async => await _prefs?.remove(key);

  static Future<void> clear() async => await _prefs?.clear();
}
