import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/services/event_service.dart';
import 'package:myapp/src/pages/pages.dart';
import 'package:myapp/src/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/providers/preferences_provider.dart';
import 'package:myapp/src/widgets/chips/event_chip_widget.dart'; // Corregido: chips

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
    print('ExplorePage inicializada');
  }

  void _loadInitialEvents() async {
    try {
      var events = await _eventService.getAllEvents();
      print('Eventos desde EventService: $events');
      if (events.isEmpty) {
        events = [
          {'title': 'Exposición de Arte Moderno', 'type': 'exposición', 'date': '2025-06-04', 'location': 'Museo B'},
          {'title': 'Obra de Teatro: Hamlet', 'type': 'teatro', 'date': '2025-06-04', 'location': 'Teatro Real'},
          {'title': 'Noche de Stand-up', 'type': 'stand-up', 'date': '2025-06-04', 'location': 'Club B'},
          {'title': 'Festival de Cine Independiente', 'type': 'cine', 'date': '2025-06-05', 'location': 'Cine C'},
          {'title': 'Show Infantil: Cuentacuentos', 'type': 'infantil', 'date': '2025-06-05', 'location': 'Plaza D'},
          {'title': 'Monólogo: Risa Local', 'type': 'stand-up', 'date': '2025-06-05', 'location': 'Café Cultural V'},
          {'title': 'Recital de Indie Rock', 'type': 'música', 'date': '2025-06-06', 'location': 'Club del Arte'},
        ];
        print('Usando datos estáticos: $events');
      }
      if (mounted) {
        setState(() {
          _searchResults = events;
          print('Eventos iniciales cargados: ${_searchResults.length}');
        });
      }
    } catch (e) {
      print('Error cargando eventos: $e');
    }
  }

  void _onSearchChanged() async {
    final query = _searchController.text;
    try {
      if (query.isEmpty) {
        var events = await _eventService.getAllEvents();
        if (events.isEmpty) {
          events = [
            {'title': 'Exposición de Arte Moderno', 'type': 'exposición', 'date': '2025-06-04', 'location': 'Museo B'},
            {'title': 'Obra de Teatro: Hamlet', 'type': 'teatro', 'date': '2025-06-04', 'location': 'Teatro Real'},
            {'title': 'Noche de Stand-up', 'type': 'stand-up', 'date': '2025-06-04', 'location': 'Club B'},
          ];
        }
        if (mounted) {
          setState(() {
            _searchResults = events;
            print('Eventos cargados sin búsqueda: ${_searchResults.length}');
          });
        }
      } else {
        final results = await _eventService.searchEvents(query);
        if (mounted) {
          setState(() {
            _searchResults = results.isEmpty
                ? [
                    {'title': 'Noche de Stand-up', 'type': 'stand-up', 'date': '2025-06-04', 'location': 'Club B'},
                  ]
                : results;
            print('Resultados de búsqueda para "$query": ${_searchResults.length}');
          });
        }
      }
    } catch (e) {
      print('Error buscando eventos: $e');
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
    final provider = Provider.of<PreferencesProvider>(context);
    print('Categorías seleccionadas: ${provider.selectedCategories}');
    print('Categorías de filtro activas: ${provider.activeFilterCategories}');

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

    final normalizedCategories = provider.activeFilterCategories
        .map((c) => categoryMapping[c] ?? c.toLowerCase())
        .toSet();
    print('Categorías normalizadas: $normalizedCategories');

    List<Map<String, String>> filteredResults = _searchResults;
    if (normalizedCategories.isNotEmpty) {
      filteredResults = _searchResults.where((event) {
        final eventType = event['type']?.toLowerCase() ?? '';
        return normalizedCategories.contains(eventType);
      }).toList();
      print('Eventos filtrados por categorías: ${filteredResults.length}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Explorar Eventos'),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ChipsHeaderDelegate(
              categories: provider.selectedCategories.isEmpty
                  ? ['Música', 'Teatro', 'Cine', 'Stand-up']
                  : provider.selectedCategories
                      .map((c) => c == 'StandUp' ? 'Stand-up' : c)
                      .toList(),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Busca eventos (ej. payasos)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (filteredResults.isEmpty) {
                  print('Mostrando mensaje: No hay resultados');
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No hay resultados'),
                    ),
                  );
                }
                final event = filteredResults[index];
                return _buildEventCard(context, event, index);
              },
              childCount: filteredResults.isEmpty ? 1 : filteredResults.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, String> event, int index) {
    print('Construyendo tarjeta para evento: ${event['title']}');
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

class _ChipsHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<String> categories;

  _ChipsHeaderDelegate({required this.categories});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 8.0,
        ),
        child: GridView.count(
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
      ),
    );
  }

  @override
  double get maxExtent => 80.0; // Aumentado

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(covariant _ChipsHeaderDelegate oldDelegate) {
    return categories != oldDelegate.categories;
  }
}