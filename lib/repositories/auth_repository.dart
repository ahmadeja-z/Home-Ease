import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../core/services/localStorage/my-local-controller.dart';
import '../core/services/notification_service.dart';
import '../core/utils/constants.dart';
import '../models/user_model.dart';
import 'user_repository.dart';

class AuthRepository {
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  final supabase = Supabase.instance.client;

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final response = await supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) return null;

    return getProfile(user.id);
  }

  Future<UserModel?> getProfile(String userId) async {
    final profileData = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (profileData == null) return null;

    return UserModel.fromJson({
      "id": userId,
      "email": profileData['email'] ?? supabase.auth.currentUser?.email,
      "name": profileData['name'],
      "phoneNumber": profileData['phone_number'],
      "role": profileData['role'],
      "profileImage": profileData['profile_picture'],
      "isActive": profileData['is_active'],
      "status": profileData['status'],
      "verification": profileData['verification'],
      "address": profileData['latitude'] != null
          ? {
              "latitude": profileData['latitude'],
              "longitude": profileData['longitude'],
              "address": profileData['address'],
            }
          : null,
      "createdAt": profileData['created_at'],
      "updatedAt": profileData['updated_at'],
      "deviceFcmToken": profileData['deviceFcmToken'],
      "workerDoc": profileData['cnic_front'] != null
          ? {
              "cnicFront": profileData['cnic_front'],
              "cnicBack": profileData['cnic_back'],
            }
          : null,
    });
  }

  Future<UserModel?> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {"role": "customer"},
    );

    final user = response.user;
    if (user == null) return null;

    await supabase.from('profiles').insert({
      "id": user.id,
      "email": email,
      "name": name,
      "phone_number": phoneNumber,
      "role": "customer",
      "is_active": true,
      "status": "approved",
      "verification": "verified",
    });

    return UserModel.fromJson({
      "id": user.id,
      "email": email,
      "name": name,
      "phoneNumber": phoneNumber,
      "isActive": true,
      "role": "customer",
      "status": "approved",
      "verification": "verified",
    });
  }

  Future<void> logout() async {
    try {
      // 1. Delete FCM token from Firebase and SharedPreferences
      await NotificationService().deleteDeviceToken();

      // 2. Sign out from Supabase
      await supabase.auth.signOut();

      // 3. Clear local user state
      await UserRepository().clearUser();

      // 4. Clear auth-related local storage
      await LocalStorage.removeData(key: AppKeys.authToken);
      await LocalStorage.removeData(key: AppKeys.uRole);

      print('✅ [AuthRepository] Logout complete and storage cleaned.');
    } catch (e) {
      print('❌ [AuthRepository] Error during logout: $e');
    }
  }

  Future<void> resetPassword({required String email}) async {
    await supabase.auth.resetPasswordForEmail(email);
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }

  Future<String> uploadPicture(
    Uint8List bytes,
    String fileName,
    String userId,
  ) async {
    final filePath =
        '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';

    await supabase.storage
        .from('varification-images')
        .uploadBinary(
          filePath,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/png'),
        );

    return supabase.storage.from('varification-images').getPublicUrl(filePath);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = supabase.auth.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }

    // Verify current password by attempting to sign in
    try {
      final email = user.email;
      if (email == null) {
        throw Exception('User email not found');
      }

      // Verify current password
      await supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );
    } catch (e) {
      throw Exception('Current password is incorrect');
    }

    // Update password
    await supabase.auth.updateUser(UserAttributes(password: newPassword));
  }
}
