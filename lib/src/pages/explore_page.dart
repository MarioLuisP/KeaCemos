import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:myapp/src/providers/home_viewmodel.dart';
import 'package:myapp/src/providers/preferences_provider.dart';
import 'package:myapp/src/widgets/chips/event_chip_widget.dart';
import 'package:myapp/src/pages/event_detail_page.dart';
import 'package:myapp/src/utils/utils.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late HomeViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = HomeViewModel();
    _viewModel.initialize();
    _searchController.addListener(() {
      _viewModel.setSearchQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _viewModel),
      ],
      child: Consumer2<HomeViewModel, PreferencesProvider>(
        builder: (context, viewModel, prefs, _) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.applyCategoryFilters(prefs.activeFilterCategories);
          });

          return Scaffold(
            appBar: AppBar(
              title: const Text('Explorar Eventos'),
              centerTitle: true,
            ),
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '🔍 Busca eventos (ej. payasos)',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.count(
                    crossAxisCount: 4,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 4.0,
                    crossAxisSpacing: 4.0,
                    childAspectRatio: 3.5,
                    children: (prefs.selectedCategories.isEmpty
                        ? ['Música', 'Teatro', 'Cine', 'StandUp']
                        : prefs.selectedCategories)
                        .map((c) => EventChipWidget(category: c))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8.0),
                Expanded(
                  child: viewModel.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : viewModel.hasError
                          ? Center(child: Text('Error: ${viewModel.errorMessage}'))
                          : viewModel.filteredEvents.isEmpty
                              ? const Center(child: Text('No hay eventos.'))
                              : ListView.builder(
                                  itemCount: viewModel.filteredEvents.take(20).length,
                                  itemBuilder: (context, index) {
                                    final event = viewModel.filteredEvents[index];
                                    return _buildEventCard(context, event, viewModel);
                                  },
                                ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventCard(
      BuildContext context, Map<String, String> event, HomeViewModel viewModel) {
    final formattedDate = viewModel.formatEventDate(event['date']!);
    final cardColor = viewModel.getEventCardColor(event['type'] ?? '');

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
              Text(event['title']!, style: AppStyles.cardTitle),
              const SizedBox(height: 8),
              Text('Fecha: $formattedDate'),
              const SizedBox(height: 4),
              Text('Ubicación: ${event['location']}'),
            ],
          ),
        ),
      ),
    );
  }
}
