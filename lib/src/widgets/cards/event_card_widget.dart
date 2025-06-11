import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/pages/event_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:quehacemos_cba/src/services/auth_service.dart';

class EventCardWidget extends StatelessWidget {
  final Map<String, String> event;
  final HomeViewModel viewModel;

  const EventCardWidget({
    Key? key,
    required this.event,
    required this.viewModel,
  }) : super(key: key);

  // Método para oscurecer un color en un 20%
  Color _darkenColor(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  @override
  Widget build(BuildContext context) {
    final parsedDate = viewModel.parseDate(event['date']!);
    final formattedTime = parsedDate.hour > 0 || parsedDate.minute > 0
        ? '${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')} hs'
        : '';
    final cardColor = viewModel.getEventCardColor(event['type'] ?? '', context);
    final darkCardColor = _darkenColor(cardColor, 0.2); // 20% más oscuro

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailPage(event: event),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [cardColor, darkCardColor],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event['title']!,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface, // Asegura contraste
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (formattedTime.isNotEmpty)
                        Text(
                          'Hora: $formattedTime',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Ubicación: ${event['location']}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: IconButton(
                    iconSize: 24,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.favorite_border),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () {
                      if (FirebaseAuth.instance.currentUser == null) {
                        AuthService().signInWithGoogle().then((_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sesión iniciada')),
                          );
                        }).catchError((error) {
                          print('Error signing in: $error');
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}