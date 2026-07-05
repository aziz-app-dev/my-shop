import '../../models/user/user_model.dart';
import '../../utils/image_picker_helper.dart';
import '../services/database/database_services.dart';
import '../states/signup_states.dart';
import 'package:riverpod/legacy.dart';

class SignUpFormNotifier extends StateNotifier<SignUpFormState> {
  final DatabaseService _databaseService;

  SignUpFormNotifier(this._databaseService) : super(SignUpFormState());

  void updateOwnerName(String ownerName) {
    // Added
    state = state.copyWith(ownerName: ownerName, errorMessage: null);
  }

  void updateEmail(String email) {
    // Added
    state = state.copyWith(email: email, errorMessage: null);
  }

  void updateShopName(String shopName) {
    state = state.copyWith(shopName: shopName, errorMessage: null);
  }

  void updateShopAddress(String shopAddress) {
    state = state.copyWith(shopAddress: shopAddress, errorMessage: null);
  }

  Future<void> pickShopLogo() async {
    final pickedFile = await ImagePickerHelper.pickImageFromGallery();
    if (pickedFile != null) {
      state = state.copyWith(shopLogo: pickedFile);
    }
  }

  Future<void> pickUserImage() async {
    final pickedFile = await ImagePickerHelper.pickImageFromGallery();
    if (pickedFile != null) {
      state = state.copyWith(userImage: pickedFile);
    }
  }

  void updatePhoneNumber(String phoneNumber) {
    state = state.copyWith(phoneNumber: phoneNumber, errorMessage: null);
  }

  Future<bool> submitForm() async {
    if (state.ownerName == null || state.ownerName!.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter owner name');
      return false;
    }
    if (state.email == null || state.email!.isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter an email');
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

    state = state.copyWith(isLoading: true);

    try {
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerName: state.ownerName!,
        email: state.email!,
        shopName: state.shopName!,
        shopAddress: state.shopAddress!,
        shopLogoPath: state.shopLogo?.path,
        userImagePath: state.userImage?.path,
        phoneNumber: state.phoneNumber!,
      );

      await _databaseService.saveUser(user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to sign up: $e',
      );
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final signUpFormProvider =
    StateNotifierProvider<SignUpFormNotifier, SignUpFormState>(
      (ref) => SignUpFormNotifier(ref.read(databaseServiceProvider)),
    );
