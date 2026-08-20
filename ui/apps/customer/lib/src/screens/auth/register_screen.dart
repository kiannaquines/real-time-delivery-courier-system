import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';

class CustomerRegisterScreen extends StatefulWidget {
  const CustomerRegisterScreen({super.key});

  @override
  State<CustomerRegisterScreen> createState() => _CustomerRegisterScreenState();
}

class _CustomerRegisterScreenState extends State<CustomerRegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _handleRegister() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _phoneCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      setState(() => _error = 'Please fill out all fields.');
      return;
    }

    if (_passwordCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthSessionManager>();
      await auth.registerCustomer(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('ApiException: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Order food from local restaurants in Kabacan.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 24),

                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            label: 'FULL NAME',
                            hintText: 'Juan Dela Cruz',
                            prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.brandPrimary, size: 20),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'EMAIL',
                            hintText: 'juan@example.com',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: const Icon(Icons.email_outlined, color: AppColors.brandPrimary, size: 20),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _phoneCtrl,
                            label: 'PHONE NUMBER',
                            hintText: '+63 917 123 4567',
                            keyboardType: TextInputType.phone,
                            prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.brandPrimary, size: 20),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordCtrl,
                            label: 'PASSWORD',
                            hintText: '••••••••••••',
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.brandPrimary, size: 20),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _confirmPassCtrl,
                            label: 'CONFIRM PASSWORD',
                            hintText: '••••••••••••',
                            obscureText: true,
                            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          AppButton(
                            text: 'CREATE ACCOUNT',
                            isLoading: _isLoading,
                            onPressed: _handleRegister,
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
