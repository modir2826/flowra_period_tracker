import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/register_screen.dart';
import 'home_screen.dart';
import '../widgets/primary_button.dart';
import '../widgets/card_container.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _logoController.dispose();
    super.dispose();
  }
  late final AnimationController _logoController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = CurvedAnimation(parent: _logoController, curve: Curves.elasticOut);
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _logoController.forward();
  }

  Future<void> _handleLogin() async {
    // Clear previous error message
    setState(() => _errorMessage = null);

    // Validate inputs
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    // Email validation regex
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(_emailController.text)) {
      setState(() => _errorMessage = 'Please enter a valid email');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = await _authService.loginWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        if (user != null) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo/Header with animation
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.pink.shade300, Colors.pink.shade600],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Welcome Text
                Text(
                  'Welcome to Flowra',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.pink.shade700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your period tracker & safety companion',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage != null)
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 16),

                // Email Field
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      prefixIconColor: Colors.pink.shade300,
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Forgot Password
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          // TODO: Implement forgot password
                        },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: Colors.pink.shade600),
                  ),
                ),
                const SizedBox(height: 24),

                // Login Button
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: CardContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: PrimaryButton(
                        label: 'Login',
                        busy: _isLoading,
                        onPressed: _isLoading ? null : _handleLogin,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Divider
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'New User?',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),

                // Register Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.pink.shade600),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.pink.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const TextField(decoration: InputDecoration(labelText: "Email")),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              },
              child: const Text("Login"),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RegisterScreen(),
                  ),
                );
              },
              child: const Text("Don’t have an account? Register"),
            ),
          ],
        ),
      ),
    );
  }
