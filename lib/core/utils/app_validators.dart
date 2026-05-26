import 'labels.dart';

class AppValidators {
  // Email Validator
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Labels.emailIsRequired;
    }
    const emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    final regex = RegExp(emailPattern);
    if (!regex.hasMatch(value.trim())) {
      return Labels.enterAValidEmailAddress;
    }
    return null;
  }

  // Password Validator
  static String? validatePassword(String? value, {int minLength = 3}) {
    if (value == null || value.isEmpty) {
      return Labels.passwordIsRequired;
    }
    if (value.length < minLength) {
      return "${Labels.passwordMustBeAtLeast} $minLength ${Labels.charactersLong}";
    }
    return null;
  }

  // Confirm Password
  static String? validateConfirmPassword(String? value, String? original) {
    if (value == null || value.isEmpty) {
      return Labels.confirmPasswordIsRequired;
    }
    if (value != original) {
      return Labels.passwordsDoNotMatch;
    }
    return null;
  }

  // Number only
  static String? validateNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Labels.thisFieldIsRequired;
    }
    final regex = RegExp(r'^[0-9]+$');
    if (!regex.hasMatch(value.trim())) {
      return Labels.enterNumbersOnly;
    }
    return null;
  }

  // Phone Number (Basic)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return Labels.phoneNumberIsRequired;
    }
    final regex = RegExp(r'^\+?[0-9]{7,15}$');
    if (!regex.hasMatch(value)) {
      return Labels.enterANumber;
    }
    return null;
  }

  // Name Validator
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return Labels.nameIsRequired;
    }
    final regex = RegExp(r'^[a-zA-Z ]+$');
    if (!regex.hasMatch(value.trim())) {
      return Labels.enterAlphabetsOnly;
    }
    return null;
  }

  // Generic Required Field
  static String? validateRequired(String? value, {String fieldName = "Field"}) {
    if (value == null || value.trim().isEmpty) {
      return "$fieldName ${Labels.thisFieldIsRequired}";
    }
    return null;
  }

  static String? noValidation(String? value) {
    return null;
  }
}
