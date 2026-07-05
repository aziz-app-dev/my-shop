import 'dart:io';
import '../../models/user/user_model.dart';
import '../../utils/image_picker_helper.dart';
import '../services/database/database_services.dart'
    hide databaseServiceProvider;
import '../services/cloud_user/cloud_user_service.dart';
import 'sales_provider.dart';
import 'package:riverpod/legacy.dart';

class BankState {
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final File? qrCode;

  BankState({this.bankName, this.accountNumber, this.ifscCode, this.qrCode});

  BankState copyWith({
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    File? qrCode,
  }) {
    return BankState(
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      qrCode: qrCode ?? this.qrCode,
    );
  }
}

class ProfileState {
  final String? ownerName;
  final String? email;
  final String? shopName;
  final String? shopTagline;
  final String? shopAddress;
  final File? shopLogo;
  final File? userImage;
  final String? phoneNumber;
  final List<BankState> bankDetails;
  final String? whatsapp;
  final String? facebook;
  final String? twitter;
  final String? instagram;
  final bool isLoading;
  final String? errorMessage;
  final bool isEditing;

  ProfileState({
    this.ownerName,
    this.email,
    this.shopName,
    this.shopTagline,
    this.shopAddress,
    this.shopLogo,
    this.userImage,
    this.phoneNumber,
    this.bankDetails = const [],
    this.whatsapp,
    this.facebook,
    this.twitter,
    this.instagram,
    this.isLoading = false,
    this.errorMessage,
    this.isEditing = false,
  });

  ProfileState copyWith({
    String? ownerName,
    String? email,
    String? shopName,
    String? shopTagline,
    String? shopAddress,
    File? shopLogo,
    File? userImage,
    String? phoneNumber,
    List<BankState>? bankDetails,
    String? whatsapp,
    String? facebook,
    String? twitter,
    String? instagram,
    bool? isLoading,
    String? errorMessage,
    bool? isEditing,
  }) {
    return ProfileState(
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      shopName: shopName ?? this.shopName,
      shopTagline: shopTagline ?? this.shopTagline,
      shopAddress: shopAddress ?? this.shopAddress,
      shopLogo: shopLogo ?? this.shopLogo,
      userImage: userImage ?? this.userImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bankDetails: bankDetails ?? this.bankDetails,
      whatsapp: whatsapp ?? this.whatsapp,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      instagram: instagram ?? this.instagram,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isEditing: isEditing ?? this.isEditing,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final DatabaseService _databaseService;
  final CloudUserService _cloudUserService;
  String? _userId;
  final String? _originalEmail;

  ProfileNotifier(this._databaseService, this._cloudUserService, {User? user})
    : _userId = user?.id,
      _originalEmail = user?.email,
      super(
        ProfileState(
          ownerName: user?.ownerName,
          email: user?.email,
          shopName: user?.shopName,
          shopTagline: user?.shopTagline, // Added shopTagline
          shopAddress: user?.shopAddress,
          shopLogo:
              user?.shopLogoPath != null &&
                      File(user!.shopLogoPath!).existsSync()
                  ? File(user.shopLogoPath!)
                  : null,
          userImage:
              user?.userImagePath != null &&
                      File(user!.userImagePath!).existsSync()
                  ? File(user.userImagePath!)
                  : null,
          phoneNumber: user?.phoneNumber,
          bankDetails:
              user?.bankDetails
                  .map(
                    (bank) => BankState(
                      bankName: bank.bankName,
                      accountNumber: bank.accountNumber,
                      ifscCode: bank.ifscCode,
                      qrCode:
                          bank.qrCodePath != null &&
                                  File(bank.qrCodePath!).existsSync()
                              ? File(bank.qrCodePath!)
                              : null,
                    ),
                  )
                  .toList() ??
              [],
          whatsapp: user?.whatsapp,
          facebook: user?.facebook,
          twitter: user?.twitter,
          instagram: user?.instagram,
        ),
      );

  Future<void> loadUserData() async {
    try {
      await _databaseService.initialize();
      final users = await _databaseService.getUsers();
      if (!mounted) return; // Check if still mounted after async operation
      if (users.isNotEmpty) {
        final user = users.first;
        _userId = user.id;
        state = state.copyWith(
          ownerName: user.ownerName,
          email: user.email,
          shopName: user.shopName,
          shopTagline: user.shopTagline, // Added shopTagline
          shopAddress: user.shopAddress,
          shopLogo:
              user.shopLogoPath != null && File(user.shopLogoPath!).existsSync()
                  ? File(user.shopLogoPath!)
                  : null,
          userImage:
              user.userImagePath != null &&
                      File(user.userImagePath!).existsSync()
                  ? File(user.userImagePath!)
                  : null,
          phoneNumber: user.phoneNumber,
          bankDetails:
              user.bankDetails
                  .map(
                    (bank) => BankState(
                      bankName: bank.bankName,
                      accountNumber: bank.accountNumber,
                      ifscCode: bank.ifscCode,
                      qrCode:
                          bank.qrCodePath != null &&
                                  File(bank.qrCodePath!).existsSync()
                              ? File(bank.qrCodePath!)
                              : null,
                    ),
                  )
                  .toList(),
          whatsapp: user.whatsapp,
          facebook: user.facebook,
          twitter: user.twitter,
          instagram: user.instagram,
          errorMessage: null,
        );
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(errorMessage: 'Failed to load user data: $e');
      }
    }
  }

  void toggleEditMode() {
    state = state.copyWith(isEditing: !state.isEditing);
  }

  void updateOwnerName(String ownerName) {
    state = state.copyWith(ownerName: ownerName, errorMessage: null);
  }

  void updateEmail(String email) {
    // Only allow email update for new users (no original email set)
    if (_originalEmail != null && _originalEmail.isNotEmpty) {
      // Existing user - email cannot be changed
      return;
    }
    // New user - allow setting email
    state = state.copyWith(email: email, errorMessage: null);
  }

  /// Check if this is a new user (no original email)
  bool get isNewUser => _originalEmail == null || _originalEmail.isEmpty;

  void updateShopName(String shopName) {
    state = state.copyWith(shopName: shopName, errorMessage: null);
  }

  void updateShopTagline(String shopTagline) {
    // Added updateShopTagline
    state = state.copyWith(shopTagline: shopTagline, errorMessage: null);
  }

  void updateShopAddress(String shopAddress) {
    state = state.copyWith(shopAddress: shopAddress, errorMessage: null);
  }

  Future<void> pickShopLogo() async {
    final pickedFile = await ImagePickerHelper.pickImageFromGallery();
    if (!mounted) return;
    if (pickedFile != null) {
      state = state.copyWith(
        shopLogo: pickedFile,
        errorMessage: null,
      );
    }
  }

  Future<void> pickUserImage() async {
    final pickedFile = await ImagePickerHelper.pickImageFromGallery();
    if (!mounted) return;
    if (pickedFile != null) {
      state = state.copyWith(
        userImage: pickedFile,
        errorMessage: null,
      );
    }
  }

  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber, errorMessage: null);
  }

  void addBankDetail() {
    final newBankDetails = List<BankState>.from(state.bankDetails)
      ..add(BankState());
    state = state.copyWith(bankDetails: newBankDetails, errorMessage: null);
  }

  void removeBankDetail(int index) {
    final newBankDetails = List<BankState>.from(state.bankDetails)
      ..removeAt(index);
    state = state.copyWith(bankDetails: newBankDetails, errorMessage: null);
  }

  void updateBankName(int index, String bankName) {
    final newBankDetails = List<BankState>.from(state.bankDetails);
    newBankDetails[index] = newBankDetails[index].copyWith(bankName: bankName);
    state = state.copyWith(bankDetails: newBankDetails, errorMessage: null);
  }

  void updateAccountNumber(int index, String accountNumber) {
    final newBankDetails = List<BankState>.from(state.bankDetails);
    newBankDetails[index] = newBankDetails[index].copyWith(
      accountNumber: accountNumber,
    );
    state = state.copyWith(bankDetails: newBankDetails, errorMessage: null);
  }

  void updateIfscCode(int index, String ifscCode) {
    final newBankDetails = List<BankState>.from(state.bankDetails);
    newBankDetails[index] = newBankDetails[index].copyWith(ifscCode: ifscCode);
    state = state.copyWith(bankDetails: newBankDetails, errorMessage: null);
  }

  Future<void> pickQrCode(int index) async {
    final pickedFile = await ImagePickerHelper.pickImageFromGallery();
    if (!mounted) return;
    if (pickedFile != null) {
      final newBankDetails = List<BankState>.from(state.bankDetails);
      newBankDetails[index] = newBankDetails[index].copyWith(
        qrCode: pickedFile,
      );
      state = state.copyWith(bankDetails: newBankDetails, errorMessage: null);
    }
  }

  void updateWhatsapp(String whatsapp) {
    state = state.copyWith(whatsapp: whatsapp, errorMessage: null);
  }

  void updateFacebook(String facebook) {
    state = state.copyWith(facebook: facebook, errorMessage: null);
  }

  void updateTwitter(String twitter) {
    state = state.copyWith(twitter: twitter, errorMessage: null);
  }

  void updateInstagram(String instagram) {
    state = state.copyWith(instagram: instagram, errorMessage: null);
  }

  Future<bool> submitProfile() async {
    // Validate fields without non-null assertions
    if (state.ownerName == null || state.ownerName!.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter owner name');
      return false;
    }
    if (state.shopName == null || state.shopName!.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a shop name');
      return false;
    }
    if (state.shopAddress == null || state.shopAddress!.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a shop address');
      return false;
    }
    if (state.phoneNumber == null || state.phoneNumber!.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a phone number');
      return false;
    }
    if (_originalEmail == null && state.email == null) {
      state = state.copyWith(errorMessage: 'Email is required');
      return false;
    }

    // Validate bank details (optional, but if provided, check completeness)
    for (var bank in state.bankDetails) {
      if ((bank.bankName?.isEmpty ?? true) ||
          (bank.accountNumber?.isEmpty ?? true) ||
          (bank.ifscCode?.isEmpty ?? true)) {
        state = state.copyWith(
          errorMessage: 'Please complete all bank detail fields',
        );
        return false;
      }
    }

    state = state.copyWith(isLoading: true);

    try {
      var user = User(
        id: _userId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        ownerName: state.ownerName!,
        email: _originalEmail ?? state.email!,
        shopName: state.shopName!,
        shopTagline: state.shopTagline, // Added shopTagline
        shopAddress: state.shopAddress!,
        shopLogoPath: state.shopLogo?.path,
        userImagePath: state.userImage?.path,
        phoneNumber: state.phoneNumber!,
        bankDetails:
            state.bankDetails
                .map(
                  (bank) => BankDetail(
                    bankName: bank.bankName!,
                    accountNumber: bank.accountNumber!,
                    ifscCode: bank.ifscCode!,
                    qrCodePath: bank.qrCode?.path,
                  ),
                )
                .toList(),
        whatsapp: state.whatsapp,
        facebook: state.facebook,
        twitter: state.twitter,
        instagram: state.instagram,
      );

      // If this email already exists in cloud, pull it and merge (handles "other data" on same email).
      try {
        final remote = await _cloudUserService.getUserByEmail(user.email);
        if (remote != null) {
          user = _cloudUserService.mergePreferLocal(local: user, remote: remote);
        }
      } catch (_) {
        // Ignore cloud errors; local profile still works offline.
      }

      if (_userId != null) {
        await _databaseService.updateUser(user);
      } else {
        await _databaseService.saveUser(user);
      }

      // Upsert to cloud (no Supabase Auth, key is email).
      try {
        await _cloudUserService.upsertUser(user);
      } catch (_) {
        // Ignore cloud errors; queue-based data sync will handle later.
      }

      if (!mounted) return true;
      state = state.copyWith(isEditing: false, errorMessage: null);
      return true;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to update profile: $e',
        );
      }
      return false;
    } finally {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
  }
}

final profileProvider =
    StateNotifierProvider.autoDispose<ProfileNotifier, ProfileState>(
      (ref) =>
          ProfileNotifier(ref.read(databaseServiceProvider), CloudUserService()),
    );
