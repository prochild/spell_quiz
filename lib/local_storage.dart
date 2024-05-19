import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  static SharedPreferences? _preferences;

  static Future init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static List<String> getWords() {
    return _preferences?.getStringList('words') ?? [];
  }

  static void setWords(List<String> words) {
    _preferences?.setStringList('words', words);
  }
}
