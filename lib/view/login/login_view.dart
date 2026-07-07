import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../res/colors/app_color.dart';
import '../../res/components/app_button.dart';
import '../../res/components/app_flushbar.dart';
import '../../routes/routes_name.dart';
import '../../view_models/providers/auth_provider.dart';
import '../../view_models/services/cloud_user/cloud_user_service.dart';
import '../../view_models/services/database/database_services.dart';
import 'widgets/auth_scaffold.dart';

/// Simple, animated email/password login. On success:
///  - pulls the shop profile from Firestore (if any) into local Hive,
///  - routes to Home if a profile exists, else to the shop-info setup page.
class LoginView extends ConsumerStatefulWidget {
  const LoginView({super.key});

  @override
  ConsumerState<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends ConsumerState<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final user = await ref.read(authProvider.notifier).login(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    if (user == null) {
      final err = ref.read(authProvider).errorMessage;
      AppFlushbar.error(context, message: err ?? 'Login failed');
      return;
    }

    // Pull the cloud profile into local Hive, then route by whether a shop
    // profile exists.
    bool hasProfile = false;
    try {
      final cloudUser = await CloudUserService().getProfile();
      if (cloudUser != null) {
        final db = DatabaseService();
        await db.initialize();
        await db.saveUser(cloudUser);
        hasProfile = true;
      } else {
        final db = DatabaseService();
        await db.initialize();
        hasProfile = (await db.getUsers()).isNotEmpty;
      }
    } catch (_) {
      // Offline / no profile — fall through to setup.
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      hasProfile ? RouteName.mainScreen : RouteName.profileEdit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to your shop',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AuthField(
              controller: _emailCtrl,
              label: 'Email',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            SizedBox(height: 16.spMin),
            _AuthField(
              controller: _passwordCtrl,
              label: 'Password',
              hint: 'Your password',
              icon: Icons.lock_outline,
              obscure: _obscure,
              suffix: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  size: 20.spMin,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                return null;
              },
              onSubmitted: (_) => _login(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: authState.isLoading ? null : _forgotPassword,
                child: Text(
                  'Forgot password?',
                  style: TextStyle(fontSize: 12.spMin, color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 8.spMin),
            AppButton().primaryButton(
              text: 'Sign In',
              isLoading: authState.isLoading,
              onPressed: _login,
              height: 48.spMin,
              borderRadius: 12,
            ),
            SizedBox(height: 20.spMin),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: TextStyle(fontSize: 13.spMin),
                ),
                GestureDetector(
                  onTap:
                      authState.isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                                context,
                                RouteName.signUpView,
                              ),
                  child: Text(
                    'Register',
                    style: TextStyle(
                      fontSize: 13.spMin,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      AppFlushbar.warning(context, message: 'Enter your email first');
      return;
    }
    final ok = await ref.read(authProvider.notifier).sendPasswordReset(email);
    if (!mounted) return;
    if (ok) {
      AppFlushbar.success(context, message: 'Password reset email sent');
    } else {
      final err = ref.read(authProvider).errorMessage;
      AppFlushbar.error(context, message: err ?? 'Could not send reset email');
    }
  }
}

/// Shared labeled text field used across the auth screens.
class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onSubmitted;

  const _AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      onFieldSubmitted: onSubmitted,
      style: TextStyle(fontSize: 14.spMin),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 13.spMin),
        hintStyle: TextStyle(fontSize: 12.spMin, color: Colors.grey),
        prefixIcon: Icon(icon, size: 20.spMin, color: AppColors.primary),
        suffixIcon: suffix,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.spMin,
          vertical: 14.spMin,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}

/// Exported so the register screen can reuse the exact same field styling.
class AuthField extends _AuthField {
  const AuthField({
    super.key,
    required super.controller,
    required super.label,
    required super.hint,
    required super.icon,
    super.obscure,
    super.suffix,
    super.keyboardType,
    super.validator,
    super.onSubmitted,
  });
}
