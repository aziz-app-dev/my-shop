class BankDetail {
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String? qrCodePath;

  BankDetail({
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    this.qrCodePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'qrCodePath': qrCodePath,
    };
  }

  factory BankDetail.fromMap(Map<String, dynamic> map) {
    return BankDetail(
      bankName: map['bankName'] as String,
      accountNumber: map['accountNumber'] as String,
      ifscCode: map['ifscCode'] as String,
      qrCodePath: map['qrCodePath'] as String?,
    );
  }
}

class User {
  final String id;
  final String ownerName;
  final String email;
  final String shopName;
  final String? shopTagline;
  final String shopAddress;
  final String? shopLogoPath;
  final String? userImagePath;
  final String phoneNumber;
  final List<BankDetail> bankDetails;
  final String? whatsapp;
  final String? facebook;
  final String? twitter;
  final String? instagram;

  User({
    required this.id,
    required this.ownerName,
    required this.email,
    required this.shopName,
    this.shopTagline,
    required this.shopAddress,
    this.shopLogoPath,
    this.userImagePath,
    required this.phoneNumber,
    this.bankDetails = const [],
    this.whatsapp,
    this.facebook,
    this.twitter,
    this.instagram,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ownerName': ownerName,
      'email': email,
      'shopName': shopName,
      'shopTagline': shopTagline,
      'shopAddress': shopAddress,
      'shopLogoPath': shopLogoPath,
      'userImagePath': userImagePath,
      'phoneNumber': phoneNumber,
      'bankDetails': bankDetails.map((bank) => bank.toMap()).toList(),
      'whatsapp': whatsapp,
      'facebook': facebook,
      'twitter': twitter,
      'instagram': instagram,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      ownerName: map['ownerName'] as String,
      email: map['email'] as String,
      shopName: map['shopName'] as String,
      shopTagline: map['shopTagline'] as String?,
      shopAddress: map['shopAddress'] as String,
      shopLogoPath: map['shopLogoPath'] as String?,
      userImagePath: map['userImagePath'] as String?,
      phoneNumber: map['phoneNumber'] as String,
      bankDetails:
          (map['bankDetails'] as List<dynamic>? ?? [])
              .map(
                (item) =>
                    BankDetail.fromMap(Map<String, dynamic>.from(item as Map)),
              )
              .toList(),
      whatsapp: map['whatsapp'] as String?,
      facebook: map['facebook'] as String?,
      twitter: map['twitter'] as String?,
      instagram: map['instagram'] as String?,
    );
  }
}
