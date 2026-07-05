class Validators {
  //! ---------------------- Email Validator ---------------------
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return "Email can't be empty";
    }
    String emailPattern = r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$';
    if (!RegExp(emailPattern).hasMatch(value)) {
      return "Enter a valid email";
    }
    return null;
  }

  //! ---------------------- Password Validator ---------------------
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password can't be empty";
    }
    if (value.length < 6) {
      return "Password must be at least 6 characters";
    }
    // if (!RegExp(r'^(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
    //   return "Password must contain an uppercase letter & a number";
    // }
    return null;
  }
}

// CustomTextField(
//         controller: emailController,
//         label: "Email",
//         validator: Validators.validateEmail,
//         apiError: apiEmailError,
//         keyboardType: TextInputType.emailAddress,
//       ),
