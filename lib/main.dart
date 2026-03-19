import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/firebase_service.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/habit_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/planner_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // This will need the google-services.json later
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
  ));
  runApp(const LifeOSApp());
}

class LifeOSApp extends StatefulWidget {
  const LifeOSApp({super.key});

  @override
  State<LifeOSApp> createState() => _LifeOSAppState();
}

class _LifeOSAppState extends State<LifeOSApp> {
  bool _isDarkMode = true;
  String? _userName;
  int _selectedIndex = 1;

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  Widget _buildCurrentScreen() {
    if (_userName == null) {
      return AuthScreen(onLogin: (name) => setState(() {
        _userName = name;
        _selectedIndex = 1;
      }));
    }

    switch (_selectedIndex) {
      case 1:
        return DashboardScreen(
          userName: _userName!,
          onToggleTheme: _toggleTheme,
          isDarkMode: _isDarkMode,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: () => setState(() => _userName = null),
        );
      case 2:
        return ChatScreen(userName: _userName!);
      case 3:
        return const HabitScreen();
      case 4:
        return const FinanceScreen();
      case 5:
        return const PlannerScreen();
      default:
        return DashboardScreen(
          userName: _userName!,
          onToggleTheme: _toggleTheme,
          isDarkMode: _isDarkMode,
          onNavigate: (index) => setState(() => _selectedIndex = index),
          onLogout: () => setState(() => _userName = null),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Life OS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFAFAFA),
        cardColor: Colors.white,
        dividerColor: const Color(0xFFDBDBDB),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFF262626)),
          bodyMedium: TextStyle(color: Color(0xFF737373)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        cardColor: Colors.black,
        dividerColor: const Color(0xFF262626),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Color(0xFFF5F5F5)),
          bodyMedium: TextStyle(color: Color(0xFFA8A8A8)),
        ),
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        body: _buildCurrentScreen(),
        bottomNavigationBar: _userName != null ? BottomNavigationBar(
          currentIndex: _selectedIndex >= 1 && _selectedIndex <= 4 ? (_selectedIndex == 1 ? 0 : (_selectedIndex == 2 ? 1 : (_selectedIndex == 3 ? 2 : 3))) : 0,
          type: BottomNavigationBarType.fixed,
          backgroundColor: _isDarkMode ? Colors.black : Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: _isDarkMode ? Colors.grey[600] : Colors.grey[400],
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'AI Agent'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Planner'),
            BottomNavigationBarItem(icon: Icon(Icons.check_circle_outline), label: 'Habits'),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Finance'),
          ],
          onTap: (index) {
            setState(() {
              if (index == 0) _selectedIndex = 1;
              if (index == 1) _selectedIndex = 2;
              if (index == 2) _selectedIndex = 5;
              if (index == 3) _selectedIndex = 3;
              if (index == 4) _selectedIndex = 4;
            });
          },
        ) : null,
      ),
    );
  }
}
