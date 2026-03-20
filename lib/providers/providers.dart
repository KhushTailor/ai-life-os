import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../services/ai_service.dart';
import '../theme/glass_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// Services
final firebaseServiceProvider = Provider((ref) => FirebaseService());
final aiServiceProvider = Provider((ref) => AIService());

// Auth State
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).user;
});

// User Data Sync (Tasks, Habits, Finance)
final tasksProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firebaseServiceProvider).streamTasks(user.uid);
});

final habitsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firebaseServiceProvider).streamHabits(user.uid);
});

final financeProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  return ref.watch(firebaseServiceProvider).streamFinance(user.uid);
});

// App Settings (Theme, Currency, User Profile)
class AppSettings {
  final String themeKey;
  final String currency;
  final String userName;

  AppSettings({
    required this.themeKey, 
    required this.currency, 
    this.userName = 'User',
  });

  AppSettings copyWith({String? themeKey, String? currency, String? userName}) {
    return AppSettings(
      themeKey: themeKey ?? this.themeKey,
      currency: currency ?? this.currency,
      userName: userName ?? this.userName,
    );
  }
}

class AppSettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;

  AppSettingsNotifier(this._ref) : super(AppSettings(themeKey: 'nebula_deep', currency: '\$')) {
    _load();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen for auth state changes to re-load settings from cloud
    _ref.listen<AsyncValue<User?>>(authStateProvider, (previous, next) {
      if (next.value != null && previous?.value?.uid != next.value?.uid) {
        debugPrint("AUTH CHANGE DETECTED: Fetching cloud settings for ${next.value?.uid}");
        _load();
      }
    });
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('theme') ?? 'nebula_deep';
    final currency = prefs.getString('currency') ?? '\$';
    final name = prefs.getString('userName') ?? 'User';
    
    state = AppSettings(themeKey: theme, currency: currency, userName: name);

    // Try to restore from Firestore if user is logged in
    final user = _ref.read(authStateProvider).value;
    if (user != null) {
      debugPrint("FETCHING USER DATA FOR: ${user.uid}");
      final userData = await FirebaseService().getUserData(user.uid);
      if (userData != null) {
        debugPrint("CLOUD SETTINGS FOUND: $userData");
        final cloudTheme = userData['theme'] as String?;
        final cloudCurrency = userData['currency'] as String?;
        final cloudName = userData['userName'] as String?;
        
        state = AppSettings(
          themeKey: cloudTheme ?? state.themeKey,
          currency: cloudCurrency ?? state.currency,
          userName: cloudName ?? state.userName,
        );
        
        if (cloudTheme != null) await prefs.setString('theme', cloudTheme);
        if (cloudCurrency != null) await prefs.setString('currency', cloudCurrency);
        if (cloudName != null) await prefs.setString('userName', cloudName);
      } else {
        debugPrint("NO CLOUD SETTINGS FOUND FOR NEW USER");
      }
    }
  }

  Future<void> setTheme(String key) async {
    state = state.copyWith(themeKey: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', key);
    final user = _ref.read(authStateProvider).value;
    if (user != null) {
      await FirebaseService().syncProfile(user.uid, {'theme': key});
      debugPrint("THEME SAVED TO CLOUD: $key");
    }
  }

  Future<void> setCurrency(String symbol) async {
    state = state.copyWith(currency: symbol);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', symbol);
    final user = _ref.read(authStateProvider).value;
    if (user != null) {
      await FirebaseService().syncProfile(user.uid, {'currency': symbol});
      debugPrint("CURRENCY SAVED TO CLOUD: $symbol");
    }
  }

  Future<void> setUserName(String name) async {
    state = state.copyWith(userName: name);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', name);
    final user = _ref.read(authStateProvider).value;
    if (user != null) {
      await FirebaseService().syncProfile(user.uid, {'userName': name});
      debugPrint("USERNAME SAVED TO CLOUD: $name");
    }
  }
}

final settingsProvider = StateNotifierProvider<AppSettingsNotifier, AppSettings>((ref) {
  return AppSettingsNotifier(ref);
});

final activeThemeProvider = Provider((ref) {
  final settings = ref.watch(settingsProvider);
  return GlassTheme.themes[settings.themeKey] ?? GlassTheme.themes['nebula_deep']!;
});
