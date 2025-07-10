import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:quehacemos_cba/src/services/auth_service.dart';
import 'package:quehacemos_cba/src/services/mock_auth_service.dart';

class AuthProvider extends ChangeNotifier {
  //final AuthService _authService = AuthService();
  final MockAuthService _authService = MockAuthService();
  User? _user;
  bool _isLoading = false;

  // NUEVO: Getters públicos
  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => true;

  // NUEVO: Datos del usuario para la UI
  String get userName => 'Mario Passalia';           // HACK: Nombre hardcodeado
  String get userEmail => 'mario@gmail.com';      // HACK: Email hardcodeado  
  String get userInitials => 'MP';               // HACK: Iniciales hardcodeadas
  String get userPhotoUrl => _user?.photoURL ?? '';

  AuthProvider() {
    // NUEVO: Escuchar cambios en auth state
   // _initializeAuthListener();
  }

  /// NUEVO: Inicializar listener de auth state
  void _initializeAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });

    // NUEVO: Inicializar con usuario actual si existe
    _user = FirebaseAuth.instance.currentUser;
  }

  /// NUEVO: Obtener iniciales del usuario
  String _getUserInitials() {
    if (_user?.displayName != null) {
      final names = _user!.displayName!.split(' ');
      if (names.length >= 2) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      } else {
        return names[0][0].toUpperCase();
      }
    }
    
    if (_user?.email != null) {
      return _user!.email![0].toUpperCase();
    }
    
    return 'U'; // NUEVO: Default fallback
  }

  /// NUEVO: Iniciar sesión con Google
  Future<bool> signInWithGoogle() async {
    try {
      _isLoading = true;
      notifyListeners();

      final result = await _authService.signInWithGoogle();
      
      if (result != null) {
        _user = result.user;
        print('✅ Login exitoso: ${_user?.displayName}');
        return true;
      } else {
        print('❌ Login cancelado por usuario');
        return false;
      }
    } catch (e) {
      print('❌ Error en login: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NUEVO: Cerrar sesión
  Future<void> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await FirebaseAuth.instance.signOut();
      // CAMBIO: Acceder a GoogleSignIn desde AuthService no es posible
      // await _authService._googleSignIn.signOut(); // REMOVIDO
      
      _user = null;
      print('✅ Logout exitoso');
    } catch (e) {
      print('❌ Error en logout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// NUEVO: Datos mockeados para desarrollo (temporal)
  void _setMockUser() {
    // NUEVO: Solo para desarrollo, remover en producción
    _user = null; // NUEVO: Simular usuario no logueado
    notifyListeners();
  }

  /// NUEVO: Método para desarrollo - alternar entre logueado/no logueado
  void toggleMockAuth() {
    if (_user == null) {
      // NUEVO: Simular usuario logueado
      _user = FirebaseAuth.instance.currentUser ?? _createMockUser();
    } else {
      // NUEVO: Simular usuario no logueado
      _user = null;
    }
    notifyListeners();
  }

  /// NUEVO: Crear usuario mock para desarrollo
  User? _createMockUser() {
    // NUEVO: Esto es solo para desarrollo
    // En producción, siempre usar el usuario real de Firebase
    return null; // NUEVO: Por ahora no crear mock, usar auth real
  }

  /// NUEVO: Obtener color del avatar basado en iniciales
  Color getAvatarColor() {
    if (_user?.email != null) {
      final hash = _user!.email!.hashCode;
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
    }
    return Colors.grey;
  }

  @override
  void dispose() {
    // NUEVO: Limpiar recursos si es necesario
    super.dispose();
  }
}