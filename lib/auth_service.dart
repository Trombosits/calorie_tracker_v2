import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthService {
  static Future<AuthResponse?> login(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse?> register(String email, String password) async {
    return await supabase.auth.signUp(email: email.trim(), password: password);
  }
}
