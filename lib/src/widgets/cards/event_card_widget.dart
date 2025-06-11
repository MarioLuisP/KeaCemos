import 'package:flutter/material.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/pages/event_detail_page.dart';

class EventCardWidget extends StatelessWidget {
  final Map<String, String> event;
  final HomeViewModel viewModel;

  const EventCardWidget({
    Key? key,
    required this.event,
    required this.viewModel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formattedDate = viewModel.formatEventDate(event['date']!);
    final cardColor = viewModel.getEventCardColor(event['type'] ?? '', context);

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
        color: cardColor,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 6.0, // Puedes usar AppDimens si está definido
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16), // Puedes usar AppDimens
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title']!,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Fecha: $formattedDate'),
              const SizedBox(height: 4),
              Text('Ubicación: ${event['location']}'),
            ],
          ),
        ),
      ),
    );
  }
}