import 'package:flutter/material.dart';

/// NUEVO: MockAuthProvider completamente independiente de Firebase
/// Permite desarrollo sin Firebase hasta que usuario decida loguearse
class MockAuthProvider extends ChangeNotifier {
  bool _isLoggedIn = false; // NUEVO: Estado mock de autenticación
  bool _isLoading = false; // NUEVO: Estado de carga mock

  // NUEVO: Datos mock del usuario (solo cuando está logueado)
  String _mockUserName = 'Mario Passalia';
  String _mockUserEmail = 'mario@gmail.com';
  String _mockUserInitials = 'MP';
  String _mockUserPhotoUrl = '';

  // NUEVO: Getters públicos - completamente mock
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;

  // NUEVO: Datos del usuario solo si está logueado
  String get userName => _isLoggedIn ? _mockUserName : 'Usuario';
  String get userEmail => _isLoggedIn ? _mockUserEmail : '';
  String get userInitials =>
      _isLoggedIn ? _mockUserInitials : '?'; // NUEVO: "?" cuando no logueado
  String get userPhotoUrl => _isLoggedIn ? _mockUserPhotoUrl : '';

  MockAuthProvider() {
    // NUEVO: Inicializar en estado no logueado
    _isLoggedIn = false;
  }

  /// NUEVO: Simular login con Google (mock)
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true; // NUEVO: Mostrar loading
      notifyListeners();

      // NUEVO: Simular delay de autenticación
      await Future.delayed(const Duration(seconds: 1));

      // NUEVO: Simular login exitoso
      _isLoggedIn = true;
      print('✅ Mock Login exitoso: $_mockUserName');
      return true;
    } catch (e) {
      print('❌ Error en mock login: $e');
      return false;
    } finally {
      _isLoading = false; // NUEVO: Ocultar loading
      notifyListeners();
    }
  }

  /// NUEVO: Simular logout (mock)
  Future<void> signOut() async {
    try {
      _isLoading = true; // NUEVO: Mostrar loading
      notifyListeners();

      // NUEVO: Simular delay de logout
      await Future.delayed(const Duration(milliseconds: 500));

      _isLoggedIn = false; // NUEVO: Cambiar a no logueado
      print('✅ Mock Logout exitoso');
    } catch (e) {
      print('❌ Error en mock logout: $e');
    } finally {
      _isLoading = false; // NUEVO: Ocultar loading
      notifyListeners();
    }
  }

  /// NUEVO: Obtener color del avatar basado en estado
  Color getAvatarColor() {
    if (_isLoggedIn) {
      // NUEVO: Color basado en email cuando está logueado
      final hash = _mockUserEmail.hashCode;
      final colors = [
        Colors.blue,
        Colors.green,
        Colors.orange,
        Colors.purple,
        Colors.red,
        Colors.teal,
        Colors.indigo,
        Colors.pink,
      ];
      return colors[hash.abs() % colors.length];
    } else {
      // NUEVO: Color gris para estado no logueado
      return Colors.grey.withAlpha(179);
    }
  }

  /// NUEVO: Método para desarrollo - alternar login/logout rápidamente
  void toggleMockAuth() {
    _isLoggedIn = !_isLoggedIn;
    notifyListeners();
    print(
      _isLoggedIn ? '✅ Mock: Usuario logueado' : '❌ Mock: Usuario no logueado',
    );
  }

  /// NUEVO: Cambiar datos del usuario mock (para testing)
  void setMockUserData({String? name, String? email, String? photoUrl}) {
    if (name != null) {
      _mockUserName = name;
      // NUEVO: Recalcular iniciales automáticamente
      _mockUserInitials = _generateInitials(name);
    }
    if (email != null) _mockUserEmail = email;
    if (photoUrl != null) _mockUserPhotoUrl = photoUrl;

    notifyListeners();
  }

  /// NUEVO: Generar iniciales automáticamente
  String _generateInitials(String name) {
    final names = name.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return '?'; // NUEVO: Fallback a "?"
  }

  @override
  void dispose() {
    // NUEVO: Limpiar recursos mock
    super.dispose();
  }
}
