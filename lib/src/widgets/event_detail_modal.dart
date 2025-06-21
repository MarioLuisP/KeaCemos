/// Modal expandible para mostrar detalle del evento.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/utils/dimens.dart';
import 'package:url_launcher/url_launcher.dart';

class EventDetailModal {
  static void show(BuildContext context, Map<String, String> event, HomeViewModel viewModel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: EventDetailContent(
            event: event,
            viewModel: viewModel,
            scrollController: scrollController,
          ),
        ),
      ),
    );
  }
}

class EventDetailContent extends StatefulWidget {
  final Map<String, String> event;
  final HomeViewModel viewModel;
  final ScrollController scrollController;

  const EventDetailContent({
    super.key,
    required this.event,
    required this.viewModel,
    required this.scrollController,
  });

  @override
  State<EventDetailContent> createState() => _EventDetailContentState();
}

class _EventDetailContentState extends State<EventDetailContent> {
  bool _isDescriptionExpanded = false;

  // Datos hardcodeados - reemplazar cuando estén disponibles
  String get _imageUrl => 'https://res.cloudinary.com/dloaaxni6/image/upload/v1750432383/001_fg9ogq.jpg';
  String get _description => 'Una visita inesperada. Una amistad que lo cambia todo. Una mañana cualquiera, en la casa de Flora, aparece un visitante muy poco común: un Aguará guazú. Alto, peludo, misterioso. Nadie sabe muy bien de dónde vino ni por qué eligió ese lugar… pero desde ese momento, todo empieza a transformarse. Junto a su mamá, su abuela y su tía, Flora se embarca en una serie de grandes aventuras para entender a este nuevo amigo, cuidarlo y, quizás, ayudarlo a encontrar su camino de regreso. Con humor, ternura y poesía, esta obra invita a mirar lo desconocido con otros ojos, y a descubrir que, aunque cada uno siga su propio camino, siempre hay una manera de encontrarse bajo las mismas estrellas.';
  String get _address => 'Pasaje A. Perez 11';
  String get _websiteUrl => 'https://www.instagram.com/espacioblick/?hl=es';
  double get _lat => -31.405408632866454;
  double get _lng => -64.17766983175501;

  Color _darkenColor(Color color, [double amount = 0.2]) {
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse('geo:$_lat,$_lng?q=$_lat,$_lng(${widget.event['title']})');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUber() async {
    final uri = Uri.parse('uber://?action=setPickup&pickup=my_location&dropoff[latitude]=$_lat&dropoff[longitude]=$_lng&dropoff[nickname]=${widget.event['title']}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      // Fallback a URL web de Uber
      final webUri = Uri.parse('https://m.uber.com/ul/?action=setPickup&pickup=my_location&dropoff[latitude]=$_lat&dropoff[longitude]=$_lng');
      await launchUrl(webUri);
    }
  }

  Future<void> _shareEvent() async {
    final formattedDate = widget.viewModel.formatEventDate(widget.event['date']!, format: 'card');
    final message = 'Te comparto este evento que vi en la app QuehaCeMos Cba:\n\n'
        '📌 ${widget.event['title']}\n'
        '🗓 $formattedDate\n'
        '📍 ${widget.event['location']}\n\n'
        '¡No te lo pierdas!'
        '¡📲 Descargá la app desde playsore!';
    
    final uri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(message)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openWebsite() async {
    final uri = Uri.parse(_websiteUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventType = widget.event['type'] ?? '';
    final cardColor = widget.viewModel.getEventCardColor(eventType, context);
    final darkCardColor = _darkenColor(cardColor, 0.1);

    return Column(
      children: [
        // Handle indicator
        Container(
          margin: const EdgeInsets.only(top: 8),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        
        Expanded(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Image con botón de favorito
                Stack(
                  children: [
                    Container(
                      height: 250,
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [cardColor, darkCardColor],
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          // widget.event['imageUrl'] ?? _imageUrl, // Usar cuando esté disponible
                          _imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [cardColor, darkCardColor],
                              ),
                            ),
                            child: const Center(
                              child: Icon(Icons.event, size: 64, color: Colors.white70),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Botón de favorito
                    Positioned(
                      top: 24,
                      right: 24,
                      child: Consumer<FavoritesProvider>(
                        builder: (context, favoritesProvider, child) {
                          final isFavorite = favoritesProvider.isFavorite(widget.event['id']!);
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.favorite : Icons.favorite_border,
                                color: isFavorite ? Colors.red : Colors.white,
                                size: 28,
                              ),
                              onPressed: () => favoritesProvider.toggleFavorite(widget.event['id']!),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                // Información principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                      Text(
                        widget.event['title']!,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Categoría
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: cardColor.withOpacity(0.5)),
                        ),
                        child: Text(
                          widget.viewModel.getCategoryWithEmoji(eventType),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: darkCardColor,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Descripción
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isDescriptionExpanded 
                                ? _description
                                // ? widget.event['description'] ?? _description // Usar cuando esté disponible
                                : '${_description.substring(0, _description.length > 150 ? 150 : _description.length)}...',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.5,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => setState(() => _isDescriptionExpanded = !_isDescriptionExpanded),
                              child: Text(
                                _isDescriptionExpanded ? 'Ver menos' : 'Ver más...',
                                style: TextStyle(
                                  color: cardColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Información del evento
                      _buildInfoSection(context, cardColor),

                      const SizedBox(height: 24),

                      // Botones de acción
                      _buildActionButtons(context, cardColor),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(BuildContext context, Color cardColor) {
    final formattedDate = widget.viewModel.formatEventDate(widget.event['date']!, format: 'card');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow(context, '🗓 ', 'Fecha y Hora', formattedDate),
          const Divider(height: 24),
          _buildInfoRow(context, '📍', 'Ubicación', widget.event['location']!),
          const Divider(height: 24),
          _buildInfoRow(context, '📫', 'Dirección', _address),
          // _buildInfoRow(context, '📫', 'Dirección', widget.event['address'] ?? _address), // Usar cuando esté disponible
          const Divider(height: 24),
          _buildInfoRow(context, '🎟', 'Entrada', widget.event['price']?.isNotEmpty == true ? widget.event['price']! : 'Consultar'),
          const Divider(height: 24),
          GestureDetector(
            onTap: _openWebsite,
            child: _buildInfoRow(
              context, 
              '🌐', 
              'Más información', 
              'Ver sitio oficial',
              isLink: true,
              linkColor: cardColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String emoji, String label, String value, {bool isLink = false, Color? linkColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isLink ? linkColor : Theme.of(context).colorScheme.onSurface,
                  decoration: isLink ? TextDecoration.underline : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, Color cardColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          context,
          icon: Icons.map_outlined,
          label: 'Maps',
          onTap: _openMaps,
          color: cardColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.local_taxi_outlined,
          label: 'Uber',
          onTap: _openUber,
          color: cardColor,
        ),
        _buildActionButton(
          context,
          icon: Icons.share_outlined,
          label: 'Compartir',
          onTap: _shareEvent,
          color: cardColor,
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}