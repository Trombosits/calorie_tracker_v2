import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

class AuthService {
  static Future<AuthResponse> login(String email, String password) async {
    return await supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> register(String email, String password) async {
    return await supabase.auth.signUp(email: email.trim(), password: password);
  }

  // Dipakai untuk Android/native, bukan untuk Flutter Web
  static Future<AuthResponse> signInWithGoogle() async {
    const webClientId =
        '525250997907-7lb4fpp0e4u74ev1b2kubsa3i4ptig8p.apps.googleusercontent.com';

    const scopes = <String>['email', 'profile'];

    final GoogleSignIn googleSignIn = GoogleSignIn.instance;

    await googleSignIn.initialize(serverClientId: webClientId);

    final googleUser = await googleSignIn.authenticate(scopeHint: scopes);

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    final googleAuthorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
        await googleUser.authorizationClient.authorizeScopes(scopes);

    final accessToken = googleAuthorization.accessToken;

    if (idToken == null) {
      throw const AuthException('Google ID Token tidak ditemukan');
    }

    return await supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }
}
