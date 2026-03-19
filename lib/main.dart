import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.black,
  ));
  runApp(const LifeOSApp());
}

class LifeOSApp extends StatefulWidget {
  const LifeOSApp({super.key});

  @override
  State<LifeOSApp> createState() => _LifeOSAppState();
}

class _LifeOSAppState extends State<LifeOSApp> {
  String? _userName;
  String? _uid;
  int _selectedIndex = 0;
  String _activeThemeKey = 'nebula_deep';
  String _currency = '\$';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) {
        setState(() {
          _userName = user.displayName ?? "User";
          _uid = user.uid;
        });
      }
    }
  }

  void _onThemeChanged(String themeKey) {
    setState(() {
      _activeThemeKey = themeKey;
    });
  }

  void _onCurrencyChanged(String symbol) {
    setState(() {
      _currency = symbol;
    });
  }

  Future<void> _logout() async {
    await FirebaseService().signOut();
    setState(() { _userName = null; _uid = null; });
  }

  Widget _buildCurrentScreen(GlassTheme theme) {
    if (_userName == null || _uid == null) {
      return AuthScreen(
        onLogin: (name) {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            setState(() {
              _userName = name;
              _uid = user.uid;
              _selectedIndex = 0;
            });
          }
        },
      );
    }

    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          userName: _userName!,
          uid: _uid!,
          activeTheme: theme,
          currency: _currency,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: _logout,
        );
      case 1:
        return ChatScreen(userName: _userName!);
      case 2:
        return PlannerScreen(uid: _uid!, activeTheme: theme);
      case 3:
        return HabitScreen(uid: _uid!, activeTheme: theme);
      case 4:
        return FinanceScreen(uid: _uid!, currency: _currency, activeTheme: theme);
      case 5:
        return SettingsScreen(
          activeTheme: _activeThemeKey,
          onThemeChanged: _onThemeChanged,
          userName: _userName!,
          currency: _currency,
          onCurrencyChanged: _onCurrencyChanged,
          onLogout: _logout,
        );
      default:
        return DashboardScreen(
          userName: _userName!,
          uid: _uid!,
          activeTheme: theme,
          currency: _currency,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: _logout,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = GlassTheme.themes[_activeThemeKey] ?? GlassTheme.themes['nebula_deep']!;

    return MaterialApp(
      title: 'Life OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: theme.brightness,
        scaffoldBackgroundColor: Colors.transparent,
        cardColor: Colors.black,
        dividerColor: Colors.white.withOpacity(0.1),
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        // extendBody: true allows content to scroll BEHIND the floating bottom bar
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
              _buildCurrentScreen(theme),
              if (_userName != null)
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
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: (theme.brightness == Brightness.dark ? Colors.black : Colors.white).withOpacity(0.7),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withOpacity(0.1),
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
                _buildNavItem(Icons.calendar_today_rounded, 'Plan', 2, theme),
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
    final isSelected = _selectedIndex == index || (_selectedIndex == 5 && index == 0);

    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: isSelected
            ? BoxDecoration(
                color: theme.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? theme.accentColor : (theme.brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[700]),
              size: isSelected ? 26 : 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.accentColor : (theme.brightness == Brightness.dark ? Colors.grey[500] : Colors.grey[700]),
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
