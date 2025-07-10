import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/widgets/contact_modal.dart';

class ContactButton extends StatefulWidget {
  const ContactButton({super.key});

  @override
  State<ContactButton> createState() => _ContactButtonState();
}

class _ContactButtonState extends State<ContactButton> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    // NUEVO: Configurar animación de pulso para llamar la atención
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // NUEVO: Repetir animación
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: IconButton(
            onPressed: () => _showContactModal(context),
            icon: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add_circle_outline, // NUEVO: Ícono de agregar
                color: Colors.white,
                size: 18,
              ),
            ),
            tooltip: 'Publicar evento',
          ),
        );
      },
    );
  }

  /// NUEVO: Mostrar modal de contacto
  void _showContactModal(BuildContext context) {
    // NUEVO: Parar animación mientras se muestra el modal
    _animationController.stop();
    
    ContactModal.show(context).then((_) {
      // NUEVO: Reanudar animación cuando se cierre el modal
      if (mounted) {
        _animationController.repeat(reverse: true);
      }
    });
  }
}

/// NUEVO: Versión alternativa sin animación (más discreta)
class ContactButtonSimple extends StatelessWidget {
  const ContactButtonSimple({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => ContactModal.show(context),
      icon: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.add_circle_outline,
          color: Colors.white,
          size: 18,
        ),
      ),
      tooltip: 'Publicar evento',
    );
  }
}

/// NUEVO: Versión con texto (para espacios más amplios)
class ContactButtonWithText extends StatelessWidget {
  const ContactButtonWithText({super.key});

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => ContactModal.show(context),
      icon: const Icon(
        Icons.add_circle_outline,
        color: Colors.white,
        size: 18,
      ),
      label: const Text(
        'Publicar',
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

/// NUEVO: Versión FAB (Floating Action Button) como alternativa
class ContactFAB extends StatelessWidget {
  const ContactFAB({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => ContactModal.show(context),
      backgroundColor: Theme.of(context).colorScheme.primary,
      foregroundColor: Colors.white,
      tooltip: 'Publicar evento',
      child: const Icon(Icons.add),
    );
  }
}

/// NUEVO: Versión con badge "NUEVO" (para promocionar la función)
class ContactButtonWithBadge extends StatelessWidget {
  const ContactButtonWithBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: () => ContactModal.show(context),
          icon: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.add_circle_outline,
              color: Colors.white,
              size: 18,
            ),
          ),
          tooltip: 'Publicar evento',
        ),
        // NUEVO: Badge "NUEVO"
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: const Text(
              'NUEVO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}