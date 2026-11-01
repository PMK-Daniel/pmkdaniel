import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device preferences deliberately exclude account data and Circle reflections.
class AppPreferences extends ChangeNotifier {
  double textScale = 1;
  bool reduceMotion = false;
  bool saving = false;
  String? error;
  bool _disposed = false;
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      textScale = (prefs.getDouble('ui.textScale') ?? 1).clamp(1.0, 1.3);
      reduceMotion = prefs.getBool('ui.reduceMotion') ?? false;
    } catch (_) {
      error = 'Preferensi belum dapat dimuat. Pengaturan standar digunakan.';
    }
    _notify();
  }

  Future<bool> update({double? scale, bool? motion}) async {
    if (saving || _disposed) return false;
    saving = true;
    error = null;
    _notify();
    try {
      final prefs = await SharedPreferences.getInstance();
      final success = scale != null
          ? await prefs.setDouble('ui.textScale', scale.clamp(1.0, 1.3))
          : await prefs.setBool('ui.reduceMotion', motion ?? reduceMotion);
      if (!success) throw StateError('Preference was not persisted');
      if (scale != null) textScale = scale.clamp(1.0, 1.3);
      if (motion != null) reduceMotion = motion;
      return true;
    } catch (_) {
      error = 'Perubahan belum tersimpan. Coba lagi.';
      return false;
    } finally {
      saving = false;
      _notify();
    }
  }
}

class PreferencesScope extends InheritedNotifier<AppPreferences> {
  const PreferencesScope({
    super.key,
    required AppPreferences controller,
    required super.child,
  }) : super(notifier: controller);
  static AppPreferences? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>()?.notifier;
}

class ImmediatePageTransitions extends PageTransitionsBuilder {
  const ImmediatePageTransitions();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}
