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
  bool _isLogin = true;
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final user = await FirebaseService().signInWithEmail(email, password);
        if (user != null) {
          widget.onLogin(user.displayName ?? email.split('@')[0]);
        }
      } else {
        final user = await FirebaseService().signUpWithEmail(email, password, name);
        if (user != null) {
          widget.onLogin(user.displayName ?? name);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                  _isLogin ? 'Welcome back to your second brain' : 'Create your intelligent hub',
                  style: TextStyle(color: Colors.white.withOpacity(0.4), letterSpacing: 1, fontSize: 13),
                ),
                const SizedBox(height: 40),

                // Form Toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _isLogin = true),
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isLogin ? const Color(0xFFBC13FE) : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(width: 30),
                    GestureDetector(
                      onTap: () => setState(() => _isLogin = false),
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: !_isLogin ? const Color(0xFFBC13FE) : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Inputs
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Column(
                      children: [
                        if (!_isLogin) ...[
                          _buildTextField(_nameController, "Full Name", Icons.person_outline),
                          const SizedBox(height: 12),
                        ],
                        _buildTextField(_emailController, "Email", Icons.email_outlined, isEmail: true),
                        const SizedBox(height: 12),
                        _buildTextField(_passwordController, "Password", Icons.lock_outline, isPassword: true),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Action
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitAuth,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFBC13FE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isLogin ? 'Login' : 'Create Account', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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

                // Social Logins
                _buildSocialButton(
                  label: 'Continue with Google',
                  icon: Icons.g_mobiledata,
                  onPressed: () async {
                    setState(() => _isLoading = true);
                    try {
                      final user = await FirebaseService().signInWithGoogle();
                      if (user != null) {
                        widget.onLogin(user.displayName ?? "User");
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign-in failed: $e'), backgroundColor: Colors.redAccent));
                      }
                    }
                    if (mounted) setState(() => _isLoading = false);
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {bool isPassword = false, bool isEmail = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFBC13FE), width: 2),
        ),
        prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.4)),
      ),
    );
  }

  Widget _buildSocialButton({required String label, required IconData icon, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: OutlinedButton(
        onPressed: _isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.12)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: Colors.white.withOpacity(0.05),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Colors.white.withOpacity(0.7)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
