import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(String) onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '◈ LIFE OS',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 4),
              ),
              const SizedBox(height: 8),
              Text(
                'Intelligent Personal Operating System',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, letterSpacing: 1),
              ),
              const SizedBox(height: 60),
              
              // Standard Name Login
              TextField(
                controller: _controller,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: 'Enter your name...',
                  hintStyle: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.5)),
                  filled: true,
                  fillColor: theme.cardColor,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0095F6), width: 2),
                  ),
                ),
                onSubmitted: (val) { if(val.trim().isNotEmpty) widget.onLogin(val.trim()); },
              ),
              const SizedBox(height: 16),
              _buildButton(
                label: 'Continue with Name',
                onPressed: () { if(_controller.text.trim().isNotEmpty) widget.onLogin(_controller.text.trim()); },
                color: const Color(0xFF0095F6),
              ),
              
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: Divider(color: theme.dividerColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('OR', style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: theme.dividerColor)),
                ],
              ),
              const SizedBox(height: 24),

              // Social Logins
              _buildSocialButton(
                label: 'Continue with Google',
                iconPath: 'assets/google_logo.png', // Placeholder for actual icon
                onPressed: () async {
                  final user = await FirebaseService().signInWithGoogle();
                  if (user != null) {
                    widget.onLogin(user.displayName ?? "Life OS User");
                  }
                },
                isDark: theme.brightness == Brightness.dark,
              ),
              const SizedBox(height: 12),
              _buildSocialButton(
                label: 'Continue with Apple',
                icon: Icons.apple,
                onPressed: () async {
                  final user = await FirebaseService().signInWithApple();
                  if (user != null) {
                    widget.onLogin(user.displayName ?? "Life OS User");
                  }
                },
                isDark: theme.brightness == Brightness.dark,
              ),
              
              const SizedBox(height: 48),
              Text(
                'Data is synced to your Life OS Cloud account for lifetime persistence.',
                textAlign: TextAlign.center,
                style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton({required String label, required VoidCallback onPressed, required Color color}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Widget _buildSocialButton({required String label, String? iconPath, IconData? icon, required VoidCallback onPressed, required bool isDark}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: theme.dividerColor),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          backgroundColor: theme.cardColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) Icon(icon, size: 22, color: theme.textTheme.bodyLarge?.color)
            else const Icon(Icons.mail, size: 20), // Placeholder
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: theme.textTheme.bodyLarge?.color,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
