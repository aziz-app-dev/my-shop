import 'dart:io';

class SignUpFormState {
  final String? ownerName;
  final String? email;
  final String? shopName;
  final String? shopAddress;
  final File? shopLogo;
  final File? userImage;
  final String? phoneNumber;
  final bool isLoading;
  final String? errorMessage;

  SignUpFormState({
    this.ownerName,
    this.email,
    this.shopName,
    this.shopAddress,
    this.shopLogo,
    this.userImage,
    this.phoneNumber,
    this.isLoading = false,
    this.errorMessage,
  });

  SignUpFormState copyWith({
    String? ownerName,
    String? email,
    String? shopName,
    String? shopAddress,
    File? shopLogo,
    File? userImage,
    String? phoneNumber,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SignUpFormState(
      ownerName: ownerName ?? this.ownerName,
      email: email ?? this.email,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopLogo: shopLogo ?? this.shopLogo,
      userImage: userImage ?? this.userImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
