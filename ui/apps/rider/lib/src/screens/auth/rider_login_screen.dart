import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auth_session/auth_session.dart';
import 'package:design_system/design_system.dart';

class RiderLoginScreen extends StatefulWidget {
  const RiderLoginScreen({super.key});

  @override
  State<RiderLoginScreen> createState() => _RiderLoginScreenState();
}

class _RiderLoginScreenState extends State<RiderLoginScreen> {
  final _emailCtrl = TextEditingController(text: 'rider@mns.com');
  final _passwordCtrl = TextEditingController(text: 'RiderPass123!');
  bool _isLoading = false;
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
          // Header Area
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
                          color: AppColors.brandPrimary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.two_wheeler, size: 40, color: AppColors.brandPrimary),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Rider Portal',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'M&S Delivery Express Kabacan Courier Fleet',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Main Card
          Positioned(
            top: size.height * 0.34,
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
                        label: 'RIDER EMAIL',
                        hintText: 'rider@mns.com',
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
                      const SizedBox(height: 28),
                      AppButton(
                        text: 'START COURIER SHIFT',
                        isLoading: _isLoading,
                        onPressed: _handleLogin,
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
