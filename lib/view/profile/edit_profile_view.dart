import 'package:desktopapp/res/colors/app_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:desktopapp/res/components/app_button.dart';
import 'package:desktopapp/res/components/text_field_widget.dart';
import 'package:desktopapp/res/validator/validator_text_field.dart';
import 'package:desktopapp/utils/utils.dart';
import 'package:desktopapp/view_models/providers/profile_provider.dart';
import 'package:desktopapp/view_models/providers/sales_provider.dart';
import '../../res/assets/image_assets.dart';
import '../../res/components/app_bar_widget.dart';
import '../../res/components/app_flushbar.dart';
import '../../res/components/app_icon.dart';
import '../../routes/routes_name.dart';

class EditProfile extends ConsumerStatefulWidget {
  const EditProfile({super.key});

  @override
  ConsumerState<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends ConsumerState<EditProfile> {
  final TextEditingController ownerNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();
  final TextEditingController shopTaglineController = TextEditingController();
  final TextEditingController shopAddressController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController();
  final TextEditingController whatsappController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController twitterController = TextEditingController();
  final TextEditingController instagramController = TextEditingController();
  final FocusNode ownerNameNode = FocusNode();
  final FocusNode shopNameNode = FocusNode();
  final FocusNode shopTaglineNode = FocusNode();
  final FocusNode shopAddressNode = FocusNode();
  final FocusNode phoneNumberNode = FocusNode();
  final FocusNode btnNode = FocusNode();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  List<BankFormControllers> bankControllers = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final users = await ref.read(databaseServiceProvider).getUsers();
    if (users.isNotEmpty) {
      final user = users.first;
      final formNotifier = ref.read(profileProvider.notifier);

      ownerNameController.text = user.ownerName;
      emailController.text = user.email;
      shopNameController.text = user.shopName;
      shopTaglineController.text = user.shopTagline ?? '';
      shopAddressController.text = user.shopAddress;
      phoneNumberController.text = user.phoneNumber;
      whatsappController.text = user.whatsapp ?? '';
      facebookController.text = user.facebook ?? '';
      twitterController.text = user.twitter ?? '';
      instagramController.text = user.instagram ?? '';
      for (var ctrl in bankControllers) {
        ctrl.dispose();
      }
      bankControllers.clear();
      bankControllers =
          user.bankDetails.map((bank) {
            final ctrl = BankFormControllers();
            ctrl.bankName.text = bank.bankName;
            ctrl.accountNumber.text = bank.accountNumber;
            ctrl.ifscCode.text = bank.ifscCode;
            return ctrl;
          }).toList();

      formNotifier.updateOwnerName(user.ownerName);
      formNotifier.updateShopName(user.shopName);
      formNotifier.updateShopTagline(user.shopTagline ?? '');
      formNotifier.updateShopAddress(user.shopAddress);
      formNotifier.updatePhoneNumber(user.phoneNumber);
      formNotifier.updateWhatsapp(user.whatsapp ?? '');
      formNotifier.updateFacebook(user.facebook ?? '');
      formNotifier.updateTwitter(user.twitter ?? '');
      formNotifier.updateInstagram(user.instagram ?? '');
    }
  }

  @override
  void dispose() {
    ownerNameController.dispose();
    emailController.dispose();
    shopNameController.dispose();
    shopTaglineController.dispose();
    shopAddressController.dispose();
    phoneNumberController.dispose();
    whatsappController.dispose();
    facebookController.dispose();
    twitterController.dispose();
    instagramController.dispose();
    ownerNameNode.dispose();
    shopNameNode.dispose();
    shopTaglineNode.dispose();
    shopAddressNode.dispose();
    phoneNumberNode.dispose();
    btnNode.dispose();
    for (var ctrl in bankControllers) {
      ctrl.dispose();
    }
    bankControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final formNotifier = ref.read(profileProvider.notifier);

    if (bankControllers.length < profileState.bankDetails.length) {
      for (
        var i = bankControllers.length;
        i < profileState.bankDetails.length;
        i++
      ) {
        bankControllers.add(BankFormControllers());
      }
    } else if (bankControllers.length > profileState.bankDetails.length) {
      for (
        var i = profileState.bankDetails.length;
        i < bankControllers.length;
        i++
      ) {
        bankControllers[i].dispose();
      }
      bankControllers = bankControllers.sublist(
        0,
        profileState.bankDetails.length,
      );
    }

    ref.listen<ProfileState>(profileProvider, (previous, next) {
      if (next.isLoading == false &&
          previous?.isLoading == true &&
          next.errorMessage == null) {
        // Capture navigator before async gap
        final navigator = Navigator.of(context);
        final canPop = Navigator.canPop(context);
        // Show flushbar and navigate after it's dismissed
        AppFlushbar.showAndNavigate(
          context,
          message: 'Profile updated successfully',
          type: FlushbarType.success,
          duration: const Duration(seconds: 2),
          onDismissed: () {
            if (!mounted) return;
            // Check if we can pop (i.e., there's a previous route)
            // If not, navigate to main screen (first-time setup flow)
            if (canPop) {
              navigator.pop();
            } else {
              navigator.pushReplacementNamed(RouteName.mainScreen);
            }
          },
        );
      }
    });

    // Utility methods for responsive checks

    bool isDesktop(BuildContext context) =>
        MediaQuery.of(context).size.width >= 1100;

    return Scaffold(
      appBar: AppBarWidget.customAppBar(
        title: 'Edit Profile',
        context: context,
        backIconWidget: AppIcon(
          // color: Colors.grey,
          size: 18.spMin,
          defaultIcon: Icons.arrow_back_ios_new_rounded,
          win11IconPath: ImageAssets.win11Back,
        ),
      ),
      body: SingleChildScrollView(
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
          child: Form(
            key: _formKey,
            child:
                isDesktop(context)
                    ? Column(
                      children: [
                        // User Image Picker
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 500),
                          opacity: 1.0,
                          child: GestureDetector(
                            onTap: () async {
                              await formNotifier.pickUserImage();
                            },
                            child: Column(
                              children: [
                                Container(
                                  height: 150.spMin,
                                  width: 150.spMin,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child:
                                      profileState.userImage != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                            child: Image.file(
                                              profileState.userImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          )
                                          : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                AppIcon(
                                                  color: Colors.grey,
                                                  size: 40.spMin,
                                                  defaultIcon:
                                                      TablerIcons.photo_plus,
                                                  win11IconPath:
                                                      ImageAssets.win11AddImage,
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                        // Shop Logo Picker
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 500),
                          opacity: 1.0,
                          child: GestureDetector(
                            onTap: () async {
                              await formNotifier.pickShopLogo();
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.h),
                              height: 150.spMin,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child:
                                  profileState.shopLogo != null
                                      ? Image.file(
                                        profileState.shopLogo!,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                      : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AppIcon(
                                              defaultIcon: TablerIcons.photo_up,
                                              win11IconPath:
                                                  ImageAssets.win11List,
                                              size: 40.spMin,
                                              color: Colors.grey,
                                            ),

                                            Text(
                                              'Tap to add shop logo',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12.spMin,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        // Text Fields in Rows for Desktop
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedSlide(
                                offset: Offset(0, 0),
                                duration: Duration(milliseconds: 300),
                                child: CustomTextField(
                                  controller: ownerNameController,
                                  focusNode: ownerNameNode,
                                  hintText: 'Owner Name',
                                  prefixIcon: AppIcon(
                                    win11IconPath:
                                        ImageAssets.win11Administrator,
                                    defaultIcon: TablerIcons.user,
                                    size: 18.spMin,
                                  ),

                                  filled: true,
                                  enabled: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter owner name';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) {
                                    Utils.fieldFocusChange(
                                      context,
                                      ownerNameNode,
                                      shopNameNode,
                                    );
                                  },
                                  onChange: (value) {
                                    formNotifier.updateOwnerName(value ?? "");
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: CustomTextField(
                                controller: emailController,
                                hintText:
                                    formNotifier.isNewUser
                                        ? 'Email'
                                        : 'Email (cannot be changed)',
                                filled: true,
                                prefixIcon: AppIcon(
                                  win11IconPath: ImageAssets.win11Email,
                                  defaultIcon: TablerIcons.mail,
                                  size: 18.spMin,
                                ),
                                enabled: formNotifier.isNewUser,
                                keyboardType: TextInputType.emailAddress,
                                validator:
                                    formNotifier.isNewUser
                                        ? Validators.validateEmail
                                        : null,
                                onChange: (value) {
                                  formNotifier.updateEmail(value ?? "");
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedSlide(
                                offset: Offset(0, 0),
                                duration: Duration(milliseconds: 300),
                                child: CustomTextField(
                                  controller: shopNameController,
                                  focusNode: shopNameNode,
                                  filled: true,
                                  hintText: 'Shop Name',
                                  prefixIcon: AppIcon(
                                    win11IconPath: ImageAssets.win11Shop,
                                    defaultIcon: TablerIcons.building_store,
                                    size: 18.spMin,
                                  ),

                                  enabled: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a shop name';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) {
                                    Utils.fieldFocusChange(
                                      context,
                                      shopNameNode,
                                      shopTaglineNode,
                                    );
                                  },
                                  onChange: (value) {
                                    formNotifier.updateShopName(value ?? "");
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: AnimatedSlide(
                                offset: Offset(0, 0),
                                duration: Duration(milliseconds: 300),
                                child: CustomTextField(
                                  controller: shopTaglineController,
                                  focusNode: shopTaglineNode,
                                  hintText: 'Shop Tagline',
                                  prefixIcon: AppIcon(
                                    win11IconPath: ImageAssets.win11PriceTag,
                                    defaultIcon: TablerIcons.tag,
                                    size: 18.spMin,
                                  ),

                                  filled: true,
                                  enabled: true,
                                  onFieldSubmitted: (_) {
                                    Utils.fieldFocusChange(
                                      context,
                                      shopTaglineNode,
                                      shopAddressNode,
                                    );
                                  },
                                  onChange: (value) {
                                    formNotifier.updateShopTagline(value ?? "");
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10.h),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: AnimatedSlide(
                                offset: Offset(0, 0),
                                duration: Duration(milliseconds: 300),
                                child: CustomTextField(
                                  controller: shopAddressController,
                                  focusNode: shopAddressNode,
                                  filled: true,
                                  hintText: 'Shop Address',
                                  prefixIcon: AppIcon(
                                    win11IconPath: ImageAssets.win11Location,
                                    defaultIcon: TablerIcons.location,
                                    size: 18.spMin,
                                  ),
                                  enabled: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a shop address';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) {
                                    Utils.fieldFocusChange(
                                      context,
                                      shopAddressNode,
                                      phoneNumberNode,
                                    );
                                  },
                                  onChange: (value) {
                                    formNotifier.updateShopAddress(value ?? "");
                                    return null;
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: AnimatedSlide(
                                offset: Offset(0, 0),
                                duration: Duration(milliseconds: 300),
                                child: CustomTextField(
                                  controller: phoneNumberController,
                                  focusNode: phoneNumberNode,
                                  filled: true,
                                  hintText: 'Phone Number',
                                  prefixIcon: AppIcon(
                                    win11IconPath: ImageAssets.win11Phone,
                                    defaultIcon: TablerIcons.phone,
                                    size: 18.spMin,
                                  ),
                                  keyboardType: TextInputType.phone,
                                  enabled: true,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter a phone number';
                                    }
                                    if (!RegExp(
                                      r'^\+?[1-9]\d{1,14}$',
                                    ).hasMatch(value)) {
                                      return 'Please enter a valid phone number';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) {
                                    Utils.fieldFocusChange(
                                      context,
                                      phoneNumberNode,
                                      btnNode,
                                    );
                                  },
                                  onChange: (value) {
                                    formNotifier.updatePhoneNumber(value ?? "");
                                    return null;
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // Bank Details Section
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Details',
                              style: TextStyle(
                                fontSize: 18.spMin,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            profileState.bankDetails.isEmpty
                                ? Text(
                                  'No bank details added.',
                                  style: TextStyle(
                                    fontSize: 14.spMin,
                                    color: Colors.grey,
                                  ),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: profileState.bankDetails.length,
                                  itemBuilder: (context, index) {
                                    if (index >= bankControllers.length) {
                                      return SizedBox.shrink();
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          spacing: 8.w,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              child: AppIcon(
                                                win11IconPath:
                                                    ImageAssets.win11Cancel,
                                                defaultIcon:
                                                    TablerIcons
                                                        .square_rounded_x_filled,
                                                size: 18.spMin,
                                                color: Colors.red,
                                              ),

                                              onTap: () {
                                                bankControllers[index]
                                                    .dispose();
                                                bankControllers.removeAt(index);
                                                formNotifier.removeBankDetail(
                                                  index,
                                                );
                                              },
                                            ),
                                            Text(
                                              'Bank ${index + 1}',
                                              style: TextStyle(
                                                fontSize: 16.spMin,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5.h),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: CustomTextField(
                                                controller:
                                                    bankControllers[index]
                                                        .bankName,
                                                hintText: 'Bank Name',
                                                prefixIcon: AppIcon(
                                                  win11IconPath:
                                                      ImageAssets.win11Bank,
                                                  defaultIcon:
                                                      TablerIcons.building_bank,
                                                  size: 18.spMin,
                                                ),

                                                enabled: true,
                                                filled: true,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter bank name';
                                                  }
                                                  return null;
                                                },
                                                onChange: (value) {
                                                  formNotifier.updateBankName(
                                                    index,
                                                    value ?? "",
                                                  );
                                                  return null;
                                                },
                                              ),
                                            ),
                                            SizedBox(width: 10.w),
                                            Expanded(
                                              child: CustomTextField(
                                                controller:
                                                    bankControllers[index]
                                                        .ifscCode,
                                                hintText: 'IFSC Code',
                                                prefixIcon: AppIcon(
                                                  win11IconPath:
                                                      ImageAssets.win11Mun,
                                                  defaultIcon:
                                                      TablerIcons.building_bank,
                                                  size: 18.spMin,
                                                ),
                                                enabled: true,
                                                filled: true,
                                                validator: (value) {
                                                  if (value == null ||
                                                      value.isEmpty) {
                                                    return 'Please enter IFSC code';
                                                  }
                                                  return null;
                                                },
                                                onChange: (value) {
                                                  formNotifier.updateIfscCode(
                                                    index,
                                                    value ?? "",
                                                  );
                                                  return null;
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10.h),
                                        CustomTextField(
                                          controller:
                                              bankControllers[index]
                                                  .accountNumber,
                                          hintText: 'Account Number',
                                          prefixIcon: AppIcon(
                                            win11IconPath:
                                                ImageAssets.win11Card,
                                            defaultIcon:
                                                TablerIcons.credit_card_pay,
                                            size: 18.spMin,
                                          ),

                                          enabled: true,
                                          filled: true,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter account number';
                                            }
                                            return null;
                                          },
                                          onChange: (value) {
                                            formNotifier.updateAccountNumber(
                                              index,
                                              value ?? "",
                                            );
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 10.h),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            GestureDetector(
                                              onTap: () async {
                                                await formNotifier.pickQrCode(
                                                  index,
                                                );
                                              },
                                              child: Container(
                                                height: 100.h,
                                                width: 100.h,
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.r,
                                                      ),
                                                ),
                                                child:
                                                    profileState
                                                                .bankDetails[index]
                                                                .qrCode !=
                                                            null
                                                        ? ClipRRect(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                8.5.r,
                                                              ),
                                                          child: Image.file(
                                                            profileState
                                                                .bankDetails[index]
                                                                .qrCode!,
                                                            fit: BoxFit.cover,
                                                          ),
                                                        )
                                                        : Center(
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              AppIcon(
                                                                win11IconPath:
                                                                    ImageAssets
                                                                        .win11QrCode,
                                                                defaultIcon:
                                                                    TablerIcons
                                                                        .qrcode,
                                                                size: 40.spMin,
                                                                color:
                                                                    Colors.grey,
                                                              ),

                                                              Text(
                                                                'Tap to add QR code',
                                                                style: TextStyle(
                                                                  color:
                                                                      Colors
                                                                          .grey,
                                                                  fontSize:
                                                                      12.spMin,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 10.h),
                                        Divider(),
                                      ],
                                    );
                                  },
                                ),
                            Container(
                              height: 35.h,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight2,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: InkWell(
                                onTap: () {
                                  bankControllers.add(BankFormControllers());
                                  formNotifier.addBankDetail();
                                },
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AppIcon(
                                        win11IconPath: ImageAssets.win11Add,
                                        defaultIcon: TablerIcons.plus,
                                      ),
                                      Text('Add Bank'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        // Social Media Section
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Social Media',
                              style: TextStyle(
                                fontSize: 18.spMin,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: whatsappController,
                                    hintText: 'WhatsApp',
                                    prefixIcon: AppIcon(
                                      win11IconPath: ImageAssets.win11Whatsapp,
                                      defaultIcon: TablerIcons.message,
                                      size: 18.spMin,
                                    ),

                                    enabled: true,
                                    filled: true,
                                    onChange: (value) {
                                      formNotifier.updateWhatsapp(value ?? "");
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: CustomTextField(
                                    controller: facebookController,
                                    hintText: 'Facebook',
                                    prefixIcon: AppIcon(
                                      win11IconPath: ImageAssets.win11Facebook,
                                      defaultIcon: TablerIcons.brand_facebook,
                                      size: 18.spMin,
                                    ),

                                    enabled: true,
                                    filled: true,
                                    onChange: (value) {
                                      formNotifier.updateFacebook(value ?? '');
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 10.h),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomTextField(
                                    controller: twitterController,
                                    hintText: 'X (Twitter)',
                                    prefixIcon: AppIcon(
                                      win11IconPath: ImageAssets.win11X,
                                      defaultIcon: TablerIcons.brand_x,
                                      size: 18.spMin,
                                    ),

                                    enabled: true,
                                    filled: true,
                                    onChange: (value) {
                                      formNotifier.updateTwitter(value ?? "");
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  child: CustomTextField(
                                    controller: instagramController,
                                    hintText: 'Instagram',
                                    prefixIcon: AppIcon(
                                      win11IconPath: ImageAssets.win11Instagram,
                                      defaultIcon: TablerIcons.brand_instagram,
                                      size: 18.spMin,
                                    ),

                                    enabled: true,
                                    filled: true,
                                    onChange: (value) {
                                      formNotifier.updateInstagram(value ?? "");
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30.h),
                            if (profileState.errorMessage != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: Text(
                                  profileState.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14.spMin,
                                  ),
                                ),
                              ),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: AppButton().primaryButton(
                                key: ValueKey<bool>(true),
                                text: 'Update Profile',
                                focusNode: btnNode,
                                isLoading: profileState.isLoading,
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await formNotifier.submitProfile();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                    : Column(
                      // Original Column layout for mobile and tablet
                      children: [
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 500),
                          opacity: 1.0,
                          child: GestureDetector(
                            onTap: () async {
                              await formNotifier.pickUserImage();
                            },
                            child: Column(
                              children: [
                                Container(
                                  height: 150.spMin,
                                  width: 150.spMin,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: AppColors.primary,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(100),
                                  ),
                                  child:
                                      profileState.userImage != null
                                          ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                            child: Image.file(
                                              profileState.userImage!,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                            ),
                                          )
                                          : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                AppIcon(
                                                  win11IconPath:
                                                      ImageAssets.win11AddImage,
                                                  defaultIcon:
                                                      TablerIcons.photo_plus,
                                                  size: 40.spMin,
                                                  color: Colors.grey,
                                                ),
                                              ],
                                            ),
                                          ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 15.h),
                        AnimatedOpacity(
                          duration: Duration(milliseconds: 500),
                          opacity: 1.0,
                          child: GestureDetector(
                            onTap: () async {
                              await formNotifier.pickShopLogo();
                            },
                            child: Container(
                              padding: EdgeInsets.all(8.h),
                              height: 150.spMin,
                              decoration: BoxDecoration(
                                color: Colors.transparent,
                                border: Border.all(
                                  color: AppColors.primary,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child:
                                  profileState.shopLogo != null
                                      ? Image.file(
                                        profileState.shopLogo!,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                      : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            AppIcon(
                                              win11IconPath:
                                                  ImageAssets.win11AddImage,
                                              defaultIcon: TablerIcons.photo_up,
                                              size: 40.spMin,
                                              color: Colors.grey,
                                            ),

                                            Text(
                                              'Tap to add shop logo',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12.spMin,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10.h),
                        AnimatedSlide(
                          offset: Offset(0, 0),
                          duration: Duration(milliseconds: 300),
                          child: CustomTextField(
                            controller: ownerNameController,
                            focusNode: ownerNameNode,
                            hintText: 'Owner Name',
                            prefixIcon: AppIcon(
                              win11IconPath: ImageAssets.win11Administrator,
                              defaultIcon: TablerIcons.user,
                              size: 18.spMin,
                            ),

                            filled: true,
                            enabled: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter owner name';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              Utils.fieldFocusChange(
                                context,
                                ownerNameNode,
                                shopNameNode,
                              );
                            },
                            onChange: (value) {
                              formNotifier.updateOwnerName(value ?? "");
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                        CustomTextField(
                          controller: emailController,
                          hintText:
                              formNotifier.isNewUser
                                  ? 'Email'
                                  : 'Email (cannot be changed)',
                          filled: true,
                          prefixIcon: AppIcon(
                            win11IconPath: ImageAssets.win11Email,
                            defaultIcon: TablerIcons.mail,
                            size: 18.spMin,
                          ),

                          enabled: formNotifier.isNewUser,
                          keyboardType: TextInputType.emailAddress,
                          validator:
                              formNotifier.isNewUser
                                  ? Validators.validateEmail
                                  : null,
                          onChange: (value) {
                            formNotifier.updateEmail(value ?? "");
                            return null;
                          },
                        ),
                        SizedBox(height: 10.h),
                        AnimatedSlide(
                          offset: Offset(0, 0),
                          duration: Duration(milliseconds: 300),
                          child: CustomTextField(
                            controller: shopNameController,
                            focusNode: shopNameNode,
                            filled: true,
                            hintText: 'Shop Name',
                            prefixIcon: AppIcon(
                              win11IconPath: ImageAssets.win11Shop,
                              defaultIcon: TablerIcons.building_store,
                              size: 18.spMin,
                            ),

                            enabled: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a shop name';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              Utils.fieldFocusChange(
                                context,
                                shopNameNode,
                                shopTaglineNode,
                              );
                            },
                            onChange: (value) {
                              formNotifier.updateShopName(value ?? "");
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                        AnimatedSlide(
                          offset: Offset(0, 0),
                          duration: Duration(milliseconds: 300),
                          child: CustomTextField(
                            controller: shopTaglineController,
                            focusNode: shopTaglineNode,
                            hintText: 'Shop Tagline',
                            prefixIcon: AppIcon(
                              win11IconPath: ImageAssets.win11PriceTag,
                              defaultIcon: TablerIcons.tag,
                              size: 18.spMin,
                            ),

                            filled: true,
                            enabled: true,
                            onFieldSubmitted: (_) {
                              Utils.fieldFocusChange(
                                context,
                                shopTaglineNode,
                                shopAddressNode,
                              );
                            },
                            onChange: (value) {
                              formNotifier.updateShopTagline(value ?? "");
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                        AnimatedSlide(
                          offset: Offset(0, 0),
                          duration: Duration(milliseconds: 300),
                          child: CustomTextField(
                            controller: shopAddressController,
                            focusNode: shopAddressNode,
                            filled: true,
                            hintText: 'Shop Address',
                            prefixIcon: AppIcon(
                              win11IconPath: ImageAssets.win11Location,
                              defaultIcon: TablerIcons.location,
                              size: 18.spMin,
                            ),

                            enabled: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a shop address';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              Utils.fieldFocusChange(
                                context,
                                shopAddressNode,
                                phoneNumberNode,
                              );
                            },
                            onChange: (value) {
                              formNotifier.updateShopAddress(value ?? "");
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 10.h),
                        AnimatedSlide(
                          offset: Offset(0, 0),
                          duration: Duration(milliseconds: 300),
                          child: CustomTextField(
                            controller: phoneNumberController,
                            focusNode: phoneNumberNode,
                            filled: true,
                            hintText: 'Phone Number',
                            prefixIcon: AppIcon(
                              win11IconPath: ImageAssets.win11Phone,
                              defaultIcon: TablerIcons.phone,
                              size: 18.spMin,
                            ),
                            keyboardType: TextInputType.phone,
                            enabled: true,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a phone number';
                              }
                              if (!RegExp(
                                r'^\+?[1-9]\d{1,14}$',
                              ).hasMatch(value)) {
                                return 'Please enter a valid phone number';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              Utils.fieldFocusChange(
                                context,
                                phoneNumberNode,
                                btnNode,
                              );
                            },
                            onChange: (value) {
                              formNotifier.updatePhoneNumber(value ?? "");
                              return null;
                            },
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bank Details',
                              style: TextStyle(
                                fontSize: 18.spMin,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            profileState.bankDetails.isEmpty
                                ? Text(
                                  'No bank details added.',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    color: Colors.grey,
                                  ),
                                )
                                : ListView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: profileState.bankDetails.length,
                                  itemBuilder: (context, index) {
                                    if (index >= bankControllers.length) {
                                      return SizedBox.shrink();
                                    }
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          spacing: 8.w,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            InkWell(
                                              child: AppIcon(
                                                win11IconPath:
                                                    ImageAssets.win11Cancel,
                                                defaultIcon:
                                                    TablerIcons
                                                        .square_rounded_x_filled,
                                                color: Colors.red,
                                                size: 18.spMin,
                                              ),

                                              onTap: () {
                                                bankControllers[index]
                                                    .dispose();
                                                bankControllers.removeAt(index);
                                                formNotifier.removeBankDetail(
                                                  index,
                                                );
                                              },
                                            ),
                                            Text(
                                              'Bank ${index + 1}',
                                              style: TextStyle(
                                                fontSize: 16.spMin,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 5.h),
                                        CustomTextField(
                                          controller:
                                              bankControllers[index].bankName,
                                          hintText: 'Bank Name',
                                          prefixIcon: AppIcon(
                                            win11IconPath:
                                                ImageAssets.win11Bank,
                                            defaultIcon:
                                                TablerIcons.building_bank,
                                            size: 18.spMin,
                                          ),

                                          enabled: true,
                                          filled: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter bank name';
                                            }
                                            return null;
                                          },
                                          onChange: (value) {
                                            formNotifier.updateBankName(
                                              index,
                                              value ?? "",
                                            );
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 10.h),
                                        CustomTextField(
                                          controller:
                                              bankControllers[index].ifscCode,
                                          hintText: 'IFSC Code',
                                          prefixIcon: AppIcon(
                                            win11IconPath: ImageAssets.win11Mun,
                                            defaultIcon: TablerIcons.code,
                                            size: 18.spMin,
                                          ),

                                          enabled: true,
                                          filled: true,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter IFSC code';
                                            }
                                            return null;
                                          },
                                          onChange: (value) {
                                            formNotifier.updateIfscCode(
                                              index,
                                              value ?? "",
                                            );
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 10.h),
                                        CustomTextField(
                                          controller:
                                              bankControllers[index]
                                                  .accountNumber,
                                          hintText: 'Account Number',
                                          prefixIcon: AppIcon(
                                            win11IconPath:
                                                ImageAssets.win11Card,
                                            defaultIcon:
                                                TablerIcons.credit_card_pay,
                                            size: 18.spMin,
                                          ),

                                          enabled: true,
                                          filled: true,
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please enter account number';
                                            }
                                            return null;
                                          },
                                          onChange: (value) {
                                            formNotifier.updateAccountNumber(
                                              index,
                                              value ?? "",
                                            );
                                            return null;
                                          },
                                        ),
                                        SizedBox(height: 10.h),
                                        GestureDetector(
                                          onTap: () async {
                                            await formNotifier.pickQrCode(
                                              index,
                                            );
                                          },
                                          child: Container(
                                            height: 100.h,
                                            width: 100.h,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: Colors.grey,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8.r),
                                            ),
                                            child:
                                                profileState
                                                            .bankDetails[index]
                                                            .qrCode !=
                                                        null
                                                    ? ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8.5.r,
                                                          ),
                                                      child: Image.file(
                                                        profileState
                                                            .bankDetails[index]
                                                            .qrCode!,
                                                        fit: BoxFit.cover,
                                                      ),
                                                    )
                                                    : Center(
                                                      child: Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          AppIcon(
                                                            win11IconPath:
                                                                ImageAssets
                                                                    .win11QrCode,
                                                            defaultIcon:
                                                                TablerIcons
                                                                    .qrcode,
                                                            size: 40.spMin,
                                                            color: Colors.grey,
                                                          ),

                                                          Text(
                                                            'Tap to add QR code',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.grey,
                                                              fontSize:
                                                                  10.spMin,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                          ),
                                        ),
                                        SizedBox(height: 10.h),
                                        Divider(),
                                      ],
                                    );
                                  },
                                ),
                            Container(
                              height: 35.h,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight2,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              child: InkWell(
                                onTap: () {
                                  bankControllers.add(BankFormControllers());
                                  formNotifier.addBankDetail();
                                },
                                child: Center(
                                  child: Row(
                                    spacing: 5.spMin,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      AppIcon(
                                        win11IconPath: ImageAssets.win11Add,
                                        defaultIcon: TablerIcons.plus,
                                        size: 18.spMin,
                                      ),
                                      Text('Add Bank'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20.h),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Text(
                              'Social Media',
                              style: TextStyle(
                                fontSize: 18.spMin,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 10.h),
                            CustomTextField(
                              controller: whatsappController,
                              hintText: 'WhatsApp',
                              prefixIcon: AppIcon(
                                win11IconPath: ImageAssets.win11Whatsapp,
                                defaultIcon: TablerIcons.message,
                                size: 18.spMin,
                              ),

                              enabled: true,
                              filled: true,
                              onChange: (value) {
                                formNotifier.updateWhatsapp(value ?? "");
                                return null;
                              },
                            ),
                            SizedBox(height: 10.h),
                            CustomTextField(
                              controller: facebookController,
                              hintText: 'Facebook',
                              prefixIcon: AppIcon(
                                win11IconPath: ImageAssets.win11Facebook,
                                defaultIcon: TablerIcons.brand_facebook,
                                size: 18.spMin,
                              ),

                              enabled: true,
                              filled: true,
                              onChange: (value) {
                                formNotifier.updateFacebook(value ?? "");
                                return null;
                              },
                            ),
                            SizedBox(height: 10.h),
                            CustomTextField(
                              controller: twitterController,
                              hintText: 'X (Twitter)',

                              prefixIcon: AppIcon(
                                win11IconPath: ImageAssets.win11X,
                                defaultIcon: TablerIcons.brand_x,
                                size: 18.spMin,
                              ),

                              enabled: true,
                              filled: true,
                              onChange: (value) {
                                formNotifier.updateTwitter(value ?? "");
                                return null;
                              },
                            ),
                            SizedBox(height: 10.h),
                            CustomTextField(
                              controller: instagramController,
                              hintText: 'Instagram',
                              prefixIcon: AppIcon(
                                win11IconPath: ImageAssets.win11Instagram,
                                defaultIcon: TablerIcons.brand_instagram,
                                size: 18.spMin,
                              ),

                              enabled: true,
                              filled: true,
                              onChange: (value) {
                                formNotifier.updateInstagram(value ?? "");

                                return null;
                              },
                            ),
                            SizedBox(height: 50.h),
                            if (profileState.errorMessage != null)
                              Padding(
                                padding: EdgeInsets.only(bottom: 10.h),
                                child: Text(
                                  profileState.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 14.spMin,
                                  ),
                                ),
                              ),
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 300),
                              child: AppButton().primaryButton(
                                key: ValueKey<bool>(true),
                                text: 'Update Profile',
                                focusNode: btnNode,
                                isLoading: profileState.isLoading,
                                onPressed: () async {
                                  if (_formKey.currentState!.validate()) {
                                    await formNotifier.submitProfile();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}

class BankFormControllers {
  TextEditingController bankName = TextEditingController();
  TextEditingController accountNumber = TextEditingController();
  TextEditingController ifscCode = TextEditingController();

  void dispose() {
    bankName.dispose();
    accountNumber.dispose();
    ifscCode.dispose();
  }
}
