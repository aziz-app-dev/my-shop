import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../res/colors/app_color.dart';
import '../../res/components/app_button.dart';
import '../../res/components/app_flushbar.dart';
import '../../routes/routes_name.dart';
import '../../view_models/providers/auth_provider.dart';
import '../login/login_view.dart' show AuthField;
import '../login/widgets/auth_scaffold.dart';

/// Step 1 of registration: create the Firebase account (email + password).
/// On success it routes to the shop-info setup page ([RouteName.profileEdit]),
/// which collects the full shop details and then continues to Home. This keeps
/// the single, complete shop-info form in one place.
class SignUpView extends ConsumerStatefulWidget {
  const SignUpView({super.key});

  @override
  ConsumerState<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends ConsumerState<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final user = await ref.read(authProvider.notifier).register(
          email: _emailCtrl.text,
          password: _passwordCtrl.text,
        );

    if (!mounted) return;
    if (user == null) {
      final err = ref.read(authProvider).errorMessage;
      AppFlushbar.error(context, message: err ?? 'Registration failed');
      return;
    }

    AppFlushbar.success(context, message: 'Account created! Set up your shop.');
    // Continue to the full shop-info setup, which navigates to Home on save.
    Navigator.pushReplacementNamed(context, RouteName.profileEdit);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return AuthScaffold(
      title: 'Create account',
      subtitle: 'Register to set up your shop',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthField(
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
            AuthField(
              controller: _passwordCtrl,
              label: 'Password',
              hint: 'At least 6 characters',
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
                if (v.length < 6) return 'Use at least 6 characters';
                return null;
              },
            ),
            SizedBox(height: 16.spMin),
            AuthField(
              controller: _confirmCtrl,
              label: 'Confirm password',
              hint: 'Re-enter your password',
              icon: Icons.lock_outline,
              obscure: _obscureConfirm,
              suffix: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  size: 20.spMin,
                ),
                onPressed:
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Confirm your password';
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
              onSubmitted: (_) => _register(),
            ),
            SizedBox(height: 24.spMin),
            AppButton().primaryButton(
              text: 'Create Account',
              isLoading: authState.isLoading,
              onPressed: _register,
              height: 48.spMin,
              borderRadius: 12,
            ),
            SizedBox(height: 20.spMin),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 13.spMin),
                ),
                GestureDetector(
                  onTap:
                      authState.isLoading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                                context,
                                RouteName.loginView,
                              ),
                  child: Text(
                    'Sign In',
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
}
