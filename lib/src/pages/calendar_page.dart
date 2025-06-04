import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:myapp/src/models/models.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime(2025, 6, 4);
  DateTime? _selectedDay;
  List<Map<String, String>> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    print('Calendario inicializado: $_focusedDay');
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    final dateString = DateFormat('yyyy-MM-dd').format(day);
    return events.where((event) => event['date'] == dateString).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    print('Día seleccionado: $selectedDay');
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEvents = _getEventsForDay(selectedDay);
    });
    Navigator.pop(context, selectedDay);
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
            Navigator.pop(context, _selectedDay);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
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
              markerDecoration: const BoxDecoration(
                color: Colors.deepPurpleAccent,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            eventLoader: _getEventsForDay,
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedEvents.isEmpty
                ? const Center(child: Text('Selecciona un día para ver eventos'))
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
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
                        default:
                          cardColor = const Color(0xFFE0E0E0);
                          print('Color por defecto para tipo: $eventType');
                          break;
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        color: cardColor,
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
                              Text('Fecha: ${DateFormat('d MMM yyyy', 'es').format(DateFormat('yyyy-MM-dd').parse(event['date']!))}'),
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
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}