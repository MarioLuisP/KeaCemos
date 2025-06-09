import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/providers/home_viewmodel.dart';

class CalendarPage extends StatefulWidget {
  final Function(DateTime?)? onDateSelected;
  const CalendarPage({super.key, this.onDateSelected});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime(2025, 6, 4); // Mantener fecha de desarrollo
  DateTime? _selectedDay;
  late HomeViewModel _homeViewModel;
  final Map<DateTime, List<Map<String, String>>> _eventCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _homeViewModel = HomeViewModel();
    _initializeViewModel();
    print('Calendario inicializado: $_focusedDay');
  }

  Future<void> _initializeViewModel() async {
    await _homeViewModel.initialize();
    await _preloadEvents();
  }

  Future<void> _preloadEvents() async {
    // Cargar todos los eventos y cachearlos por fecha
    await _homeViewModel.loadEvents();
    final events = _homeViewModel.filteredEvents;
    
    _eventCache.clear();
    for (var event in events) {
      final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!);
      final cacheKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
      _eventCache[cacheKey] ??= [];
      _eventCache[cacheKey]!.add(event);
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final cacheKey = DateTime(day.year, day.month, day.day);
    return _eventCache[cacheKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    print('Día seleccionado: $selectedDay');
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    
    // Notificar al callback si existe (para navegación entre páginas)
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(selectedDay);
    }
  }

  @override
  void dispose() {
    _homeViewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _homeViewModel,
      child: Consumer<HomeViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(_selectedDay == null
                  ? 'Selecciona una fecha'
                  : 'Eventos para ${DateFormat('EEEE, d MMM', 'es').format(_selectedDay!)}'),
              centerTitle: true,
              actions: [
                // Botón para ir a la fecha seleccionada en HomePage
                if (_selectedDay != null)
                  IconButton(
                    icon: const Icon(Icons.list),
                    tooltip: 'Ver eventos de este día',
                    onPressed: () {
                      // Navegar a HomePage con la fecha seleccionada
                      Navigator.pop(context);
                      if (widget.onDateSelected != null) {
                        widget.onDateSelected!(_selectedDay);
                      }
                    },
                  ),
              ],
            ),
            body: Column(
              children: [
                // Calendario
                TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: _onDaySelected,
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() => _calendarFormat = format);
                    }
                  },
                  onPageChanged: (focusedDay) {
                    print('Mes cambiado: $focusedDay');
                    setState(() => _focusedDay = focusedDay);
                    _preloadEvents();
                  },
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final eventsForDay = _getEventsForDay(date);
                      if (eventsForDay.isNotEmpty) {
                        return Container(
                          margin: const EdgeInsets.all(4.0),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.deepPurpleAccent.withOpacity(0.3),
                          ),
                          width: 40,
                          height: 40,
                          child: Center(
                            child: Text(
                              eventsForDay.length.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  eventLoader: _getEventsForDay,
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    formatButtonShowsNext: false,
                    formatButtonTextStyle: const TextStyle(color: Colors.white),
                    formatButtonDecoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    titleCentered: true,
                  ),
                  availableCalendarFormats: const {
                    CalendarFormat.month: 'Mes',
                    CalendarFormat.twoWeeks: '2 Semanas',
                    CalendarFormat.week: 'Semana',
                  },
                ),
                
                // Lista de eventos para el día seleccionado
                if (_selectedDay != null) ...[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Divider(),
                  ),
                  Expanded(
                    child: _buildEventsForSelectedDay(),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventsForSelectedDay() {
    final eventsForDay = _getEventsForDay(_selectedDay!);
    
    if (eventsForDay.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No hay eventos para esta fecha.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: eventsForDay.length,
      itemBuilder: (context, index) {
        final event = eventsForDay[index];
        final cardColor = _homeViewModel.getEventCardColor(event['type'] ?? '', context);
        
        return Card(
          color: cardColor,
          margin: const EdgeInsets.only(bottom: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListTile(
            title: Text(
              event['title']!,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📍 ${event['location']}'),
                Text('🎭 ${event['type']}'),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Navegar a EventDetailPage
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(
              //     builder: (context) => EventDetailPage(event: event),
              //   ),
              // );
            },
          ),
        );
      },
    );
  }
}