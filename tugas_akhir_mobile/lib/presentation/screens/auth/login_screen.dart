import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/custom_widgets.dart';
import '../../providers/auth_provider.dart';
import '../../navigation/navigation.dart';
import '../../../core/utils/validators.dart';
import '../../../core/services/biometric_service.dart';

/// Login Screen
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
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
                  const SizedBox(height: 32),
                  const Icon(
                    Icons.school,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Welcome to EduFun',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Learn, Play & Grow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
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
                                Validators.validateRequired(value, 'Password'),
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          const SizedBox(height: 24),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              return CustomButton(
                                text: 'Login',
                                isLoading: authProvider.isLoading,
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    final success = await authProvider.login(
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
                          OutlinedButton.icon(
                            onPressed: () async {
                              final bio = context.read<BiometricService>();
                              final authProvider = context.read<AuthProvider>();
                              final allowed = await bio.authenticate();
                              if (!context.mounted) {
                                return;
                              }

                              if (!allowed) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Biometrik gagal atau tidak tersedia'),
                                  ),
                                );
                                return;
                              }

                              final success = await authProvider.biometricQuickLogin();
                              if (!context.mounted) {
                                return;
                              }

                              if (success) {
                                Navigator.of(context).pushReplacementNamed(AppNavigation.home);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(authProvider.error ?? 'Login biometrik gagal')),
                                );
                              }
                            },
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Login dengan Biometrik'),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Don\'t have an account? '),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context)
                                      .pushNamed(AppNavigation.register);
                                },
                                child: const Text('Register'),
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
