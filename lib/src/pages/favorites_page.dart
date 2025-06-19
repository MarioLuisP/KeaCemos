import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/services/event_service.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: EventService().getAllEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Error cargando eventos'),
                  Text('${snapshot.error}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No hay eventos disponibles'),
            );
          }

          return Consumer2<FavoritesProvider, HomeViewModel>(
            builder: (context, favoritesProvider, homeViewModel, child) {
              final allEvents = snapshot.data!;

              // Filtrar eventos favoritos de TODOS los eventos
              final favoriteEvents = allEvents.where((event) {
                final eventId = event['id']?.toString();
                if (eventId == null || eventId.isEmpty) return false;
                return favoritesProvider.isFavorite(eventId);
              }).toList();

              if (favoriteEvents.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 64,
                        color: Color(0xFFBDBDBD),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      Text(
                        'No tienes eventos favoritos',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      Text(
                        'Agrega eventos a favoritos desde la página principal',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey[500]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: AppDimens.paddingMedium),
                itemCount: favoriteEvents.length,
                itemBuilder: (context, index) {
                  return EventCardWidget(
                    event: favoriteEvents[index],
                    viewModel: homeViewModel,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
