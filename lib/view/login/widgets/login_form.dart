import 'dart:io';

import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/user/user_model.dart';
import '../../../routes/routes_name.dart';
import '../../../view_models/providers/add_prduct_provider.dart';
import '../../../view_models/services/cloud_user/cloud_user_service.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final FocusNode _btnNode = FocusNode();
  final CloudUserService _cloudUserService = CloudUserService();

  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<User> _users = [];
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.initialize();
      final users = await databaseService.getUsers();
      setState(() {
        _users = users;
        _selectedUser = users.isNotEmpty ? users.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load users: $e';
        _isLoading = false;
      });
    }
  }

  void _login() async {
    if (_selectedUser == null) {
      setState(() {
        _errorMessage = 'No user selected';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    // Small delay for UX
    await Future.delayed(const Duration(milliseconds: 300));

    // Pull cloud profile by email (no Supabase Auth) and update local if needed.
    try {
      final remote = await _cloudUserService.getUserByEmail(_selectedUser!.email);
      if (remote != null) {
        // Prefer cloud values if they have more info, but keep local file paths if present.
        final merged = _cloudUserService.mergePreferLocal(
          local: _selectedUser!,
          remote: remote,
        );
        final databaseService = ref.read(databaseServiceProvider);
        await databaseService.updateUser(merged);
        _selectedUser = merged;
      } else {
        // Ensure the email exists in cloud for this device/user.
        await _cloudUserService.upsertUser(_selectedUser!);
      }
    } catch (e) {
      // If offline or schema/RLS issue, still allow local login.
      debugPrint('Cloud user sync failed: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, RouteName.mainScreen);
    }
  }

  @override
  void dispose() {
    _btnNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64.spMin, color: Colors.grey),
            SizedBox(height: 16.h),
            mdText(text: 'No users found'),
            SizedBox(height: 24.h),
            TextButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, RouteName.signUpView);
              },
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 14.spMin,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // User Profile Card
        _buildUserProfileCard(),

        // Error Message
        if (_errorMessage != null)
          Padding(
            padding: EdgeInsets.only(top: 10.h),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: 14.spMin),
            ),
          ),

        SizedBox(height: 20.h),

        // Login Button
        AppButton().primaryButton(
          text: 'Continue',
          focusNode: _btnNode,
          isLoading: _isSubmitting,
          onPressed: _login,
        ),

        // Switch User (if multiple users)
        if (_users.length > 1) ...[
          SizedBox(height: 16.h),
          TextButton.icon(
            onPressed: _showUserSelectionDialog,
            icon: Icon(Icons.switch_account, size: 18.spMin),
            label: Text(
              'Switch User',
              style: TextStyle(fontSize: 14.spMin),
            ),
          ),
        ],

        SizedBox(height: 20.h),

        // Navigate to Sign Up
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            smText(text: "Don't have an account? "),
            GestureDetector(
              onTap: () {
                Navigator.pushReplacementNamed(context, RouteName.signUpView);
              },
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 14.spMin,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserProfileCard() {
    return GestureDetector(
      onTap: _users.length > 1 ? _showUserSelectionDialog : null,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textFieldsColor),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            // Shop Logo
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: ClipOval(
                child: _selectedUser?.shopLogoPath != null &&
                        File(_selectedUser!.shopLogoPath!).existsSync()
                    ? Image.file(
                        File(_selectedUser!.shopLogoPath!),
                        fit: BoxFit.cover,
                        width: 80.w,
                        height: 80.w,
                      )
                    : Icon(
                        Icons.store,
                        size: 40.spMin,
                        color: AppColors.iconColor,
                      ),
              ),
            ),

            SizedBox(height: 12.h),

            // Shop Name
            lgTextBold(text: _selectedUser?.shopName ?? 'Shop Name'),

            SizedBox(height: 4.h),

            // Owner Name
            smText(text: _selectedUser?.ownerName ?? 'Owner'),

            if (_selectedUser?.shopTagline != null &&
                _selectedUser!.shopTagline!.isNotEmpty) ...[
              SizedBox(height: 4.h),
              xsText(
                text: _selectedUser!.shopTagline!,
                color: AppColors.grey500,
              ),
            ],

            if (_users.length > 1) ...[
              SizedBox(height: 8.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 14.spMin,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: 4.w),
                  xsText(text: 'Tap to switch user', color: AppColors.primary),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: mdTextBold(text: 'Select User'),
        content: SizedBox(
          width: 300.w,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              final isSelected = user.id == _selectedUser?.id;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight2,
                  backgroundImage: user.shopLogoPath != null &&
                          File(user.shopLogoPath!).existsSync()
                      ? FileImage(File(user.shopLogoPath!))
                      : null,
                  child: user.shopLogoPath == null ||
                          !File(user.shopLogoPath!).existsSync()
                      ? Icon(Icons.store, color: AppColors.primary)
                      : null,
                ),
                title: Text(user.shopName),
                subtitle: Text(user.ownerName),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: AppColors.primary)
                    : null,
                selected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedUser = user;
                    _errorMessage = null;
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}
