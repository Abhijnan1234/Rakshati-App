String? validateRequired(String? value, String fieldLabel) {
  if (value == null || value.trim().isEmpty) {
    return '$fieldLabel is required.';
  }
  return null;
}

String? validateEmail(String? value) {
  final requiredError = validateRequired(value, 'Email');
  if (requiredError != null) {
    return requiredError;
  }

  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(value!.trim())) {
    return 'Enter a valid email address.';
  }

  return null;
}

String? validatePassword(String? value) {
  final requiredError = validateRequired(value, 'Password');
  if (requiredError != null) {
    return requiredError;
  }

  if (value!.trim().length < 6) {
    return 'Password must be at least 6 characters.';
  }
  return null;
}

String? validateUsername(String? value) {
  final requiredError = validateRequired(value, 'Username');
  if (requiredError != null) {
    return requiredError;
  }

  final username = value!.trim();
  if (username.length < 3 || username.length > 24) {
    return 'Username must be 3 to 24 characters.';
  }

  final usernamePattern = RegExp(r'^[a-zA-Z0-9_]+$');
  if (!usernamePattern.hasMatch(username)) {
    return 'Only letters, numbers, and underscores are allowed.';
  }

  return null;
}
