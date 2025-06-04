import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:myapp/l10n/intl_messages_all.dart';
import 'package:myapp/src/pages/pages.dart';
import 'package:myapp/src/models/models.dart'; // Importa events

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // events ahora está en models.dart
  events.sort((a, b) => a['date']!.compareTo(b['date']!));
  print('Lista de eventos: $events'); // Depuración
  await initializeMessages('es_ES');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', ''),
        Locale('en', ''),
      ],
      title: 'KeaCMos Córdoba',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  DateTime? _selectedDate;

  List<Map<String, String>> _getEventsForDate(DateTime date) {
    final dateString = DateFormat('yyyy-MM-dd').format(date);
    return events.where((event) => event['date'] == dateString).toList();
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, String>> displayedEvents = [];
    String listTitle = '';

    final now = DateTime(2025, 6, 4);
    print('Fecha actual para pruebas: $now');
    print('Fecha real del sistema: ${DateTime.now()}');

    if (_selectedDate == null) {
      final today = DateFormat('yyyy-MM-dd').format(now);
      final tomorrow = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
      final todayEvents = events.where((event) => event['date'] == today).toList();
      final tomorrowEvents = events.where((event) => event['date'] == tomorrow).toList();
      displayedEvents = [
        ...todayEvents,
        ...tomorrowEvents,
        ...events.where((event) => event['date'] != today && event['date'] != tomorrow),
      ].take(20).toList();
      listTitle = 'Próximos Eventos';
    } else {
      final selectedDateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      displayedEvents = events.where((event) => event['date'] == selectedDateString).toList();
      listTitle = 'Eventos para ${DateFormat('EEEE, d MMM', 'es').format(_selectedDate!)}';
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

    final sortedDates = groupedEvents.keys.toList()..sort((a, b) => a.compareTo(b));

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🌟 KeaCMos Córdoba',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CalendarPage()),
          ).then((selectedDate) {
            if (selectedDate != null && selectedDate is DateTime) {
              setState(() => _selectedDate = selectedDate);
            }
          });
        },
        child: const Icon(Icons.calendar_today),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Text(
                      date == DateFormat('yyyy-MM-dd').format(now)
                          ? 'Hoy'
                          : date == DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)))
                              ? 'Mañana'
                              : DateFormat('EEEE, d MMM', 'es').format(DateFormat('yyyy-MM-dd').parse(date)),
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
  }

  Widget _buildEventCard(BuildContext context, Map<String, String> event, int index) {
    final now = DateTime(2025, 6, 4);
    final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!);
    final formattedDate = eventDate == DateTime(now.year, now.month, now.day)
        ? 'Hoy'
        : eventDate == DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
            ? 'Mañana'
            : DateFormat('d MMM yyyy', 'es').format(eventDate);
    print('Evento: ${event['title']}, Fecha original: ${event['date']}, Fecha formateada: $formattedDate');
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