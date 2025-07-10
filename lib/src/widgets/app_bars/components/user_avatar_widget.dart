import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/auth_provider.dart';

class UserAvatarWidget extends StatelessWidget {
  const UserAvatarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          // NUEVO: Mostrar loading mientras se autentica
          return const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        if (authProvider.isLoggedIn) {
          // NUEVO: Usuario logueado - mostrar avatar con dropdown
          return _LoggedInAvatar(authProvider: authProvider);
        } else {
          // NUEVO: Usuario no logueado - mostrar botón de login
          return _LoginButton(authProvider: authProvider);
        }
      },
    );
  }
}

/// NUEVO: Avatar para usuario logueado
class _LoggedInAvatar extends StatelessWidget {
  final AuthProvider authProvider;

  const _LoggedInAvatar({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuSelection(context, value),
      offset: const Offset(0, 40), // NUEVO: Posicionar dropdown
      itemBuilder: (context) => [
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
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil - Próximamente')),
        );
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
      builder: (context) => AlertDialog(
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

/// NUEVO: Botón de login para usuario no logueado
class _LoginButton extends StatelessWidget {
  final AuthProvider authProvider;

  const _LoginButton({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => authProvider.signInWithGoogle(),
      icon: const Icon(
        Icons.person_outline,
        color: Colors.white,
        size: 20,
      ),
      label: const Text(
        'Entrar',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

/// NUEVO: Círculo del avatar
class _AvatarCircle extends StatelessWidget {
  final AuthProvider authProvider;

  const _AvatarCircle({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: authProvider.getAvatarColor(),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: authProvider.userPhotoUrl.isNotEmpty
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

/// NUEVO: Avatar con iniciales
class _InitialsAvatar extends StatelessWidget {
  final AuthProvider authProvider;

  const _InitialsAvatar({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        authProvider.userInitials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}