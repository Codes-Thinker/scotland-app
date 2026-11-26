/// Form validation helpers aligned with scotland-backend auth DTOs.
class Validators {
  Validators._();

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Enter your full name.';
    if (v.length > 120) return 'Name is too long.';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim().toLowerCase() ?? '';
    if (v.isEmpty) return 'Enter your email address.';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v);
    if (!ok) return 'Enter a valid email address.';
    return null;
  }

  static String? phone(String? value) {
    final v = value?.trim() ?? '';
    if (!RegExp(r'^\+?[0-9 ]{8,20}$').hasMatch(v)) {
      return 'Enter a valid phone (digits, optional +).';
    }
    return null;
  }

  static String? password(String? value, {int min = 8}) {
    final v = value ?? '';
    if (v.length < min) return 'Password must be at least $min characters.';
    if (v.length > 128) return 'Password is too long.';
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value != password) return 'Passwords do not match.';
    return null;
  }

  static String? vehicleMakeModel(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Enter vehicle make and model.';
    return null;
  }

  static String? vehiclePlate(String? value) {
    final v = value?.trim().toUpperCase() ?? '';
    if (!RegExp(r'^[A-Z0-9 ]{2,16}$').hasMatch(v)) {
      return 'Enter a valid registration plate.';
    }
    return null;
  }

  static String? operatingZone(String? value) {
    final v = value?.trim() ?? '';
    if (v.length < 2) return 'Select your operating zone.';
    return null;
  }
}
