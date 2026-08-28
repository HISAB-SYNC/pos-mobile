import 'package:flutter/foundation.dart';
import '../models/settings_model.dart';

class SettingsProvider extends ChangeNotifier {
  UserSettings _settings = const UserSettings();
  bool _isEditing = false;

  UserSettings get settings => _settings;
  bool get isEditing => _isEditing;

  void toggleEditing() {
    _isEditing = !_isEditing;
    notifyListeners();
  }

  void setEditing(bool editing) {
    _isEditing = editing;
    notifyListeners();
  }

  void updateSettings(UserSettings newSettings) {
    _settings = newSettings;
    _isEditing = false;
    notifyListeners();
  }
}
