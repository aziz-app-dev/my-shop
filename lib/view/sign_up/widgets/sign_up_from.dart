// ignore_for_file: use_build_context_synchronously

import 'package:desktopapp/res/colors/app_color.dart';
import 'package:desktopapp/res/components/app_text_widgrt.dart';
import 'package:desktopapp/utils/app_sizes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/text_field_widget.dart';
import 'package:desktopapp/res/validator/validator_text_field.dart';
import 'package:desktopapp/utils/utils.dart';

import '../../../res/components/app_flushbar.dart';
import '../../../routes/routes_name.dart';
import '../../../view_models/providers/add_prduct_provider.dart';
import '../../../view_models/providers/profile_provider.dart';

class UserInfoFormFields extends ConsumerStatefulWidget {
  const UserInfoFormFields({super.key});

  @override
  ConsumerState<UserInfoFormFields> createState() => _UserInfoFormFieldsState();
}

class _UserInfoFormFieldsState extends ConsumerState<UserInfoFormFields> {
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopAddressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final FocusNode ownerNameNode = FocusNode();
  final FocusNode emailNode = FocusNode();
  final FocusNode shopNameNode = FocusNode();
  final FocusNode shopAddressNode = FocusNode();
  final FocusNode phoneNumberNode = FocusNode();
  final FocusNode btnNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Load user data into ProfileState
    ref.read(profileProvider.notifier).loadUserData().then((_) {
      final profileState = ref.read(profileProvider);
      ownerNameController.text = profileState.ownerName ?? '';
      emailController.text = profileState.email ?? '';
      shopNameController.text = profileState.shopName ?? '';
      shopAddressController.text = profileState.shopAddress ?? '';
      phoneNumberController.text = profileState.phoneNumber ?? '';
    });
  }

  @override
  void dispose() {
    ownerNameController.dispose();
    emailController.dispose();
    shopNameController.dispose();
    shopAddressController.dispose();
    phoneNumberController.dispose();
    ownerNameNode.dispose();
    emailNode.dispose();
    shopNameNode.dispose();
    shopAddressNode.dispose();
    phoneNumberNode.dispose();
    btnNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formState = ref.watch(profileProvider);
    final formNotifier = ref.read(profileProvider.notifier);

    return Form(
      key: _formKey,
      child: Column(
        spacing: 5.w,
        children: [
          // User Image Picker
          GestureDetector(
            onTap: () async {
              await formNotifier.pickUserImage();
            },
            child: Container(
              height: 100.h,
              width: 100.h,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textFieldsColor),
                borderRadius: BorderRadius.all(Radius.circular(100)),
              ),
              child:
                  formState.userImage != null
                      ? ClipRRect(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        child: Image.file(
                          formState.userImage!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder:
                              (context, error, stackTrace) => Icon(
                                Icons.person,
                                size: 40.sp,
                                color: AppColors.iconColor,
                              ),
                        ),
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_add,
                              size: 40.spMin,
                              color: AppColors.iconColor,
                            ),
                          ],
                        ),
                      ),
            ),
          ),
          SizedBox(height: 10.h),
          // Shop Logo Picker
          GestureDetector(
            onTap: () async {
              await formNotifier.pickShopLogo();
            },
            child: Container(
              height: 150.h,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textFieldsColor),
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
              ),
              child:
                  formState.shopLogo != null
                      ? Image.file(
                        formState.shopLogo!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      )
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store,
                              size: 40.spMin,
                              color: AppColors.iconColor,
                            ),
                            Text(
                              'Tap to add shop logo',
                              style: TextStyle(
                                color: AppColors.textFieldsColor,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
          // Owner Name Field
          CustomTextField(
            controller: ownerNameController,
            focusNode: ownerNameNode,
            hintText: 'Enter Owner Name',
            iconPerfix: TablerIcons.user,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter owner name';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              Utils.fieldFocusChange(context, ownerNameNode, emailNode);
            },
            onChange: (value) {
              formNotifier.updateOwnerName(value ?? "");
              return null;
            },
          ),
          // Email Field
          CustomTextField(
            controller: emailController,
            focusNode: emailNode,
            hintText: 'Enter Your Email',
            iconPerfix: TablerIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: Validators.validateEmail,
            onFieldSubmitted: (_) {
              Utils.fieldFocusChange(context, emailNode, shopNameNode);
            },
            onChange: (value) {
              formNotifier.updateEmail(value ?? "");
              return null;
            },
          ),
          // Shop Name Field
          CustomTextField(
            controller: shopNameController,
            focusNode: shopNameNode,
            hintText: 'Enter Shop Name',
            iconPerfix: TablerIcons.building_store,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a shop name';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              Utils.fieldFocusChange(context, shopNameNode, shopAddressNode);
            },
            onChange: (value) {
              formNotifier.updateShopName(value ?? "");
              return null;
            },
          ),
          // Shop Address Field
          CustomTextField(
            controller: shopAddressController,
            focusNode: shopAddressNode,
            hintText: 'Enter Shop Address',
            iconPerfix: TablerIcons.location,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a shop address';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              Utils.fieldFocusChange(context, shopAddressNode, phoneNumberNode);
            },
            onChange: (value) {
              formNotifier.updateShopAddress(value ?? "");
              return null;
            },
          ),
          // Phone Number Field
          CustomTextField(
            controller: phoneNumberController,
            focusNode: phoneNumberNode,
            hintText: 'Enter Phone Number',
            iconPerfix: TablerIcons.phone,
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a phone number';
              }
              if (!RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(value)) {
                return 'Please enter a valid phone number';
              }
              return null;
            },
            onFieldSubmitted: (_) {
              Utils.fieldFocusChange(context, phoneNumberNode, btnNode);
            },
            onChange: (value) {
              formNotifier.updatePhoneNumber(value ?? "");
              return null;
            },
          ),
          // Error Message
          if (formState.errorMessage != null)
            Padding(
              padding: EdgeInsets.only(bottom: 10.h),
              child: Text(
                formState.errorMessage!,
                style: TextStyle(color: Colors.red, fontSize: 14.sp),
              ),
            ),
          // Submit Button
          AppButton().primaryButton(
            text: 'Save Changes',
            focusNode: btnNode,
            isLoading: formState.isLoading,
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final success = await formNotifier.submitProfile();
                if (success) {
                  AppFlushbar.success(
                    context,
                    message: 'Profile updated successfully',
                  );
                }
              }
            },
          ),
          SizedBox(height: 20.h),
          // Navigate to Login
          FutureBuilder<bool>(
            future: _hasExistingUsers(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    smText(text: 'Already have an account? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacementNamed(
                          context,
                          RouteName.loginView,
                        );
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 14.spMin,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
    );
  }

  Future<bool> _hasExistingUsers() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      await databaseService.initialize();
      final users = await databaseService.getUsers();
      return users.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
