/// Detail page for displaying event information.
library;
import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  final Map<String, String> event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event['title'] ?? 'Detalle del Evento'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              'https://picsum.photos/seed/jazz/400/200',
              height: 200,
              fit: BoxFit.cover,
              // Añadir manejo de errores para la imagen
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
            ),
            const SizedBox(height: 16.0),
            Text(
              event['title'] ?? 'Título no disponible',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Fecha y Hora: ${event['date'] ?? 'Fecha no disponible'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4.0),
            Text(
              'Ubicación: ${event['location'] ?? 'Ubicación no disponible'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Descripción del evento: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16.0),
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.favorite_border),
                color: Colors.red,
                onPressed: () {
                  // Placeholder para favoritos (Prompt 7)
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}