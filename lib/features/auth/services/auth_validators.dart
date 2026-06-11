/// Password strength calculator + form-field validators.
library;

enum PasswordStrength { empty, weak, fair, good, strong, excellent }

class PasswordScore {
  final PasswordStrength strength;
  final double fraction; // 0.0–1.0
  final String label;
  final int score; // 0–4
  final List<String> feedback;

  const PasswordScore({
    required this.strength,
    required this.fraction,
    required this.label,
    required this.score,
    required this.feedback,
  });
}

PasswordScore evaluatePassword(String pwd) {
  if (pwd.isEmpty) {
    return const PasswordScore(
      strength: PasswordStrength.empty,
      fraction: 0,
      label: '',
      score: 0,
      feedback: [],
    );
  }
  int score = 0;
  final feedback = <String>[];

  if (pwd.length >= 8) {
    score++;
  } else {
    feedback.add('Use at least 8 characters');
  }
  if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) {
    score++;
  } else {
    feedback.add('Mix upper and lower case');
  }
  if (RegExp(r'[0-9]').hasMatch(pwd)) {
    score++;
  } else {
    feedback.add('Add a number');
  }
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) {
    score++;
  } else {
    feedback.add('Add a symbol (e.g. !@#)');
  }
  if (pwd.length >= 12) score = (score + 1).clamp(0, 4);

  final strength = switch (score) {
    0 => PasswordStrength.weak,
    1 => PasswordStrength.fair,
    2 => PasswordStrength.good,
    3 => PasswordStrength.strong,
    _ => PasswordStrength.excellent,
  };
  final label = switch (strength) {
    PasswordStrength.weak => 'Weak',
    PasswordStrength.fair => 'Fair',
    PasswordStrength.good => 'Good',
    PasswordStrength.strong => 'Strong',
    PasswordStrength.excellent => 'Excellent',
    _ => '',
  };
  return PasswordScore(
    strength: strength,
    fraction: (score / 4).clamp(0.0, 1.0),
    label: label,
    score: score,
    feedback: feedback,
  );
}

String? validateEmail(String? v) {
  if (v == null || v.trim().isEmpty) return 'Email is required';
  final email = v.trim();
  final re = RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');
  if (!re.hasMatch(email)) return 'Enter a valid email';
  return null;
}

String? validatePassword(String? v) {
  if (v == null || v.isEmpty) return 'Password is required';
  if (v.length < 8) return 'Use at least 8 characters';
  return null;
}

String? validatePhone(String? v) {
  if (v == null || v.trim().isEmpty) return 'Phone is required';
  final digits = v.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 7) return 'Enter a valid phone';
  return null;
}

String? validateRequired(String? v, [String label = 'This field']) {
  if (v == null || v.trim().isEmpty) return '$label is required';
  return null;
}

/// Beautify a phone number as the user types.
String formatPhone(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final sb = StringBuffer();
  for (var i = 0; i < digits.length && i < 15; i++) {
    if (i == 0) sb.write('+');
    sb.write(digits[i]);
    if (i == 2) sb.write(' ');
    if (i == 5) sb.write(' ');
    if (i == 8) sb.write(' ');
  }
  return sb.toString();
}
