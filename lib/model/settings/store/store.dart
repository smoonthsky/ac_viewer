/// provides an interface for storing and retrieving application settings.
///
/// The class has several methods that allow you to initialize, reload, clear, or remove settings, as well as get or set various types of values such as booleans, integers, doubles, strings, and lists of strings.
abstract class SettingsStore {
  bool get initialized;

  Future<void> init();

  Future<void> reload();

  Future<bool> clear();

  Future<bool> remove(String key);

  // get

  Set<String> getKeys();

  Object? get(String key);

  bool? getBool(String key);

  int? getInt(String key);

  double? getDouble(String key);

  String? getString(String key);

  List<String>? getStringList(String key);

  // set

  Future<bool> setBool(String key, bool value);

  Future<bool> setInt(String key, int value);

  Future<bool> setDouble(String key, double value);

  Future<bool> setString(String key, String value);

  Future<bool> setStringList(String key, List<String> value);
}
