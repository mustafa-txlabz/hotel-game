import 'package:shared_preferences/shared_preferences.dart';

/// Handles game persistence using SharedPreferences with versioning and backup.
class SaveService {
  static const String saveKey = 'save_v1';
  static const String corruptSaveKey = 'save_v1_corrupt';

  Future<void> init() async {
    await SharedPreferences.getInstance();
  }
}
