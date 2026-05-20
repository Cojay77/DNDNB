import 'package:dndnb/services/auth_service.dart';

/// Register push notification token for the given user.
/// Works on both Web and mobile platforms.
/// 
/// This is a convenience wrapper around AuthService.registerToken.
Future<void> registerWebToken(String userId) async {
  await AuthService().registerToken(userId);
}

/// Same as registerWebToken — unified for all platforms.
Future<void> registerWebTokenOnApp(String userId) async {
  await AuthService().registerToken(userId);
}
