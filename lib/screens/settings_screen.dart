import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/glass_theme.dart';

class SettingsScreen extends StatefulWidget {
  final String activeTheme;
  final Function(String) onThemeChanged;
  final String userName;
  final String currency;
  final Function(String) onCurrencyChanged;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.activeTheme,
    required this.onThemeChanged,
    required this.userName,
    required this.currency,
    required this.onCurrencyChanged,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  void _showCurrencyPicker() {
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
          color: const Color(0xFF1A1A2E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Select Currency', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...currencies.map((c) {
              final symbol = c.keys.first;
              final label = c.values.first;
              final isSelected = widget.currency == symbol;
              return ListTile(
                title: Text(label, style: TextStyle(color: isSelected ? const Color(0xFFBC13FE) : Colors.white)),
                trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFFBC13FE)) : null,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isSelected ? const Color(0xFFBC13FE).withOpacity(0.1) : null,
                onTap: () {
                  widget.onCurrencyChanged(symbol);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Notifications', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildToggleTile('Daily Reminders', true),
            _buildToggleTile('Habit Alerts', true),
            _buildToggleTile('Finance Updates', false),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(color: Color(0xFFBC13FE))),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(String label, bool defaultVal) {
    return StatefulBuilder(
      builder: (context, setInnerState) {
        bool val = defaultVal;
        return SwitchListTile(
          title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          value: val,
          activeColor: const Color(0xFFBC13FE),
          onChanged: (v) => setInnerState(() => val = v),
          dense: true,
          contentPadding: EdgeInsets.zero,
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Privacy & Security', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• All data is stored securely in Google Cloud Firestore', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.8)),
            Text('• No data is shared with third parties', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.8)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(color: Color(0xFFBC13FE))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final curTheme = GlassTheme.themes[widget.activeTheme] ?? GlassTheme.themes['nebula_deep']!;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Customize OS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20).copyWith(bottom: 120),
        children: [
          // Profile Card
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: (curTheme.brightness == Brightness.dark ? Colors.white : Colors.black).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: curTheme.accentColor,
                      child: Text(
                        widget.userName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.userName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Premium Member', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Theme Selection
          Text('UNIVERSAL GLASS THEMES', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          ...GlassTheme.themes.entries.map((entry) => _buildThemeCard(entry.key, entry.value)),

          const SizedBox(height: 30),

          // General Settings
          Text('PREFERENCES', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 16),
          _buildActionTile(Icons.attach_money_rounded, 'Currency', 'Selected: ${widget.currency}', onTap: _showCurrencyPicker, color: Colors.greenAccent),
          _buildActionTile(Icons.notifications_active_rounded, 'Notifications', 'Manage alerts', onTap: _showNotificationsDialog, color: Colors.orangeAccent),
          _buildActionTile(Icons.shield_rounded, 'Privacy', 'Data & security', onTap: _showPrivacyDialog, color: Colors.cyanAccent),

          const SizedBox(height: 30),

          // Logout Button
          GestureDetector(
            onTap: widget.onLogout,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.redAccent, size: 20),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(String key, GlassTheme theme) {
    final isSelected = widget.activeTheme == key;

    return GestureDetector(
      onTap: () => widget.onThemeChanged(key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.accentColor.withOpacity(0.15) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? theme.accentColor : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Mini Background Preview
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: theme.backgroundGradient),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Center(
                child: Icon(
                  theme.brightness == Brightness.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  size: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(theme.description, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: theme.accentColor)
            else
              Icon(Icons.radio_button_off_rounded, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, String subtitle, {required VoidCallback onTap, required Color color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: Colors.white.withOpacity(0.2), size: 14),
          ],
        ),
      ),
    );
  }
}
