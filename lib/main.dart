import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/firebase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/habit_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/planner_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
  int _selectedIndex = 0;
  String _activeTheme = 'neon_dark';

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userName = user.displayName ?? "User";
      });
    }
  }

  void _onThemeChanged(String themeKey) {
    setState(() {
      _activeTheme = themeKey;
    });
  }

  Widget _buildCurrentScreen() {
    if (_userName == null) {
      return AuthScreen(onLogin: (name) => setState(() {
        _userName = name;
        _selectedIndex = 0;
      }));
    }

    switch (_selectedIndex) {
      case 0:
        return DashboardScreen(
          userName: _userName!,
          activeTheme: _activeTheme,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: () async {
            await FirebaseService().signOut();
            setState(() => _userName = null);
          },
        );
      case 1:
        return ChatScreen(userName: _userName!);
      case 2:
        return const PlannerScreen();
      case 3:
        return const HabitScreen();
      case 4:
        return const FinanceScreen();
      case 5:
        return SettingsScreen(
          activeTheme: _activeTheme,
          onThemeChanged: _onThemeChanged,
          userName: _userName!,
          onLogout: () async {
            await FirebaseService().signOut();
            setState(() => _userName = null);
          },
        );
      default:
        return DashboardScreen(
          userName: _userName!,
          activeTheme: _activeTheme,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: () async {
            await FirebaseService().signOut();
            setState(() => _userName = null);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0C29),
        cardColor: Colors.black,
        dividerColor: const Color(0xFF262626),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF5F5F5)),
          bodyMedium: TextStyle(color: Color(0xFFA8A8A8)),
        ),
      ),
      home: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildCurrentScreen(),
        bottomNavigationBar: _userName != null ? Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.08))),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: const Color(0xFFBC13FE),
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 11,
            unselectedFontSize: 10,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
              BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: 'AI Agent'),
              BottomNavigationBarItem(icon: Icon(Icons.calendar_today_rounded), label: 'Planner'),
              BottomNavigationBarItem(icon: Icon(Icons.track_changes_rounded), label: 'Habits'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Finance'),
            ],
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ) : null,
      ),
    );
  }
}
