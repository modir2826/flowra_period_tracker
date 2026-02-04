import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/card_container.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    // Validate inputs
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text)) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'Please agree to terms and conditions');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.registerWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _nameController.text.trim(),
      );

      if (mounted) {
        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Join Flowra',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.pink.shade700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Create your account and take control of your health',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 24),

              // Error Message
              if (_errorMessage != null)
                CardContainer(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox.shrink(),
              if (_errorMessage != null) const SizedBox(height: 16),

              // Full Name
              Text(
                'Full Name',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.person_outline),
                  prefixIconColor: Colors.pink.shade300,
                  hintText: 'Enter your full name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade600, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Email
              Text(
                'Email Address',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  prefixIconColor: Colors.pink.shade300,
                  hintText: 'you@example.com',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade600, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Text(
                'Password',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                enabled: !_isLoading,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outlined),
                  prefixIconColor: Colors.pink.shade300,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.pink.shade300,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                  hintText: 'At least 6 characters',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade600, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password
              Text(
                'Confirm Password',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmPasswordController,
                enabled: !_isLoading,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outlined),
                  prefixIconColor: Colors.pink.shade300,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: Colors.pink.shade300,
                    ),
                    onPressed: () {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
                    },
                  ),
                  hintText: 'Re-enter your password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.pink.shade600, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 20),

              // Terms and Conditions
              Row(
                children: [
                  Checkbox(
                    value: _agreedToTerms,
                    onChanged: _isLoading
                        ? null
                        : (value) {
                            setState(() => _agreedToTerms = value ?? false);
                          },
                    activeColor: Colors.pink.shade600,
                  ),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                        children: [
                          const TextSpan(text: 'I agree to the '),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: TextStyle(
                              color: Colors.pink.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: TextStyle(
                              color: Colors.pink.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Register Button
              PrimaryButton(
                label: 'Create Account',
                busy: _isLoading,
                onPressed: _isLoading ? null : _handleRegister,
              ),
              const SizedBox(height: 16),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          },
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.pink.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
