import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'services/firebase_service.dart';
import 'theme/glass_theme.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/habit_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/focus_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/onboarding_screen.dart';
import 'providers/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDBqWBgvKyyGoZxkrdJUJ2CLSH6UyUrZxk',
        appId: '1:165104335983:android:c6ed235c3eb903890e219a',
        messagingSenderId: '165104335983',
        projectId: 'life-os-29eb0',
        storageBucket: 'life-os-29eb0.firebasestorage.app',
      ),
    );
  } catch (e) {
    await Firebase.initializeApp();
  }

  await FirebaseService.enablePersistence();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
  ));
  
  runApp(
    const ProviderScope(
      child: LifeOSApp(),
    ),
  );
}

class LifeOSApp extends ConsumerStatefulWidget {
  const LifeOSApp({super.key});

  @override
  ConsumerState<LifeOSApp> createState() => _LifeOSAppState();
}

class _LifeOSAppState extends ConsumerState<LifeOSApp> {
  int _selectedIndex = 0;
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isFirstTime = prefs.getBool('first_time') ?? true;
    });
  }

  void _onOnboardingFinished() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_time', false);
    setState(() => _isFirstTime = false);
  }

  Widget _buildCurrentScreen(User? user) {
    if (_isFirstTime) {
      return OnboardingScreen(onFinished: _onOnboardingFinished);
    }

    if (user == null) {
      return const AuthScreen();
    }

    debugPrint("NAVIGATING TO SCREEN: $_selectedIndex");
    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: () => ref.read(firebaseServiceProvider).signOut(),
        );
      case 1:
        return const ChatScreen();
      case 2:
        return PlannerScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 3:
        return HabitScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 4:
        return FinanceScreen(onNavigate: (index) => setState(() => _selectedIndex = index));
      case 5:
        return SettingsScreen(
          onLogout: () => ref.read(firebaseServiceProvider).signOut(),
        );
      case 6:
        return const FocusScreen();
      case 7:
        return const InsightsScreen();
      default:
        return DashboardScreen(
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: () => ref.read(firebaseServiceProvider).signOut(),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(activeThemeProvider);
    final user = ref.watch(authStateProvider).value;
    final isLight = theme.brightness == Brightness.light;

    return MaterialApp(
      title: 'Life OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: theme.brightness,
        scaffoldBackgroundColor: Colors.transparent,
        cardColor: isLight ? Colors.white : Colors.black,
        dividerColor: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1),
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        extendBody: true,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: theme.backgroundGradient,
            ),
          ),
          child: Stack(
            children: [
              _buildCurrentScreen(user),
              if (user != null && !_isFirstTime)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFloatingNavBar(theme),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingNavBar(GlassTheme theme) {
    final isLight = theme.brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: (isLight ? Colors.white : Colors.black).withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withValues(alpha: 0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.dashboard_rounded, 'Home', 0, theme),
                _buildNavItem(Icons.auto_awesome, 'AI', 1, theme),
                _buildNavItem(Icons.check_circle_outline_rounded, 'Tasks', 2, theme),
                _buildNavItem(Icons.track_changes_rounded, 'Habits', 3, theme),
                _buildNavItem(Icons.account_balance_wallet_rounded, 'Finance', 4, theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, GlassTheme theme) {
    final isSelected = _selectedIndex == index || (_selectedIndex == 5 && index == 0) || (_selectedIndex == 6 && index == 0);
    final isLight = theme.brightness == Brightness.light;
    final inactiveColor = isLight ? Colors.grey[600] : Colors.grey[500];

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: theme.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.accentColor : inactiveColor,
              size: isSelected ? 26 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.accentColor : inactiveColor,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
