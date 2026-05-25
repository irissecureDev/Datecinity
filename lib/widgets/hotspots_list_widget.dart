import 'package:flutter/material.dart';
import 'package:datecinity/models/hotspot.dart';
import 'package:datecinity/services/hotspots_service.dart';

/// Widget pour afficher la liste des lieux populaires (hotspots)
class HotspotsListWidget extends StatefulWidget {
  final List<Hotspot> hotspots;
  final Function(Hotspot)? onHotspotTap;
  final Function(Hotspot)? onGetDirections;
  final VoidCallback? onRefresh;

  const HotspotsListWidget({
    super.key,
    required this.hotspots,
    this.onHotspotTap,
    this.onGetDirections,
    this.onRefresh,
  });

  @override
  _HotspotsListWidgetState createState() => _HotspotsListWidgetState();
}

class _HotspotsListWidgetState extends State<HotspotsListWidget> {
  final HotspotsService _hotspotsService = HotspotsService();

  @override
  Widget build(BuildContext context) {
    if (widget.hotspots.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.hotspots.length + 1, // +1 pour l'en-tête
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildHeader();
          }

          final hotspot = widget.hotspots[index - 1];
          return _buildHotspotCard(hotspot);
        },
      ),
    );
  }

  /// Construire l'en-tête avec statistiques
  Widget _buildHeader() {
    final stats = _hotspotsService.getHotspotsStats();
    final totalUsers = widget.hotspots.fold<int>(
      0,
      (sum, h) => sum + h.userCount,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[400]!, Colors.purple[400]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_city, color: Colors.white, size: 24),
              const SizedBox(width: 8),
              const Text(
                'Lieux Populaires',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.hotspots.length} zone${widget.hotspots.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatChip(Icons.people, '$totalUsers personnes connectées'),
              const SizedBox(width: 12),
              _buildStatChip(
                Icons.refresh,
                'Maj il y a ${_getUpdateTime(stats)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construire un chip de statistique
  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construire une carte de hotspot
  Widget _buildHotspotCard(Hotspot hotspot) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: () => widget.onHotspotTap?.call(hotspot),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec nom et badges
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotspot.placeName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (hotspot.placeType != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              hotspot.placeType!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _buildIntensityBadge(hotspot),
                  ],
                ),

                const SizedBox(height: 12),

                // Statistiques
                Row(
                  children: [
                    _buildInfoChip(
                      Icons.people,
                      hotspot.userCountDescription,
                      _getTypeColor(hotspot.type),
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      Icons.location_on,
                      hotspot.distanceDescription,
                      Colors.blue,
                    ),
                    if (hotspot.averageAge > 0) ...[
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        Icons.cake,
                        '${hotspot.averageAge.round()} ans moy.',
                        Colors.orange,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Répartition des genres (si disponible)
                if (hotspot.genderDistribution.isNotEmpty)
                  _buildGenderDistribution(hotspot),

                const SizedBox(height: 12),

                // Boutons d'action
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onHotspotTap?.call(hotspot),
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('View on map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onGetDirections?.call(hotspot),
                        icon: const Icon(Icons.directions, size: 18),
                        label: const Text('Itinéraire'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Construire le badge d'intensité
  Widget _buildIntensityBadge(Hotspot hotspot) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTypeColor(hotspot.type),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hotspot.type == HotspotType.high
                ? Icons.whatshot
                : Icons.local_fire_department,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            hotspot.type == HotspotType.high ? 'TRÈS ACTIF' : 'ACTIF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// Construire un chip d'information
  Widget _buildInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Construire la répartition des genres
  Widget _buildGenderDistribution(Hotspot hotspot) {
    final distribution = hotspot.genderDistribution;
    final total = distribution.values.fold<int>(0, (sum, count) => sum + count);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Répartition:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: distribution.entries.map((entry) {
            final percentage = (entry.value / total * 100).round();
            final color = _getGenderColor(entry.key);

            return Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${_getGenderIcon(entry.key)} $percentage%',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Construire l'état vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No popular places nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are currently no areas with\nenough connected users.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          if (widget.onRefresh != null)
            ElevatedButton.icon(
              onPressed: widget.onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  /// Obtenir la couleur selon le type de hotspot
  Color _getTypeColor(HotspotType type) {
    switch (type) {
      case HotspotType.moderate:
        return Colors.orange;
      case HotspotType.high:
        return Colors.red;
    }
  }

  /// Obtenir la couleur selon le genre
  Color _getGenderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'homme':
        return Colors.blue;
      case 'female':
      case 'femme':
        return Colors.pink;
      default:
        return Colors.purple;
    }
  }

  /// Obtenir l'icône selon le genre
  String _getGenderIcon(String gender) {
    switch (gender.toLowerCase()) {
      case 'male':
      case 'homme':
        return '♂';
      case 'female':
      case 'femme':
        return '♀';
      default:
        return '⚧';
    }
  }

  /// Obtenir le temps de mise à jour formaté
  String _getUpdateTime(Map<String, dynamic> stats) {
    final cacheAge = stats['cacheAge'] as int;
    if (cacheAge < 0) return 'jamais';

    if (cacheAge < 60) {
      return '${cacheAge}s';
    } else {
      return '${(cacheAge / 60).round()}min';
    }
  }
}
