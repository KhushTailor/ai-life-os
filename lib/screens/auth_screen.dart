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
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final user = await FirebaseService().signInWithGoogle();
      if (user != null) {
        widget.onLogin(user.displayName ?? "User");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign-in failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

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
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Area
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFBC13FE).withValues(alpha: 0.15),
                    border: Border.all(color: const Color(0xFFBC13FE).withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFBC13FE).withValues(alpha: 0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.auto_awesome, color: Color(0xFFBC13FE), size: 48),
                ),
                const SizedBox(height: 32),
                const Text(
                  'LIFE OS',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 8, color: Colors.white),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your intelligent personal operating system',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.4), letterSpacing: 1, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 60),

                // Google Sign-In Button
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.g_mobiledata, size: 30, color: Colors.white.withValues(alpha: 0.9)),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Continue with Google',
                                    style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w600, fontSize: 16),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
                Text(
                  'Your data syncs to the cloud automatically.\nSign in to access it from any device.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 12, height: 1.6),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
