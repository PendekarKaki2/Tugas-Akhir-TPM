import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/navigation.dart';
import '../../../core/utils/validators.dart';

/// Register Screen
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Create Account',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          CustomTextField(
                            label: 'Username',
                            controller: _usernameController,
                            validator: (value) =>
                                Validators.validateUsername(value),
                            prefixIcon: const Icon(Icons.person),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Password',
                            controller: _passwordController,
                            validator: (value) =>
                                Validators.validatePassword(value),
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Password must be at least 8 characters with uppercase, lowercase, and numbers',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            label: 'Confirm Password',
                            controller: _confirmPasswordController,
                            validator: (value) => Validators.validateConfirmPassword(
                              value,
                              _passwordController.text,
                            ),
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          const SizedBox(height: 24),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return CustomButton(
                                text: 'Register',
                                isLoading: authProvider.isLoading,
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    final success = await authProvider.register(
                                      _usernameController.text,
                                      _passwordController.text,
                                    );

                                    if (!context.mounted) return;

                                    if (success) {
                                      Navigator.of(context)
                                          .pushReplacementNamed(
                                              AppNavigation.home);
                                    } else if (authProvider.error != null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(authProvider.error ?? ''),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Already have an account? '),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushReplacementNamed(
                                          AppNavigation.login);
                                },
                                child: const Text('Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
