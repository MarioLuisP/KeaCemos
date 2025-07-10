/// NUEVO: Configuración central de providers
/// Permite intercambiar fácilmente entre Mock y Firebase Auth
library provider_config;

// CAMBIO: EXPORTS deben ir ANTES de cualquier declaración
export 'package:quehacemos_cba/src/providers/mock_auth_provider.dart' show MockAuthProvider;
// export 'package:quehacemos_cba/src/providers/auth_provider.dart' show AuthProvider;  // NUEVO: 💥Comentado por ahora

// NUEVO: Importar ambos providers DESPUÉS de exports
import 'package:quehacemos_cba/src/providers/mock_auth_provider.dart';
import 'package:quehacemos_cba/src/providers/auth_provider.dart';

/// NUEVO: Configuración de desarrollo vs producción
class ProviderConfig {
  // CAMBIO: Flag para alternar entre Mock y Firebase  💥💥💥💥💥💥💥💥💥
  static const bool USE_MOCK_AUTH = true;  // CAMBIO: true = Mock, false = Firebase
  
  // NUEVO: Factory para obtener el provider correcto
  static dynamic getAuthProvider() {
    if (USE_MOCK_AUTH) {
      return MockAuthProvider();  // NUEVO: Provider mock para desarrollo
    } else {
      return AuthProvider();      // NUEVO: Provider Firebase para producción
    }
  }
  
  // NUEVO: Tipo para Consumer widgets
  static Type get authProviderType {
    if (USE_MOCK_AUTH) {
      return MockAuthProvider;
    } else {
      return AuthProvider;
    }
  }
}

//Paso 2: main.dart - línea 10💥💥💥💥💥
//import 'package:quehacemos_cba/src/providers/mock_auth_provider.dart';  // CAMBIO: auth