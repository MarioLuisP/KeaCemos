import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/src/services/auth_service.dart';
import 'package:myapp/src/services/event_service.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/pages/pages.dart';
import 'package:myapp/src/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/providers/preferences_provider.dart';
import 'package:myapp/src/widgets/chips/event_chip_widget.dart'; // Corregido: chips

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
    print('HomePage inicializado con selectedDate: $_selectedDate');
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedDate != oldWidget.selectedDate) {
      setState(() {
        _selectedDate = widget.selectedDate;
        print('HomePage actualizado con nuevo selectedDate: $_selectedDate');
      });
    }
  }

  Future<List<Map<String, String>>> _getEventsForDay(DateTime day) async {
    return await _eventService.getEventsForDay(day);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreferencesProvider>(context);
    final now = DateTime(2025, 6, 4);
    final todayString = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowString = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    print('Fecha actual para pruebas: $now');

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
        if (displayedEvents.isEmpty) {
          displayedEvents = [
            {'title': 'Exposición de Arte Moderno', 'type': 'exposición', 'date': '2025-06-04', 'location': 'Museo B'},
            {'title': 'Obra de Teatro: Hamlet', 'type': 'teatro', 'date': '2025-06-04', 'location': 'Teatro Real'},
            {'title': 'Noche de Stand-up', 'type': 'stand-up', 'date': '2025-06-04', 'location': 'Club B'},
          ];
        }
        String listTitle = _selectedDate == null
            ? 'Próximos Eventos'
            : 'Eventos para ${DateFormat('EEEE, d MMM', 'es').format(_selectedDate!)}';

        final categoryMapping = {
          'Música': 'música',
          'Teatro': 'teatro',
          'StandUp': 'stand-up',
          'Arte': 'exposición',
          'Cine': 'cine',
          'Mic': 'mic',
          'Cursos': 'talleres',
          'Ferias': 'ferias',
          'Calle': 'calle',
          'Redes': 'comunidad',
        };

        if (provider.activeFilterCategories.isNotEmpty) {
          displayedEvents = displayedEvents.where((event) {
            final eventType = event['type']?.toLowerCase() ?? '';
            final normalizedCategories = provider.activeFilterCategories
                .map((c) => categoryMapping[c] ?? c.toLowerCase());
            return normalizedCategories.contains(eventType);
          }).toList();
        }

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
              style: TextStyle(fontWeight: FontWeight.normal),
            ),
            centerTitle: true,
            toolbarHeight: 40.0,
          ),
          body: CustomScrollView(
            slivers: [
              SliverPersistentHeader(
                pinned: true,
                delegate: _HeaderDelegate(
                  title: listTitle,
                  categories: provider.selectedCategories.isEmpty
                      ? ['Música', 'Teatro', 'Cine', 'Stand-up']
                      : provider.selectedCategories
                          .map((c) => c == 'StandUp' ? 'Stand-up' : c)
                          .toList(),
                ),
              ),
              if (displayedEvents.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _selectedDate == null
                            ? 'No hay eventos próximos.'
                            : 'No hay eventos para esta fecha.',
                      ),
                    ),
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
                  return SliverList(
                    delegate: SliverChildListDelegate([
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 2.0,
                        ),
                        child: Text(
                          sectionTitle,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                        ),
                      ),
                      const Divider(
                        thickness: 0.5,
                        indent: 16.0,
                        endIndent: 16.0,
                        color: Colors.grey,
                      ),
                      ...eventsOnDate.asMap().entries.map((entry) {
                        final event = entry.value;
                        return _buildEventCard(context, event, entry.key);
                      }).toList(),
                    ]),
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
        : eventDate == DateTime(now.year, now.month, now.day).add(const Duration(days: 1))
            ? 'Mañana'
            : DateFormat('d MMM yyyy', 'es').format(eventDate);

    Color cardColor;
    final eventType = event['type']?.toLowerCase() ?? '';
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
      case 'mic':
        cardColor = const Color(0xFFE0E0E0);
        break;
      case 'ferias':
        cardColor = const Color(0xFFE0E0E0);
        break;
      default:
        cardColor = const Color(0xFFE0E0E0);
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
        elevation: AppDimens.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimens.borderRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title']!,
                style: AppStyles.cardTitle,
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

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final List<String> categories;

  _HeaderDelegate({required this.title, required this.categories});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 0.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
            ),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 4.0,
              crossAxisSpacing: 4.0,
              childAspectRatio: 3.5,
              children: categories.map((category) {
                return EventChipWidget(category: category);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  double get maxExtent => 28.0 + 48.0; // Reducido

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _HeaderDelegate oldDelegate) {
    return title != oldDelegate.title || categories != oldDelegate.categories;
  }
}