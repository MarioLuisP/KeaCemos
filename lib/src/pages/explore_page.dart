import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/services/event_service.dart';
import 'package:myapp/src/pages/pages.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();
  final EventService _eventService = EventService();
  List<Map<String, String>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadInitialEvents();
  }

  void _loadInitialEvents() async {
    final events = await _eventService.getAllEvents();
    if (mounted) {
      setState(() {
        _searchResults = events;
      });
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      final events = await _eventService.getAllEvents();
      if (mounted) {
        setState(() {
          _searchResults = events;
        });
      }
    } else {
      final results = await _eventService.searchEvents(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
        });
      }
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Eventos'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Busca eventos (ej. payasos)',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? const Center(child: Text('No hay resultados'))
                : ListView.builder(
                    itemCount: _searchResults.length,
                    itemBuilder: (context, index) {
                      final event = _searchResults[index];
                      return _buildEventCard(context, event, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, String> event, int index) {
    final now = DateTime(2025, 6, 4);
    final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!);
    final formattedDate = eventDate == DateTime(now.year, now.month, now.day)
        ? 'Hoy'
        : eventDate ==
                DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
            ? 'Mañana'
            : DateFormat('d MMM yyyy', 'es').format(eventDate);
    print(
        'Evento: ${event['title']}, Fecha original: ${event['date']}, Fecha formateada: $formattedDate');

    Color cardColor;
    final eventType = event['type']?.toLowerCase() ?? '';
    print('Tipo de evento: $eventType');
    switch (eventType) {
      case 'teatro':
        cardColor = const Color(0xFFB2DFDB);
        break;
      case 'stand-up':
        cardColor = const Color(0xFFFFF9C4);
        break;
      case 'música':
        cardColor = const Color(0xFFCCE5FF);
        break;
      case 'cine':
        cardColor = const Color(0xFFE0E0E0);
        break;
      case 'infantil':
        cardColor = const Color(0xFFE1BEE7);
        break;
      case 'exposición':
        cardColor = const Color(0xFFFFECB3);
        break;
      default:
        cardColor = const Color(0xFFE0E0E0);
        print('Color por defecto para tipo: $eventType');
        break;
    }

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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title']!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Fecha: $formattedDate'),
              const SizedBox(height: 4),
              Text('Ubicación: ${event['location']}'),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: const Icon(Icons.favorite_border),
                  onPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}