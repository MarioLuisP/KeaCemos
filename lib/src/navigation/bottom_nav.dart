import 'package:flutter/material.dart';
import 'package:myapp/src/pages/pages.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  DateTime? _selectedDate;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        _selectedDate = null; // Resetear fecha al ir a HomePage
      }
    });
  }

  void _onDateSelected(DateTime? selectedDate) {
    setState(() {
      _selectedDate = selectedDate;
      _currentIndex = 0; // Vuelve a HomePage
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(
        key: ValueKey(_selectedDate?.toIso8601String() ?? 'no-date'),
        selectedDate: _selectedDate,
      ),
      const ExplorePage(),
      CalendarPage(onDateSelected: _onDateSelected),
      const Center(child: Text('Favoritos en construcción')),
      const SettingsPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped, // Corregido de _onTap
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).primaryColor, // Corregido de selectedColor
        unselectedItemColor: Colors.grey, // Corregido de unselectedColor
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Explorar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Calendario',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}