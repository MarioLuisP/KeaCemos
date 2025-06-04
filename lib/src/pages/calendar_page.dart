import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

// Assume this mock data is accessible here, perhaps imported or defined globally
// for demonstration purposes. In a real app, you might pass it or fetch it.
final List<Map<String, String>> events = [
  {'title': 'Concierto de Jazz', 'date': '2023-10-27', 'location': 'Teatro A'},
  {'title': 'Exposición de Arte Moderno', 'date': '2023-11-05', 'location': 'Museo B'},
  {'title': 'Festival de Cine Independiente', 'date': '2023-11-18', 'location': 'Cine C'},
  {'title': 'Obra de Teatro', 'date': '2023-10-27', 'location': 'Teatro D'},
];

// Define the category colors (assuming consistent with HomePage)
Color getCategoryColor(String title) {
  if (title.contains('Teatro')) {
    return const Color(0xFFD0F0C0); // Verde pastel
  } else if (title.contains('Stand-up')) {
    return const Color(0xFFFFF9C4); // Amarillo pastel
  } else if (title.contains('Jazz')) {
    return const Color(0xFFCCE5FF); // Celeste pastel
  } else {
    return const Color(0xFFE0E0E0); // Gris claro por defecto
  }
}


class CalendarPage extends StatefulWidget {
  const CalendarPage({Key? key}) : super(key: key);

  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, String>> _selectedEvents = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _selectedEvents = _getEventsForDay(_selectedDay!);
  }

  List<Map<String, String>> _getEventsForDay(DateTime day) {
    // Filter events based on the selected day's date string
    return events.where((event) {
      final eventDate = DateFormat('yyyy-MM-dd').parse(event['date']!).toLocal();
      return isSameDay(eventDate, day);
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _selectedEvents = _getEventsForDay(selectedDay);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedDay == null
            ? 'Selecciona una fecha'
            : 'Eventos para ${DateFormat('EEEE, MMM d', 'es').format(_selectedDay!)}'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
            
          TableCalendar(
            locale: 'es_ES', // Set locale for Spanish weekdays
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: _onDaySelected,
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
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
              markerDecoration: BoxDecoration(
                color: Colors.deepPurpleAccent, // Subtle marker color
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false, // Hide format button
              titleCentered: true,
            ),
            // You can add dots for days with events
            eventLoader: _getEventsForDay, // You can add dots for days with events
          ),
          const SizedBox(height: 8.0),
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(child: Text('No events for this date yet'))
                : ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                       return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                        color: getCategoryColor(event['title']!), // Apply color based on category
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
                              Text('Fecha: ${event['date']}'),
                              const SizedBox(height: 4),
                              Text('Ubicación: ${event['location']}'),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  icon: const Icon(Icons.favorite_border),
                                  onPressed: () {
                                    // Non-functional favorite button
                                  },
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