import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import '../theme/glass_theme.dart';
import '../providers/providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.onLogout,
  });

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: ref.read(settingsProvider).userName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCurrencyPicker(String currentCurrency, GlassTheme curTheme, bool isLight, Color borderColor, Color textPrimary) {
    final currencies = [
      {'\$': 'US Dollar (\$)'},
      {'₹': 'Indian Rupee (₹)'},
      {'€': 'Euro (€)'},
      {'£': 'British Pound (£)'},
      {'¥': 'Japanese Yen (¥)'},
      {'A\$': 'Australian Dollar (A\$)'},
      {'C\$': 'Canadian Dollar (C\$)'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isLight ? Colors.white : const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isLight ? Colors.grey[300] : Colors.grey[700], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Select Currency', style: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...currencies.map((c) {
              final symbol = c.keys.first;
              final label = c.values.first;
              final isSelected = currentCurrency == symbol;
              return ListTile(
                title: Text(label, style: TextStyle(color: isSelected ? curTheme.accentColor : textPrimary)),
                trailing: isSelected ? Icon(Icons.check_circle, color: curTheme.accentColor) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? curTheme.accentColor.withValues(alpha: 0.1) : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).setCurrency(symbol);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final curTheme = ref.watch(activeThemeProvider);
    
    // Update controller text if settings name changes (e.g. after cloud load)
    ref.listen<AppSettings>(settingsProvider, (prev, next) {
      if (prev?.userName != next.userName && _nameController.text != next.userName) {
        _nameController.text = next.userName;
      }
    });

    final isLight = curTheme.brightness == Brightness.light;
    final textPrimary = isLight ? Colors.black87 : Colors.white;
    final textSecondary = isLight ? Colors.black54 : Colors.white70;
    final textTertiary = isLight ? Colors.black38 : Colors.white38;
    final borderColor = isLight ? Colors.black.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.1);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20).copyWith(bottom: 120),
        children: [
          // User Profile Section
          Text('USER PROFILE', style: TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildPremiumCard(
            isLight: isLight,
            borderColor: borderColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Display Name', style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    hintStyle: TextStyle(color: textTertiary),
                    filled: true,
                    fillColor: isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                      onPressed: () {
                        ref.read(settingsProvider.notifier).setUserName(_nameController.text.trim());
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile Updated!'), backgroundColor: Colors.green),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Theme Selection
          Text('UNIVERSAL GLASS THEMES', style: TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...GlassTheme.themes.entries.map((entry) => _buildThemeCard(entry.key, entry.value, settings.themeKey, isLight, textPrimary, textTertiary, borderColor)),

          const SizedBox(height: 30),

          // Preferences
          Text('PREFERENCES', style: TextStyle(color: textTertiary, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildActionTile(Icons.attach_money_rounded, 'Currency', 'Selected: ${settings.currency}', onTap: () => _showCurrencyPicker(settings.currency, curTheme, isLight, borderColor, textPrimary), color: Colors.greenAccent, textPrimary: textPrimary, textTertiary: textTertiary),
          
          const SizedBox(height: 30),

          // Logout Button
          GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Text('Logout Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard({required Widget child, required bool isLight, required Color borderColor}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: (isLight ? Colors.black : Colors.white).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildThemeCard(String key, GlassTheme theme, String activeThemeKey, bool isLight, Color textPrimary, Color textTertiary, Color borderColor) {
    final isSelected = activeThemeKey == key;

    return GestureDetector(
      onTap: () => ref.read(settingsProvider.notifier).setTheme(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor.withValues(alpha: 0.15) : (isLight ? Colors.black.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.accentColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: theme.backgroundGradient),
                border: Border.all(color: borderColor),
              ),
              child: Center(child: Icon(theme.brightness == Brightness.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 16, color: Colors.white.withValues(alpha: 0.6))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.name, style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                  Text(theme.description, style: TextStyle(color: textTertiary, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected) Icon(Icons.check_circle_rounded, color: theme.accentColor) else Icon(Icons.radio_button_off_rounded, color: textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {required VoidCallback onTap, required Color color, required Color textPrimary, required Color textTertiary}) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 15)),
      subtitle: Text(subtitle, style: TextStyle(color: textTertiary, fontSize: 12)),
      trailing: Icon(Icons.arrow_forward_ios_rounded, color: textTertiary, size: 14),
    );
  }
}
