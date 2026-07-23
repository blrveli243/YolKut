import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WaterNotifier extends Notifier<int> {
  SharedPreferences? _prefs;

  @override
  int build() {
    _initPrefs();
    return 0; // Başlangıç 0 ml, initPrefs sonrası güncellenir
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final dateStr = '${today.year}-${today.month}-${today.day}';
    final savedDate = _prefs?.getString('water_date');

    if (savedDate == dateStr) {
      state = _prefs?.getInt('water_amount') ?? 0;
    } else {
      _prefs?.setString('water_date', dateStr);
      _prefs?.setInt('water_amount', 0);
      state = 0;
    }
  }

  void addWater() {
    state += 200;
    _prefs?.setInt('water_amount', state);
  }

  void removeWater() {
    if (state >= 200) {
      state -= 200;
      _prefs?.setInt('water_amount', state);
    }
  }
}

final waterProvider = NotifierProvider<WaterNotifier, int>(() {
  return WaterNotifier();
});
