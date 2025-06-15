import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:quehacemos_cba/src/widgets/cards/event_card_widget.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🏗️ FavoritesPage: build() iniciado');
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Favoritos'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: Builder(
        builder: (context) {
          print('🏗️ FavoritesPage: Builder iniciado');
          
          // Verificar si los providers están disponibles
          try {
            final favoritesProvider = Provider.of<FavoritesProvider>(context, listen: false);
            final homeViewModel = Provider.of<HomeViewModel>(context, listen: false);
            
            print('✅ Providers encontrados:');
            print('   - FavoritesProvider: ${favoritesProvider != null}');
            print('   - HomeViewModel: ${homeViewModel != null}');
            print('   - Favoritos actuales: ${favoritesProvider.favoriteIds}');
            print('   - Total eventos: ${homeViewModel.filteredEvents.length}');
            
          } catch (e) {
            print('❌ Error accediendo a providers: $e');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text('Error: No se pueden acceder a los providers'),
                  Text('$e', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            );
          }
          
          return Consumer2<FavoritesProvider, HomeViewModel>(
            builder: (context, favoritesProvider, homeViewModel, child) {
              print('🔄 Consumer2: builder ejecutado');
              print('🔍 DEBUG Favoritos DETALLADO:');
              print('   - FavoritesProvider null? ${favoritesProvider == null}');
              print('   - HomeViewModel null? ${homeViewModel == null}');
              print('   - Total eventos en homeViewModel: ${homeViewModel.filteredEvents.length}');
              print('   - IDs favoritos: ${favoritesProvider.favoriteIds}');
              print('   - Favoritos count: ${favoritesProvider.favoriteIds.length}');
              
              // Debug detallado de eventos
              if (homeViewModel.filteredEvents.isNotEmpty) {
                print('📋 Primeros 5 eventos:');
                homeViewModel.filteredEvents.take(5).forEach((event) {
                  final eventId = event['id'];
                  final isFav = favoritesProvider.isFavorite(eventId ?? '');
                  print('   - ID: "$eventId" | Favorito: $isFav | Título: "${event['title']}"');
                });
              } else {
                print('⚠️ No hay eventos en homeViewModel.filteredEvents');
              }
              
              final favoriteEvents = homeViewModel.filteredEvents
                  .where((event) {
                    final eventId = event['id'];
                    final isFav = favoritesProvider.isFavorite(eventId ?? '');
                    if (isFav) {
                      print('✅ Evento favorito encontrado: $eventId');
                    }
                    return isFav;
                  })
                  .toList();

              print('🎯 Eventos favoritos filtrados: ${favoriteEvents.length}');
              
              if (favoriteEvents.isEmpty) {
                print('💔 Mostrando mensaje "sin favoritos"');
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: AppDimens.paddingMedium),
                      Text(
                        'Agrega eventos a favoritos desde la página principal',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[500],
                            ),
                        textAlign: TextAlign.center,
                      ),
                      // Debug info visible en UI
                      const SizedBox(height: 20),
                      Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            Text('DEBUG INFO:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('IDs Favoritos: ${favoritesProvider.favoriteIds}'),
                            Text('Total Eventos: ${homeViewModel.filteredEvents.length}'),
                            Text('Eventos Favoritos: ${favoriteEvents.length}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              print('📋 Mostrando lista de ${favoriteEvents.length} favoritos');
              return ListView.builder(
                padding: const EdgeInsets.only(top: AppDimens.paddingMedium),
                itemCount: favoriteEvents.length,
                itemBuilder: (context, index) {
                  print('🔧 Construyendo EventCard para índice $index');
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