import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/auth_service.dart';
import 'package:myapp/event_detail_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:myapp/calendar_page.dart';
import 'package:myapp/l10n/intl_messages_all.dart';

void main() async {
  // Sort the events by date
  events.sort((a, b) => a['date']!.compareTo(b['date']!));

  WidgetsFlutterBinding.ensureInitialized();
  await initializeMessages('es_ES');

  runApp(const MyApp());
}

final List<Map<String, String>> events = [
  {'title': 'Concierto de Jazz 🎶', 'date': '2025-06-03', 'location': 'Teatro A', 'type': 'Música'},
  {'title': 'Exposición de Arte Moderno', 'date': '2025-06-03', 'location': 'Museo B', 'type': 'Exposición'},
  {'title': 'Obra de Teatro: Hamlet 🎭', 'date': '2025-06-04', 'location': 'Teatro Real', 'type': 'Teatro'},
  {'title': 'Noche de Stand-up 😂', 'date': '2025-06-04', 'location': 'Club B', 'type': 'Stand-up'},
  {'title': 'Festival de Cine Independiente 🎬', 'date': '2025-06-04', 'location': 'Cine C', 'type': 'Cine'},
  {'title': 'Show Infantil: Cuentacuentos 👧', 'date': '2025-06-04', 'location': 'Plaza D', 'type': 'Infantil'},
];

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
        useMaterial3: true, // Habilitar Material 3 para un diseño más moderno
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    // Filtrar eventos de hoy y mañana
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final tomorrow = DateFormat('yyyy-MM-dd').format(DateTime.now().add(Duration(days: 1)));
    final todayEvents = events.where((event) => event['date'] == today).toList();
    final tomorrowEvents = events.where((event) => event['date'] == tomorrow).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '🌟 KeaCMos Córdoba',
          style: TextStyle(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        centerTitle: true, // Centrar el título
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CalendarPage()),
          );
        },
        child: const Icon(Icons.calendar_today),
      ),
      body: ListView(
        children: [
          // Sección "Hoy"
          if (todayEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Eventos Hoy',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
            ),
            Divider(
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey[400],
            ),
            ...todayEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return _buildEventCard(context, event, index);
            }).toList(),
          ],
          // Sección "Mañana"
          if (tomorrowEvents.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Mañana',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
              ),
            ),
            Divider(
              thickness: 1,
              indent: 16,
              endIndent: 16,
              color: Colors.grey[400],
            ),
            ...tomorrowEvents.asMap().entries.map((entry) {
              final index = entry.key + todayEvents.length; // Ajustar índice para gestos
              final event = entry.value;
              return _buildEventCard(context, event, index);
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, Map<String, String> event, int index) {
    // Asignar colores según el tipo de evento
    Color cardColor;
    switch (event['type']) {
      case 'Teatro':
        cardColor = Color(0xFFB2DFDB); // Verde suave
        break;
      case 'Stand-up':
        cardColor = Color(0xFFFFF9C4); // Amarillo pastel
        break;
      case 'Música':
        cardColor = Color(0xFFCCE5FF); // Celeste claro
        break;
      case 'Cine':
        cardColor = Color(0xFFE0E0E0); // Gris elegante
        break;
      case 'Infantil':
        cardColor = Color(0xFFE1BEE7); // Lila tierno
        break;
      default:
        cardColor = Color(0xFFE0E0E0); // Gris claro por defecto
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
        margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['title']!,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('Fecha: ${event['date']}'),
              SizedBox(height: 4),
              Text('Ubicación: ${event['location']}'),
              SizedBox(height: 8),
              Align(
                alignment: Alignment.bottomRight,
                child: IconButton(
                  icon: Icon(Icons.favorite_border),
                  onPressed: () {
                    if (FirebaseAuth.instance.currentUser == null) {
                      AuthService().signInWithGoogle().then((_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sesión iniciada')),
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