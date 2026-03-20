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
import 'screens/focus_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/voice_assistant_overlay.dart';
import 'services/voice_service.dart';


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

  // Enable Firestore local disk cache for offline resilience
  await FirebaseService.enablePersistence();

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
  bool _isLoading = true;
  bool _isFirstTime = false;

  @override
  void initState() {
    super.initState();
    _checkFirstTime();
    _checkAuth();
    _loadPreferences();
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

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Initial fetch from SharedPreferences
    String? localTheme = prefs.getString('theme');
    String? localCurrency = prefs.getString('currency');

    if (mounted) {
      setState(() {
        _activeThemeKey = localTheme ?? 'nebula_deep';
        _currency = localCurrency ?? '\$';
      });
    }

    // If logged in but local prefs are missing, try to restore from Firestore
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (localTheme == null || localCurrency == null)) {
      _restoreSettingsFromFirestore(user.uid);
    }
  }

  Future<void> _restoreSettingsFromFirestore(String uid) async {
    try {
      final userData = await FirebaseService().getUserData(uid);
      if (userData != null) {
        final prefs = await SharedPreferences.getInstance();
        
        String? cloudTheme = userData['theme'];
        String? cloudCurrency = userData['currency'];
        String? cloudName = userData['name'];
        String? cloudApiKey = userData['gemini_api_key'];

        if (mounted) {
          setState(() {
            if (cloudTheme != null) {
              _activeThemeKey = cloudTheme;
              prefs.setString('theme', cloudTheme);
            }
            if (cloudCurrency != null) {
              _currency = cloudCurrency;
              prefs.setString('currency', cloudCurrency);
            }
            if (cloudName != null) {
              _userName = cloudName;
            }
            if (cloudApiKey != null) {
              prefs.setString('gemini_api_key', cloudApiKey);
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error restoring settings: $e");
    }
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

  void _onThemeChanged(String themeKey) async {
    setState(() {
      _activeThemeKey = themeKey;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', themeKey);
    
    if (_uid != null) {
      await FirebaseService().syncProfile(_uid!, {'theme': themeKey});
    }
  }

  void _onCurrencyChanged(String symbol) async {
    setState(() {
      _currency = symbol;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', symbol);

    if (_uid != null) {
      await FirebaseService().syncProfile(_uid!, {'currency': symbol});
    }
  }

  Future<void> _logout() async {
    await FirebaseService().signOut();
    setState(() { _userName = null; _uid = null; });
  }

  void _handleVoiceCommand(VoiceCommand command) async {
    if (_uid == null) return;

    switch (command.intent) {
      case VoiceIntent.navigate:
        if (command.payload != null) {
          int index = int.parse(command.payload!);
          setState(() => _selectedIndex = index);
        }
        break;
      case VoiceIntent.changeTheme:
        if (command.payload != null) {
          _onThemeChanged(command.payload!);
        }
        break;
      case VoiceIntent.addTask:
        if (command.payload != null && command.payload!.isNotEmpty) {
          final tasks = await FirebaseService().streamTasks(_uid!).first;
          final updated = List<Map<String, dynamic>>.from(tasks);
          updated.add({'title': command.payload, 'completed': false, 'time': 'Anytime'});
          await FirebaseService().syncTasks(_uid!, updated);
          _showToast('Task added: ${command.payload}');
        }
        break;
      case VoiceIntent.addHabit:
        if (command.payload != null && command.payload!.isNotEmpty) {
          final habits = await FirebaseService().streamHabits(_uid!).first;
          final updated = List<Map<String, dynamic>>.from(habits);
          updated.add({'name': command.payload, 'category': 'General', 'status': 'todo', 'streak': 0});
          await FirebaseService().syncHabits(_uid!, updated);
          _showToast('Habit started: ${command.payload}');
        }
        break;
      case VoiceIntent.addExpense:
        if (command.data != null) {
          final finance = await FirebaseService().streamFinance(_uid!).first;
          final updated = List<Map<String, dynamic>>.from(finance);
          updated.add({
            'title': command.data!['title'] ?? 'Voice Expense',
            'amount': command.data!['amount'],
            'date': 'Today',
            'category': 'Other'
          });
          await FirebaseService().syncFinance(_uid!, updated);
          _showToast('Expense logged: ${command.data!['amount']}');
        }
        break;
      case VoiceIntent.startFocus:
        setState(() => _selectedIndex = 6);
        _showToast('Focus session started for ${command.payload ?? 25} minutes.');
        break;
      case VoiceIntent.askAI:
        setState(() => _selectedIndex = 1); // Go to AI Chat
        _showToast('Asking AI...');
        break;
      case VoiceIntent.queryData:
        if (command.payload == 'tasks') {
          final tasks = await FirebaseService().streamTasks(_uid!).first;
          final count = tasks.where((t) => t['completed'] == false).length;
          _showToast('You have $count pending tasks.');
        } else if (command.payload == 'finance') {
          final finance = await FirebaseService().streamFinance(_uid!).first;
          final total = finance.where((tx) => (tx['amount'] ?? 0) < 0).fold(0.0, (s, t) => s + (t['amount'] as double).abs());
          _showToast('Total expenses: \$${total.toStringAsFixed(2)}');
        }
        break;
      case VoiceIntent.unknown:
        _showToast('Command not recognized: ${command.payload}');
        break;
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black.withOpacity(0.8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildCurrentScreen(GlassTheme theme) {
    if (_isFirstTime) {
      return OnboardingScreen(onFinished: _onOnboardingFinished);
    }

    if (_userName == null || _uid == null) {
      return AuthScreen(
        onLogin: (name) async {
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            setState(() {
              _userName = name;
              _uid = user.uid;
              _selectedIndex = 0;
            });
            // Immediately sync name and restore rest
            await FirebaseService().syncProfile(user.uid, {'name': name});
            await _restoreSettingsFromFirestore(user.uid);
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
        return ChatScreen(userName: _userName!, activeTheme: theme);
      case 2:
        return PlannerScreen(uid: _uid!, activeTheme: theme, onNavigate: (index) => setState(() => _selectedIndex = index));
      case 3:
        return HabitScreen(uid: _uid!, activeTheme: theme, onNavigate: (index) => setState(() => _selectedIndex = index));
      case 4:
        return FinanceScreen(uid: _uid!, currency: _currency, activeTheme: theme, onNavigate: (index) => setState(() => _selectedIndex = index));
      case 5:
        return SettingsScreen(
          activeTheme: _activeThemeKey,
          onThemeChanged: _onThemeChanged,
          userName: _userName!,
          currency: _currency,
          onCurrencyChanged: _onCurrencyChanged,
          onLogout: _logout,
        );
      case 6:
        return FocusScreen(activeTheme: theme);
      case 7:
        return InsightsScreen(uid: _uid!, theme: theme);
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
              if (_userName != null)
                VoiceAssistantOverlay(
                  theme: theme,
                  onCommand: _handleVoiceCommand,
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
