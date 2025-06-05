import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/services/event_service.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/pages/pages.dart';

class HomePage extends StatefulWidget {
  final DateTime? selectedDate;
  const HomePage({super.key, this.selectedDate});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _selectedDate;
  final EventService _eventService = EventService();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
  }

  Future<List<Map<String, String>>> _getEventsForDay(DateTime day) async {
    return await _eventService.getEventsForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime(2025, 6, 4);
    final todayString = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    print('Fecha actual para pruebas: $now');
    print('Fecha real del sistema: ${DateTime.now()}');

    return FutureBuilder<List<Map<String, String>>>(
      future: _selectedDate == null
          ? _eventService.getAllEvents()
          : _getEventsForDay(_selectedDate!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar eventos'));
        }
        List<Map<String, String>> displayedEvents = snapshot.data ?? [];
        String listTitle = _selectedDate == null
            ? 'Próximos Eventos'
            : 'Eventos para ${DateFormat('EEEE, d MMM', 'es').format(_selectedDate!)}';

        if (_selectedDate == null) {
          final todayEvents = displayedEvents
              .where((event) => event['date'] == todayString)
              .toList();
          final tomorrowEvents = displayedEvents
              .where((event) => event['date'] == tomorrowString)
              .toList();
          final futureEvents = displayedEvents.where((event) {
            final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!);
            return eventDate.isAfter(now.add(const Duration(days: 1)));
          }).toList();
          displayedEvents = [
            ...todayEvents,
            ...tomorrowEvents,
            ...futureEvents,
          ].take(20).toList();
        }

        print('displayedEvents: $displayedEvents');

        final Map<String, List<Map<String, String>>> groupedEvents = {};
        for (var event in displayedEvents) {
          final date = event['date']!;
          if (!groupedEvents.containsKey(date)) {
            groupedEvents[date] = [];
          }
          groupedEvents[date]!.add(event);
        }

        final sortedDates = groupedEvents.keys.toList()
          ..sort((a, b) {
            final dateA = DateFormat('yyyy-MM-dd').parse(a);
            final dateB = DateFormat('yyyy-MM-dd').parse(b);
            if (a == todayString) return -2;
            if (b == todayString) return 2;
            if (a == tomorrowString) return -1;
            if (b == tomorrowString) return 1;
            return dateA.compareTo(dateB);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              '🌟 KeaCMos Córdoba',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            centerTitle: true,
          ),
          body: ListView(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  listTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                ),
              ),
              const Divider(
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: Colors.grey,
              ),
              if (displayedEvents.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No hay eventos para esta fecha.'),
                  ),
                )
              else
                ...sortedDates.map((date) {
                  final eventsOnDate = groupedEvents[date]!;
                  final dateParsed = DateFormat('yyyy-MM-dd').parse(date);
                  final sectionTitle = date == todayString
                      ? 'Hoy'
                      : date == tomorrowString
                          ? 'Mañana'
                          : 'Próximos (${DateFormat('EEEE, d MMM', 'es').format(dateParsed)})';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Text(
                          sectionTitle,
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                        ),
                      ),
                      const Divider(
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Colors.grey,
                      ),
                      ...eventsOnDate.asMap().entries.map((entry) {
                        final event = entry.value;
                        return _buildEventCard(context, event, entry.key);
                      }).toList(),
                    ],
                  );
                }).toList(),
            ],
          ),
        );
      },
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
    print('Evento completo: $event');

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
    );
  }
}