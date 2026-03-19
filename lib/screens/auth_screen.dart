import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/firebase_service.dart';

class AuthScreen extends StatefulWidget {
  final Function(String) onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0C29),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F0C29), Color(0xFF302B63), Color(0xFF24243E)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Area
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBC13FE).withOpacity(0.15),
                    border: Border.all(color: const Color(0xFFBC13FE).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFFBC13FE), size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'LIFE OS',
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 6, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'Intelligent Personal Operating System',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), letterSpacing: 1, fontSize: 13),
                ),
                const SizedBox(height: 50),

                // Name Input
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter your name to get started...',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.08),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFBC13FE), width: 2),
                        ),
                        prefixIcon: Icon(Icons.person_outline, color: Colors.white.withOpacity(0.4)),
                      ),
                      onSubmitted: (val) {
                        if (val.trim().isNotEmpty) widget.onLogin(val.trim());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_controller.text.trim().isNotEmpty) widget.onLogin(_controller.text.trim());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBC13FE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),

                const SizedBox(height: 28),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12)),
                    ),
                    Expanded(child: Divider(color: Colors.white.withOpacity(0.1))),
                  ],
                ),
                const SizedBox(height: 28),

                // Google Sign In
                _buildSocialButton(
                  label: 'Continue with Google',
                  icon: Icons.mail_outline,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final user = await FirebaseService().signInWithGoogle();
                      if (user != null) {
                        widget.onLogin(user.displayName ?? "Life OS User");
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign-in failed: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                    if (mounted) setState(() => _isLoading = false);
                  },
                ),
                const SizedBox(height: 12),

                // Apple Sign In
                _buildSocialButton(
                  label: 'Continue with Apple',
                  icon: Icons.apple,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final user = await FirebaseService().signInWithApple();
                      if (user != null) {
                        widget.onLogin(user.displayName ?? "Life OS User");
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign-in failed: $e'), backgroundColor: Colors.redAccent),
                        );
                      }
                    }
                    if (mounted) setState(() => _isLoading = false);
                  },
                ),

                const SizedBox(height: 40),
                if (_isLoading)
                  const CircularProgressIndicator(color: Color(0xFFBC13FE)),
                if (!_isLoading)
                  Text(
                    'Your data is encrypted and synced securely.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
