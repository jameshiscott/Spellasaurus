import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/profile.dart';

class AuthRepository {
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  User? get currentUser => supabase.auth.currentUser;

  bool get isSignedIn => currentUser != null;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    DateTime? dateOfBirth,
  }) async {
    final response = await supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role.value,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().substring(0, 10),
      },
    );
    return response;
  }

  Future<void> signOut() => supabase.auth.signOut();

  Future<void> resetPassword(String email) =>
      supabase.auth.resetPasswordForEmail(email);

  Future<Profile?> fetchProfile(String userId) async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();
    if (data == null) return null;
    return Profile.fromJson(data);
  }
}
