import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static Future<void> saveData(
      {required String key, required String value}) async {
    SharedPreferences store = await SharedPreferences.getInstance();
    await store.setString(key, value);
  }

  // Read data from local storage
  static Future<String?> readData(String key) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  static Future<void> saveDouble(
      {required String key, required double value}) async {
    SharedPreferences store = await SharedPreferences.getInstance();
    await store.setDouble(key, value);
  }

  static Future<void> saveBool(
      {required String key, required bool value}) async {
    SharedPreferences store = await SharedPreferences.getInstance();
    await store.setBool(key, value);
  }

  static Future<String?> getData({required String key}) async {
    try {
      SharedPreferences store = await SharedPreferences.getInstance();
      return store.getString(key);
    } catch (err) {
      return null;
    }
  }

  static Future<double?> getDouble({required String key}) async {
    try {
      SharedPreferences store = await SharedPreferences.getInstance();
      return store.getDouble(key);
    } catch (err) {
      return null;
    }
  }

  static Future<bool?> getBool({required String key}) async {
    try {
      SharedPreferences store = await SharedPreferences.getInstance();
      return store.getBool(key);
    } catch (err) {
      return null;
    }
  }

  static Future<void> removeData({required String key}) async {
    SharedPreferences store = await SharedPreferences.getInstance();
    await store.remove(key);
  }

  static Future<void> removeAll() async {
    SharedPreferences store = await SharedPreferences.getInstance();
    await store.clear();
  }
}
