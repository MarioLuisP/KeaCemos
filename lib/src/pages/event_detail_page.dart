/// Detail page for displaying event information.

import 'package:flutter/material.dart';

class EventDetailPage extends StatelessWidget {
  final Map<String, String> event;

  const EventDetailPage({Key? key, required this.event}) : super(key: key);

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
            ),
            const SizedBox(height: 16.0),
            // Title
            Text(
              event['title'] ?? 'Título no disponible',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            // Date and Time
            Text(
              'Fecha y Hora: ${event['date'] ?? 'Fecha no disponible'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 4.0),
            // Address
            Text(
              'Ubicación: ${event['location'] ?? 'Ubicación no disponible'}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16.0),
            // Description
            const Text(
              'Descripción del evento: Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.', // Mock Description
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16.0),
            // Favorite Button
            Align(
              alignment: Alignment.bottomRight,
              child: IconButton(
                icon: const Icon(Icons.favorite_border),
                color: Colors.red,
                onPressed: () {
                  // Non-functional favorite button
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}