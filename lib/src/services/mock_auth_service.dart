class MockAuthService {
  Future<dynamic> signInWithGoogle() async {
    print("🧪 Mock: Simulando login con Google");
    await Future.delayed(Duration(milliseconds: 500));
    return null; // SIMPLE: Solo devolver null
  }
}