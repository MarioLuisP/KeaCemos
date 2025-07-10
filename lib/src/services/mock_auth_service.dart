import 'package:firebase_auth/firebase_auth.dart';

class MockAuthService {
  // NUEVO: Simular UserCredential sin Firebase
  Future<UserCredential?> signInWithGoogle() async {
    print("🧪 Mock: Simulando login con Google");
    await Future.delayed(Duration(milliseconds: 500)); // Simular delay
    return MockUserCredential(); // Devolver mock
  }
}

// NUEVO: Mock UserCredential
class MockUserCredential extends UserCredential {
  @override
  User? get user => MockUser();
  
  @override
  AdditionalUserInfo? get additionalUserInfo => null;
  
  @override
  AuthCredential? get credential => null;
}

// NUEVO: Mock User
class MockUser extends User {
  @override
  String? get displayName => 'Juan Pérez';
  
  @override
  String? get email => 'juan@gmail.com';
  
  @override
  String? get photoURL => '';
  
  @override
  String get uid => 'mock_uid_123';
  
  // NUEVO: Métodos requeridos por User (stubs)
  @override
  bool get emailVerified => true;
  
  @override
  bool get isAnonymous => false;
  
  @override
  UserMetadata get metadata => MockUserMetadata();
  
  @override
  String? get phoneNumber => null;
  
  @override
  List<UserInfo> get providerData => [];
  
  @override
  String? get refreshToken => null;
  
  @override
  String? get tenantId => null;
  
  // Otros métodos requeridos...
  @override
  Future<void> delete() async {}
  
  @override
  Future<String> getIdToken([bool forceRefresh = false]) async => 'mock_token';
  
  @override
  Future<IdTokenResult> getIdTokenResult([bool forceRefresh = false]) async => throw UnimplementedError();
  
  @override
  Future<User> linkWithCredential(AuthCredential credential) async => this;
  
  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential credential) async => MockUserCredential();
  
  @override
  Future<void> reload() async {}
  
  @override
  Future<void> sendEmailVerification([ActionCodeSettings? actionCodeSettings]) async {}
  
  @override
  Future<User> unlink(String providerId) async => this;
  
  @override
  Future<void> updateDisplayName(String? displayName) async {}
  
  @override
  Future<void> updateEmail(String newEmail) async {}
  
  @override
  Future<void> updatePassword(String newPassword) async {}
  
  @override
  Future<void> updatePhoneNumber(PhoneAuthCredential phoneCredential) async {}
  
  @override
  Future<void> updatePhotoURL(String? photoURL) async {}
  
  @override
  Future<void> updateProfile({String? displayName, String? photoURL}) async {}
  
  @override
  Future<void> verifyBeforeUpdateEmail(String newEmail, [ActionCodeSettings? actionCodeSettings]) async {}
  
  @override
  MultiFactor get multiFactor => throw UnimplementedError();
}

class MockUserMetadata extends UserMetadata {
  @override
  DateTime? get creationTime => DateTime.now();
  
  @override
  DateTime? get lastSignInTime => DateTime.now();
}