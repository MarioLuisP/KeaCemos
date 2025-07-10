import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/widgets/app_bars/components/user_avatar_widget.dart';
import 'package:quehacemos_cba/src/widgets/app_bars/components/notifications_bell.dart';
import 'package:quehacemos_cba/src/widgets/app_bars/components/contact_button.dart';

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? customActions;
  final bool showUserAvatar;
  final bool showNotifications;
  final bool showContactButton;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final bool centerTitle;

  const MainAppBar({
    super.key,
    this.title,
    this.customActions,
    this.showUserAvatar = true,
    this.showNotifications = true,
    this.showContactButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.centerTitle = true,
  });

  /// NUEVO: Constructor para HomePage (configuración por defecto)
  const MainAppBar.home({
    super.key,
    this.title = 'QuehaCeMos Córdoba',
    this.customActions,
    this.showUserAvatar = true,
    this.showNotifications = true,
    this.showContactButton = true,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.centerTitle = true,
  });

  /// NUEVO: Constructor para páginas internas (sin todos los componentes)
  const MainAppBar.internal({
    super.key,
    required this.title,
    this.customActions,
    this.showUserAvatar = false,
    this.showNotifications = false,
    this.showContactButton = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.centerTitle = true,
  });

  /// NUEVO: Constructor para páginas de auth (solo título)
  const MainAppBar.auth({
    super.key,
    this.title = 'QuehaCeMos Córdoba',
    this.customActions,
    this.showUserAvatar = false,
    this.showNotifications = false,
    this.showContactButton = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 2.0,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _buildTitle(context),
      centerTitle: centerTitle,
      toolbarHeight: preferredSize.height,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      actions: _buildActions(context),
    );
  }

  /// NUEVO: Construir título con estilo personalizado
  Widget _buildTitle(BuildContext context) {
    if (title == null) return const SizedBox.shrink();
    
    return Text(
      title!,
      style: TextStyle(
        fontFamily: 'Nunito', // NUEVO: Fuente personalizada
        fontWeight: FontWeight.bold,
        fontSize: _getTitleFontSize(title!),
        color: foregroundColor ?? Colors.white,
      ),
    );
  }

  /// NUEVO: Calcular tamaño de fuente basado en longitud del título
  double _getTitleFontSize(String title) {
    if (title.length > 20) {
      return 16.0; // NUEVO: Título largo
    } else if (title.length > 15) {
      return 18.0; // NUEVO: Título mediano
    } else {
      return 20.0; // NUEVO: Título corto
    }
  }

  /// NUEVO: Construir acciones de la AppBar
  List<Widget> _buildActions(BuildContext context) {
    final List<Widget> actions = [];

    // NUEVO: Acciones personalizadas primero
    if (customActions != null) {
      actions.addAll(customActions!);
    }

    // NUEVO: Componentes principales con espaciado
    if (showContactButton) {
      actions.add(const ContactButton());
    }

    if (showNotifications) {
      actions.add(const NotificationsBell());
    }

    if (showUserAvatar) {
      actions.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0), // NUEVO: Espaciado final
          child: const UserAvatarWidget(),
        ),
      );
    }

    return actions;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// NUEVO: AppBar especializada para calendario
class CalendarAppBar extends MainAppBar {
  const CalendarAppBar({
    super.key,
    String? title,
    List<Widget>? customActions,
  }) : super(
          title: title ?? 'Calendario',
          customActions: customActions,
          showUserAvatar: true,
          showNotifications: true,
          showContactButton: false, // NUEVO: No mostrar contacto en calendario
          centerTitle: true,
        );
}

/// NUEVO: AppBar especializada para favoritos
class FavoritesAppBar extends MainAppBar {
  const FavoritesAppBar({
    super.key,
    String? title,
    List<Widget>? customActions,
  }) : super(
          title: title ?? 'Mis Favoritos',
          customActions: customActions,
          showUserAvatar: true,
          showNotifications: false, // NUEVO: No mostrar notificaciones en favoritos
          showContactButton: false,
          centerTitle: true,
        );
}

/// NUEVO: AppBar especializada para búsqueda
class SearchAppBar extends MainAppBar {
  final TextEditingController? searchController;
  final Function(String)? onSearchChanged;
  final VoidCallback? onSearchSubmitted;

  const SearchAppBar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onSearchSubmitted,
    List<Widget>? customActions,
  }) : super(
          title: null, // NUEVO: No mostrar título, solo barra de búsqueda
          customActions: customActions,
          showUserAvatar: false,
          showNotifications: false,
          showContactButton: false,
          centerTitle: false,
        );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: _buildSearchField(context),
      centerTitle: false,
      toolbarHeight: preferredSize.height,
      elevation: elevation,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      actions: _buildSearchActions(context),
    );
  }

  /// NUEVO: Campo de búsqueda personalizado
  Widget _buildSearchField(BuildContext context) {
    return TextField(
      controller: searchController,
      onChanged: onSearchChanged,
      onSubmitted: (value) => onSearchSubmitted?.call(),
      style: TextStyle(
        color: foregroundColor ?? Colors.white,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar eventos...',
        hintStyle: TextStyle(
          color: (foregroundColor ?? Colors.white).withOpacity(0.7),
        ),
        border: InputBorder.none,
        prefixIcon: Icon(
          Icons.search,
          color: (foregroundColor ?? Colors.white).withOpacity(0.7),
        ),
      ),
    );
  }

  /// NUEVO: Acciones para la barra de búsqueda
  List<Widget> _buildSearchActions(BuildContext context) {
    return [
      // NUEVO: Botón para limpiar búsqueda
      if (searchController?.text.isNotEmpty ?? false)
        IconButton(
          onPressed: () {
            searchController?.clear();
            onSearchChanged?.call('');
          },
          icon: Icon(
            Icons.clear,
            color: foregroundColor ?? Colors.white,
          ),
        ),
      
      // NUEVO: Botón para cerrar búsqueda
      IconButton(
        onPressed: () => Navigator.pop(context),
        icon: Icon(
          Icons.close,
          color: foregroundColor ?? Colors.white,
        ),
      ),
    ];
  }
}

/// NUEVO: Extension para fácil uso en diferentes contextos
extension MainAppBarExtensions on MainAppBar {
  /// NUEVO: Crear copia con nuevos parámetros
  MainAppBar copyWith({
    String? title,
    List<Widget>? customActions,
    bool? showUserAvatar,
    bool? showNotifications,
    bool? showContactButton,
    Color? backgroundColor,
    Color? foregroundColor,
    double? elevation,
    bool? centerTitle,
  }) {
    return MainAppBar(
      title: title ?? this.title,
      customActions: customActions ?? this.customActions,
      showUserAvatar: showUserAvatar ?? this.showUserAvatar,
      showNotifications: showNotifications ?? this.showNotifications,
      showContactButton: showContactButton ?? this.showContactButton,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      elevation: elevation ?? this.elevation,
      centerTitle: centerTitle ?? this.centerTitle,
    );
  }
}

/// NUEVO: Mixin para páginas que usan MainAppBar
mixin MainAppBarMixin {
  /// NUEVO: Método helper para crear AppBar estándar
  PreferredSizeWidget buildMainAppBar({
    String? title,
    List<Widget>? customActions,
    bool showUserAvatar = true,
    bool showNotifications = true,
    bool showContactButton = true,
  }) {
    return MainAppBar(
      title: title,
      customActions: customActions,
      showUserAvatar: showUserAvatar,
      showNotifications: showNotifications,
      showContactButton: showContactButton,
    );
  }
}