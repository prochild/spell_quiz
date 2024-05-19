import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _preferences;

  static Future init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static Future setWords(List<String> words) async {
    await _preferences?.setStringList('words', words);
  }

  static List<String> getWords() {
    return _preferences?.getStringList('words') ?? [];
  }
}
