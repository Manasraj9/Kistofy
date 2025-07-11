import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final brandColor = const Color(0xFF4B39EF); // Brand color

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Login error: $e')));
    }
  }

  Color get brandBlue => Color(0xFF5170FF);
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: brandBlue,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset('assets/images/banner.png'),
              const SizedBox(height: 32),
              const Text(
                'Welcome Back 👋',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 8),
              const Text(
                'Login to continue using Kistofy',
                style: TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white), // Set text color
                decoration: InputDecoration(
                  labelText: 'Email',
                  labelStyle: const TextStyle(color: Colors.white), // Label color
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.white), // Icon color
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white), // Border when not focused
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white), // Border when focused
                  ),
                ),
              ),

              const SizedBox(height: 16),


          TextField(
          controller: _passwordController,
          obscureText: !_isPasswordVisible,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: const TextStyle(color: Colors.white),
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.white),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white),
            ),
          ),
        ),
          const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Login', style: TextStyle(fontSize: 20,color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              const Text('OR',style:TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {

                  },
                  icon: Image.asset('assets/images/google.png', height: 20),
                  label: const Text('Continue with Google'),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                child: const Text('Don’t have an account? Register', style:TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
