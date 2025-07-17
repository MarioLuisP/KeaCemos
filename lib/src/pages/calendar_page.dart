import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/widgets/cards/fast_event_card.dart';
import 'package:quehacemos_cba/src/services/event_service.dart';
import 'package:quehacemos_cba/src/data/repositories/event_repository.dart';

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
  late EventRepository _eventRepository;  
  final Map<DateTime, int> _eventCountsCache = {};
  final GlobalKey _calendarKey = GlobalKey();
  double _calendarHeight = 0.0; // Altura por defecto

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _homeViewModel = HomeViewModel();
    _initializeViewModel();
      // ✅ CRÍTICO: Medir altura real inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateCalendarHeight();
    });
    print('Calendario inicializado: $_focusedDay');
  }

  Future<void> _initializeViewModel() async {
    await _homeViewModel.initialize();
    _eventRepository = EventRepository();

    await _preloadEventCounts();
  }

  Future<void> _preloadEventCounts() async {
    // Calcular rango: mes anterior, actual, siguiente
    final now = _focusedDay;
    final startMonth = DateTime(now.year, now.month - 1, 1);
    final endMonth = DateTime(now.year, now.month + 2, 0); // Último día del mes siguiente
    
    final startDate = DateFormat('yyyy-MM-dd').format(startMonth);
    final endDate = DateFormat('yyyy-MM-dd').format(endMonth);
    
    // Obtener counts desde DB
    final counts = await _eventRepository.getEventCountsForDateRange(startDate, endDate);
    
    // Limpiar cache y cargar nuevos counts
    _eventCountsCache.clear();
    for (final entry in counts.entries) {
      final date = DateFormat('yyyy-MM-dd').parse(entry.key);
      final cacheKey = DateTime(date.year, date.month, date.day);
      _eventCountsCache[cacheKey] = entry.value;
    }
    
    if (mounted) setState(() {});
  }

  // ✅ NUEVO: Método para obtener altura real del calendario
void _updateCalendarHeight() {
  // ✅ Delay más largo para asegurar que TableCalendar terminó de renderizar
  Future.delayed(Duration(milliseconds: 150), () {
    final RenderBox? renderBox = _calendarKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final newHeight = renderBox.size.height + 16.0;
      if ((newHeight - _calendarHeight).abs() > 1.0) {
        setState(() {
          _calendarHeight = newHeight;
        });
      }
    }
  });
}
  
  Future<List<Map<String, dynamic>>> _getEventsForDay(DateTime day) async {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    return await _eventRepository.getEventsByDate(dateString);
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
            body: Stack(
              children: [
                // ✅ CONTENIDO SCROLLEABLE (tarjetas) - va detrás
                _buildScrollableContent(),
                
                // ✅ CALENDAR FLOTANTE - va adelante
                _buildFloatingCalendar(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ✅ CORREGIDO: FutureBuilder limpio sin duplicación
Widget _buildEventsForSelectedDay() {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: _getEventsForDay(_selectedDay!),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final eventsForDay = snapshot.data ?? [];
      
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

      // ✅ SOLUCIÓN: CustomScrollView con padding inicial como SliverToBoxAdapter
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // ✅ Espacio inicial fijo que permite overscroll
          SliverToBoxAdapter(
            child: SizedBox(height: _calendarHeight + 24.0),
          ),
          
          // ✅ Lista con solo padding horizontal
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = eventsForDay[index];
                  return SizedBox(
                    height: 230.0,
                    child: FastEventCard(
                      event: event,
                      viewModel: _homeViewModel,
                      key: ValueKey(event['id']),
                    ),
                  );
                },
                childCount: eventsForDay.length,
              ),
            ),
          ),
        ],
      );       
    },
  );
}
Widget _buildScrollableContent() {
  if (_selectedDay == null) {
    return Container();
  }
  
  // ✅ CustomScrollView directo sin padding del padre
  return _buildEventsForSelectedDay();
}

Widget _buildFloatingCalendar() {
  return Positioned(
    top: 8.0,
    left: 20.0,
    right: 20.0,
    child: Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.7),
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
                  child: TableCalendar(
                    locale: 'es_ES',
                    key: _calendarKey, // ✅ AGREGAR esto
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    calendarFormat: _calendarFormat,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: _onDaySelected,
                    onFormatChanged: (format) {
                      if (_calendarFormat != format) {
                        setState(() => _calendarFormat = format);
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                        _updateCalendarHeight();
                      });
                      }
                    },
                    onPageChanged: (focusedDay) {
                      print('Mes cambiado: $focusedDay');
                      setState(() => _focusedDay = focusedDay);
                      _preloadEventCounts(); // ✅ CORREGIDO
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                        _updateCalendarHeight();
                        setState(() {}); // Fuerza rebuild completo
                      });
                    },
                    daysOfWeekHeight: 20,
                    rowHeight: 30,
                    sixWeekMonthsEnforced: false,
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

                    calendarBuilders: CalendarBuilders(
                      // ✅ CORREGIDO: Today builder con eventCount
                      todayBuilder: (context, day, focusedDay) {
                        final isSelected = isSameDay(_selectedDay, day);
                        final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                        
                        return Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(bottom: 1),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.blue[400] 
                                  : (eventCount > 0 ? Colors.orange[300] : Colors.blue[200]), // ✅ CORREGIDO
                              borderRadius: BorderRadius.circular(8.0),
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
                      
                      // ✅ CORREGIDO: Selected builder con eventCount
                      selectedBuilder: (context, day, focusedDay) {
                        if (isSameDay(day, DateTime.now())) {
                          return null; // Dejar que todayBuilder maneje
                        }
                        
                        final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                        return Center(
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(bottom: 1),
                            decoration: BoxDecoration(
                              color: eventCount > 0 ? Colors.purple[300] : Colors.blue[400], // ✅ CORREGIDO
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
                      
                      // ✅ CORREGIDO: Default builder con eventCount
                      defaultBuilder: (context, day, focusedDay) {
                        final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                        if (eventCount > 0) { // ✅ CORREGIDO
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

                      // ✅ CORREGIDO: Marker builder usando cache
                      markerBuilder: (context, date, events) {
                        final eventCount = _eventCountsCache[DateTime(date.year, date.month, date.day)] ?? 0;
                        if (eventCount > 0) { // ✅ CORREGIDO
                          return Positioned(
                            left: 0,
                            bottom: 2,
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.deepPurple[700]!, width: 1),
                              ),
                              width: 18,
                              height: 18,
                              child: Center(
                                child: Text(
                                  eventCount.toString(), // ✅ CORREGIDO
                                  //'${eventCount > 0 ? 68 : 0}', 
                                  style: TextStyle(
                                    color: Colors.deepPurple[700],
                                    fontSize: 11,
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
                  
                    eventLoader: (day) {
                      // ✅ CORREGIDO: Simple loader para TableCalendar
                      final eventCount = _eventCountsCache[DateTime(day.year, day.month, day.day)] ?? 0;
                      return List.generate(eventCount, (index) => 'evento_$index');
                    },
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
  );
}

}