import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/cards/fast_event_card.dart'; 

class CalendarPage extends StatefulWidget {
  final Function(DateTime)? onDateSelected;
  const CalendarPage({super.key, this.onDateSelected});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  late HomeViewModel _homeViewModel;
  final Map<DateTime, List<Map<String, dynamic>>> _eventCache = {}; 

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
    final events = await _homeViewModel.getEventsForMonth(_focusedDay);
    _eventCache.clear();
    for (var event in events) {
      final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!);
      final cacheKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
      _eventCache[cacheKey] ??= [];
      _eventCache[cacheKey]!.add(event);
    }
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) { //
    final cacheKey = DateTime(day.year, day.month, day.day);
    return _eventCache[cacheKey] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    print('Día seleccionado: $selectedDay');
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

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
              title: const Text('Elije el Día'),
              centerTitle: true,
              toolbarHeight: 40.0,
              elevation: 2.0,
              actions: [],
            ),
            body: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), // CAMBIO: margin en lugar de padding
                  decoration: BoxDecoration(
                    color: Color(0xB3FFFFFF), // NUEVO: Fondo transparente
                    borderRadius: BorderRadius.circular(16.0), // NUEVO: Bordes redondeados
                    border: Border.all(
                      color: Color(0x4DFFFFFF), // NUEVO: Borde sutil
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x0D000000), // NUEVO: Sombra muy sutil
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0), // NUEVO: Padding interno
                    child: TableCalendar(
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
                    daysOfWeekHeight: 20,
                    rowHeight: 40,
                    calendarStyle: CalendarStyle(
                      todayDecoration: BoxDecoration(
                        color: Colors.blue[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      selectedDecoration: BoxDecoration(
                        color: Colors.blue[400],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      defaultDecoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      weekendDecoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      outsideDecoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      defaultTextStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      weekendTextStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      outsideTextStyle: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                      todayTextStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                      selectedTextStyle: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

// ARREGLO MÍNIMO para calendar_page.dart
// SOLO CAMBIAR EL calendarBuilders:

calendarBuilders: CalendarBuilders(
  // ✅ ARREGLO: Today builder que respeta si está seleccionado
  todayBuilder: (context, day, focusedDay) {
    final isSelected = isSameDay(_selectedDay, day);
    final eventsForDay = _getEventsForDay(day);
    
    return Center(
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          // Si está seleccionado, usar color de selección
          // Si no, usar color de "today"
          color: isSelected 
              ? Colors.blue[400] 
              : (eventsForDay.isNotEmpty ? Colors.orange[300] : Colors.blue[200]),
          borderRadius: BorderRadius.circular(8.0),
          // Borde extra para "today" cuando no está seleccionado
          border: isSelected ? null : Border.all(color: Colors.blue[600]!, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  },
  
  // ✅ ARREGLO: Selected builder que NO interfiere con today
  selectedBuilder: (context, day, focusedDay) {
    // Solo actuar si NO es today (today builder se encarga)
    if (isSameDay(day, DateTime.now())) {
      return null; // Dejar que todayBuilder maneje
    }
    
    final eventsForDay = _getEventsForDay(day);
    return Center(
      child: Container(
        width: 28,
        height: 28,
        margin: const EdgeInsets.only(bottom: 1),
        decoration: BoxDecoration(
          color: eventsForDay.isNotEmpty ? Colors.purple[300] : Colors.blue[400],
          borderRadius: BorderRadius.circular(8.0),
        ),
        alignment: Alignment.center,
        child: Text(
          '${day.day}',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  },
  
  // Mantener el resto igual...
  defaultBuilder: (context, day, focusedDay) {
    final eventsForDay = _getEventsForDay(day);
    if (eventsForDay.isNotEmpty) {
      return Center(
        child: Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(bottom: 1),
          decoration: BoxDecoration(
            color: Colors.green[200], // Días con eventos
            borderRadius: BorderRadius.circular(8.0),
          ),
          alignment: Alignment.center,
          child: Text(
            '${day.day}',
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return null;
  },

                      markerBuilder: (context, date, events) {
                        final eventsForDay = _getEventsForDay(date);
                        if (eventsForDay.isNotEmpty) {
                          return Positioned(
                            left: 0,
                            bottom: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.deepPurple[700]!, width: 1),
                              ),
                              width: 16,
                              height: 16,
                              child: Center(
                                child: Text(
                                  eventsForDay.length.toString(),
                                  style: TextStyle(
                                    color: Colors.deepPurple[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      formatButtonTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      formatButtonDecoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      titleCentered: true,
                      titleTextStyle: const TextStyle(fontSize: 16),
                      leftChevronPadding: const EdgeInsets.all(4),
                      rightChevronPadding: const EdgeInsets.all(4),
                    ),
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Mes',
                      CalendarFormat.twoWeeks: '2 Semanas',
                      CalendarFormat.week: 'Semana',
                    },
                  ),
                ),
                ),
                if (_selectedDay != null) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0), // NUEVO: Solo padding superior mínimo
                      child: _buildEventsForSelectedDay(),
                    ),
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
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      ),
    );
  }

  // CAMBIO: CustomScrollView optimizado en lugar de ListView.builder
  return CustomScrollView(
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(), // NUEVO: Physics optimizadas
    ),
    slivers: [
      // NUEVO: SliverList optimizado
      SliverPadding(
        padding: const EdgeInsets.only(top: 1.0), //
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final event = eventsForDay[index];
              return Semantics(
                label: 'Evento ${event['title']}',
                button: true,
                child: FastEventCard( // CAMBIO: FastEventCard en lugar de EventCardWidget
                  event: event,
                  key: ValueKey(event['id']), // NUEVO: Key optimizada
                  viewModel: _homeViewModel,
                ),
              );
            },
            childCount: eventsForDay.length,
          ),
        ),
      ),
    ],
  );
}
}