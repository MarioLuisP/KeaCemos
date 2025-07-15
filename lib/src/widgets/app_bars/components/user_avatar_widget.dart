import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/mock_auth_provider.dart'; // CAMBIO: Usar MockAuthProvider

class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MockAuthProvider>(
      // CAMBIO: Consumer de MockAuthProvider
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          // NUEVO: Loading más pequeño y discreto
          return Container(
            width: 36, // CAMBIO: Tamaño consistente con avatar
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(26), // NUEVO: Fondo sutil
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 20, // CAMBIO: Loading más pequeño
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          );
        }

        if (authProvider.isLoggedIn) {
          // NUEVO: Usuario logueado - mostrar avatar con dropdown
          return _LoggedInAvatar(authProvider: authProvider);
        } else {
          // CAMBIO: Usuario no logueado - mostrar avatar con "?" y botón login
          return _NotLoggedInAvatar(authProvider: authProvider);
        }
      },
    );
  }
}

/// NUEVO: Avatar para usuario logueado
class _LoggedInAvatar extends StatelessWidget {
  final MockAuthProvider authProvider; // CAMBIO: Tipo MockAuthProvider

  const _LoggedInAvatar({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(context, value),
      offset: const Offset(0, 40), // NUEVO: Posicionar dropdown
      itemBuilder:
          (context) => [
            // NUEVO: Header con info del usuario
            PopupMenuItem<String>(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authProvider.userName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authProvider.userEmail,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  const Divider(),
                ],
              ),
            ),
            // NUEVO: Opción de perfil (futuro)
            const PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline),
                  SizedBox(width: 12),
                  Text('Mi perfil'),
                ],
              ),
            ),
            // NUEVO: Opción de favoritos
            const PopupMenuItem<String>(
              value: 'favorites',
              child: Row(
                children: [
                  Icon(Icons.favorite_outline),
                  SizedBox(width: 12),
                  Text('Mis favoritos'),
                ],
              ),
            ),
            // NUEVO: Opción de configuración
            const PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined),
                  SizedBox(width: 12),
                  Text('Configuración'),
                ],
              ),
            ),
            // NUEVO: Separador
            const PopupMenuDivider(),
            // NUEVO: Cerrar sesión
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 12),
                  Text('Cerrar sesión', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
      child: _AvatarCircle(authProvider: authProvider),
    );
  }

  /// NUEVO: Manejar selección del menú
  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        // NUEVO: Abrir perfil (futuro)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil - Próximamente')));
        break;
      case 'favorites':
        // NUEVO: Navegar a favoritos
        Navigator.pushNamed(context, '/favorites');
        break;
      case 'settings':
        // NUEVO: Abrir configuración (futuro)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración - Próximamente')),
        );
        break;
      case 'logout':
        // NUEVO: Confirmar logout
        _showLogoutDialog(context);
        break;
    }
  }

  /// NUEVO: Mostrar diálogo de confirmación de logout
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Cerrar sesión'),
            content: const Text('¿Estás seguro de que querés cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  authProvider.signOut();
                },
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
    );
  }
}

/// NUEVO: Avatar para usuario NO logueado - muestra "?" e invita a login
class _NotLoggedInAvatar extends StatelessWidget {
  final MockAuthProvider authProvider; // CAMBIO: Tipo MockAuthProvider

  const _NotLoggedInAvatar({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          () => _showLoginOptions(context), // NUEVO: Mostrar opciones de login
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color:
              authProvider
                  .getAvatarColor(), // NUEVO: Color gris para no logueado
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withAlpha(77), width: 2),
        ),
        child: Center(
          child: Text(
            '?', // NUEVO: Mostrar "?" cuando no está logueado
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18, // CAMBIO: Ligeramente más grande
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  /// NUEVO: Mostrar opciones de login al tocar avatar
  void _showLoginOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NUEVO: Título del modal
                Text(
                  'Iniciar sesión',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // NUEVO: Descripción
                Text(
                  'Accedé a tus favoritos y personaliza tu experiencia',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // NUEVO: Botón de login con Google
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context); // NUEVO: Cerrar modal
                      authProvider.signInWithGoogle(); // NUEVO: Intentar login
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('Continuar con Google'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // NUEVO: Botón cancelar
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Quizás más tarde'),
                ),
              ],
            ),
          ),
    );
  }
}

/// NUEVO: Círculo del avatar (compartido entre logueado y no logueado)
class _AvatarCircle extends StatelessWidget {
  final MockAuthProvider authProvider; // CAMBIO: Tipo MockAuthProvider

  const _AvatarCircle({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: authProvider.getAvatarColor(),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withAlpha(77), width: 2),
      ),
      child:
          authProvider.userPhotoUrl.isNotEmpty
              ? ClipOval(
                child: Image.network(
                  authProvider.userPhotoUrl,
                  width: 36,
                  height: 36,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // NUEVO: Fallback a iniciales si falla la imagen
                    return _InitialsAvatar(authProvider: authProvider);
                  },
                ),
              )
              : _InitialsAvatar(authProvider: authProvider),
    );
  }
}

/// NUEVO: Avatar con iniciales (muestra "?" si no está logueado)
class _InitialsAvatar extends StatelessWidget {
  final MockAuthProvider authProvider; // CAMBIO: Tipo MockAuthProvider

  const _InitialsAvatar({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        authProvider.userInitials, // NUEVO: Será "?" si no está logueado
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
