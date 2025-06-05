import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/services/event_service.dart';

class CalendarPage extends StatefulWidget {
  final Function(DateTime?)? onDateSelected; // Callback para la fecha
  const CalendarPage({super.key, this.onDateSelected});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime(2025, 6, 4);
  DateTime? _selectedDay;
  final EventService _eventService = EventService();
  final Map<DateTime, List<Map<String, String>>> _eventCache = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _preloadEvents();
    print('Calendario inicializado: $_focusedDay');
  }

  Future<void> _preloadEvents() async {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final events = await _eventService.getAllEvents();
    for (var event in events) {
      final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!);
      if (eventDate.isAfter(firstDay.subtract(const Duration(days: 1))) &&
          eventDate.isBefore(lastDay.add(const Duration(days: 1)))) {
        final cacheKey = DateTime(eventDate.year, eventDate.month, eventDate.day);
        _eventCache[cacheKey] ??= [];
        _eventCache[cacheKey]!.add(event);
      }
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
    if (widget.onDateSelected != null) {
      widget.onDateSelected!(selectedDay); // Llama al callback
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedDay == null
            ? 'Selecciona una fecha'
            : 'Eventos para ${DateFormat('EEEE, d MMM', 'es').format(_selectedDay!)}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onDateSelected != null) {
              widget.onDateSelected!(null); // Cancela sin fecha
            }
          },
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: () {
                if (widget.onDateSelected != null) {
                  widget.onDateSelected!(null); // Cancela sin fecha
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: TableCalendar(
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
            if (events.isNotEmpty) {
              return Container(
                margin: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.deepPurpleAccent.withOpacity(0.3),
                ),
                width: 40,
                height: 40,
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
    );
  }
}