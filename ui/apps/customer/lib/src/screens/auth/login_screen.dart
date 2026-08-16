import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';
import 'register_screen.dart';

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'customer@mns.com');
  final _passwordCtrl = TextEditingController(text: 'CustomerPass123!');
  bool _isLoading = false;
  bool _rememberMe = true;
  String? _error;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = context.read<AuthSessionManager>();
      await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
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
            height: size.height * 0.38,
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.darkCardGradient,
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delivery_dining, size: 38, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Please sign in to your existing account',
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
            top: size.height * 0.32,
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
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
                        const SizedBox(height: 18),
                      ],
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'EMAIL',
                        hintText: 'example@gmail.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 18),
                      AppTextField(
                        controller: _passwordCtrl,
                        label: 'PASSWORD',
                        hintText: '••••••••••••',
                        obscureText: true,
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                activeColor: AppColors.brandPrimary,
                                onChanged: (val) => setState(() => _rememberMe = val ?? true),
                              ),
                              const Text('Remember me', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            ],
                          ),
                          TextButton(
                            onPressed: () {},
                            child: const Text('Forgot Password', style: TextStyle(fontSize: 13, color: AppColors.brandPrimary, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        text: 'LOG IN',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Text("Don't have an account? ", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const CustomerRegisterScreen(),
                              ));
                            },
                            child: const Text('SIGN UP', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandPrimary)),
                          ),
                        ],
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
