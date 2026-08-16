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
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.brandSecondary,
      body: Stack(
        children: [
          // Header Decorative Area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.32,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.darkCardGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Please sign up to get started ordering food',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Form Card
          Positioned(
            top: size.height * 0.28,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.statusCancelledBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.statusCancelledFg.withOpacity(0.3)),
                          ),
                          child: Text(_error!, style: const TextStyle(color: AppColors.statusCancelledFg, fontSize: 13)),
                        ),
                        const SizedBox(height: 16),
                      ],
                      AppTextField(
                        controller: _nameCtrl,
                        label: 'NAME',
                        hintText: 'John Doe',
                        prefixIcon: const Icon(Icons.person_outline, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'EMAIL',
                        hintText: 'example@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'PHONE NUMBER',
                        hintText: '+63 917 123 4567',
                        keyboardType: TextInputType.phone,
                        prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _passwordCtrl,
                        label: 'PASSWORD',
                        hintText: '••••••••••••',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _confirmPassCtrl,
                        label: 'RE-TYPE PASSWORD',
                        hintText: '••••••••••••',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 28),
                      AppButton(
                        text: 'SIGN UP',
                        isLoading: _isLoading,
                        onPressed: _handleRegister,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
