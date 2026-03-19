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
            _buildToggleTile('AI Insights', true),
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
            Text('• Authentication is handled by Firebase Auth', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.8)),
            Text('• No data is shared with third parties', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.8)),
            Text('• Your AI conversations are not stored on our servers', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.8)),
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

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFFBC13FE)),
            SizedBox(width: 10),
            Text('Life OS', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 2.0.0', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
            const SizedBox(height: 12),
            Text('AI Life OS is your intelligent personal operating system. Plan your day, track habits, manage finances, and get AI-powered insights — all in one app.', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.6)),
            const SizedBox(height: 16),
            Text('Built with Flutter & Firebase', style: TextStyle(color: const Color(0xFFBC13FE).withOpacity(0.8), fontSize: 12)),
            Text('AI powered by Google Gemini', style: TextStyle(color: const Color(0xFFBC13FE).withOpacity(0.8), fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Color(0xFFBC13FE))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Profile Card
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFFBC13FE),
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
                            Text('Life OS Member', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Theme Selection
            Text('APPEARANCE', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            ...GlassTheme.themes.entries.map((entry) => _buildThemeOption(entry.key, entry.value)),

            const SizedBox(height: 24),

            // General Settings
            Text('GENERAL', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 12),
            _buildSettingsTile(Icons.attach_money, 'Currency', 'Current: ${widget.currency}', onTap: _showCurrencyPicker),
            _buildSettingsTile(Icons.notifications_outlined, 'Notifications', 'Manage alerts', onTap: _showNotificationsDialog),
            _buildSettingsTile(Icons.lock_outline, 'Privacy', 'Data & security', onTap: _showPrivacyDialog),
            _buildSettingsTile(Icons.info_outline, 'About', 'Version 2.0.0', onTap: _showAboutDialog),

            const SizedBox(height: 24),

            // Logout Button
            GestureDetector(
              onTap: widget.onLogout,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.logout, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(String key, GlassTheme theme) {
    final isSelected = widget.activeTheme == key;

    return GestureDetector(
      onTap: () => widget.onThemeChanged(key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isSelected ? 0.12 : 0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? theme.accentColor : Colors.white.withOpacity(0.08),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(theme.cardBorderRadius / 2),
                gradient: LinearGradient(colors: theme.backgroundGradient),
                border: Border.all(color: theme.accentColor.withOpacity(0.4)),
              ),
              child: Center(
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.accentColor,
                    boxShadow: [BoxShadow(color: theme.accentColor.withOpacity(0.5), blurRadius: 8)],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(theme.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text(theme.description, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: theme.accentColor)
            else
              Icon(Icons.circle_outlined, color: Colors.white.withOpacity(0.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white.withOpacity(0.6), size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.2), size: 16),
          ],
        ),
      ),
    );
  }
}
