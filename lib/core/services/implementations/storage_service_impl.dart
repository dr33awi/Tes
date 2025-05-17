// lib/core/services/implementations/storage_service_impl.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../interfaces/storage_service.dart';

class StorageServiceImpl implements StorageService {
  final SharedPreferences _prefs;

  StorageServiceImpl(this._prefs);

  @override
  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  @override
  String? getString(String key) {
    return _prefs.getString(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  @override
  bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  @override
  int? getInt(String key) {
    return _prefs.getInt(key);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  @override
  double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  @override
  List<String>? getStringList(String key) {
    return _prefs.getStringList(key);
  }

  @override
  Future<bool> setMap(String key, Map<String, dynamic> value) async {
    return await _prefs.setString(key, jsonEncode(value));
  }

  @override
  Map<String, dynamic>? getMap(String key) {
    final String? jsonString = _prefs.getString(key);
    if (jsonString == null) return null;
    
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  @override
  Future<bool> clear() async {
    return await _prefs.clear();
  }

  @override
  bool containsKey(String key) {
    return _prefs.containsKey(key);
  }

  @override
  Set<String> getKeys() {
    return _prefs.getKeys();
  }
}