import 'package:get_storage/get_storage.dart';

class StorageService {
  static final GetStorage _box = GetStorage();

  static T? read<T>(String key) => _box.read<T>(key);
  static Future<void> write<T>(String key, T value) => _box.write(key, value);
  static Future<void> remove(String key) => _box.remove(key);
}
