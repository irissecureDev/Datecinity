import 'package:flutter/material.dart';
import 'package:datecinity/models/nearby_place.dart';

/// Activity level for a place
enum ActivityLevel { calm, moderate, busy }

/// Widget to display the list of nearby places (bars, restaurants, etc.)
class NearbyPlacesListWidget extends StatefulWidget {
  final List<NearbyPlace> places;
  final Function(NearbyPlace)? onPlaceTap;
  final Function(NearbyPlace)? onGetDirections;
  final VoidCallback? onRefresh;

  const NearbyPlacesListWidget({
    super.key,
    required this.places,
    this.onPlaceTap,
    this.onGetDirections,
    this.onRefresh,
  });

  @override
  State<NearbyPlacesListWidget> createState() => _NearbyPlacesListWidgetState();
}

class _NearbyPlacesListWidgetState extends State<NearbyPlacesListWidget> {
  PlaceCategory? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final filteredPlaces = _selectedCategory != null
        ? widget.places
              .where((place) => place.category == _selectedCategory)
              .toList()
        : widget.places;

    if (widget.places.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: filteredPlaces.length,
        itemBuilder: (context, index) {
          final place = filteredPlaces[index];
          return _buildPlaceCard(place);
        },
      ),
    );
  }

  /// Build a place card matching the design
  Widget _buildPlaceCard(NearbyPlace place) {
    final activityLevel = _getActivityLevel(place);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => widget.onPlaceTap?.call(place),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Photo on the left
              _buildPlacePhoto(place),
              const SizedBox(width: 12),

              // Place details in the middle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Place name
                    Text(
                      place.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Rating stars and distance
                    Row(
                      children: [
                        if (place.rating != null) ...[
                          _buildRatingStars(place.rating!),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          _formatDistance(place.distanceKm),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Category / Place type
                    Text(
                      _getPlaceTypeDisplay(place),
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              // Activity level badge on the right
              _buildActivityBadge(activityLevel),
            ],
          ),
        ),
      ),
    );
  }

  /// Build place photo
  Widget _buildPlacePhoto(NearbyPlace place) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 80,
        height: 80,
        child: place.photoUrl != null
            ? Image.network(
                place.photoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderImage(place);
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return _buildPlaceholderImage(place);
                },
              )
            : _buildPlaceholderImage(place),
      ),
    );
  }

  /// Build placeholder image with category icon
  Widget _buildPlaceholderImage(NearbyPlace place) {
    return Container(
      color: _getCategoryColor(place.category).withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          _getCategoryIcon(place.category),
          size: 36,
          color: _getCategoryColor(place.category),
        ),
      ),
    );
  }

  /// Build rating stars
  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        if (rating >= starValue) {
          return const Icon(Icons.star, size: 14, color: Colors.amber);
        } else if (rating >= starValue - 0.5) {
          return const Icon(Icons.star_half, size: 14, color: Colors.amber);
        } else {
          return Icon(Icons.star_border, size: 14, color: Colors.grey[400]);
        }
      }),
    );
  }

  /// Format distance for display
  String _formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).round()} m away';
    } else {
      return '${distanceKm.toStringAsFixed(1)} mi away';
    }
  }

  /// Get place type display string
  String _getPlaceTypeDisplay(NearbyPlace place) {
    // Use vicinity if available for more descriptive info
    if (place.vicinity != null && place.vicinity!.isNotEmpty) {
      final parts = place.vicinity!.split(',');
      if (parts.isNotEmpty) {
        final categoryName = place.category.displayName;
        // Check if there's additional info in types
        final additionalType = _getAdditionalType(place);
        if (additionalType != null) {
          return '$categoryName · $additionalType';
        }
        return categoryName;
      }
    }
    return place.category.displayName;
  }

  /// Get additional type info from place types
  String? _getAdditionalType(NearbyPlace place) {
    final additionalTypes = <String>[];

    if (place.types.contains('rooftop')) additionalTypes.add('Rooftop');
    if (place.types.contains('sports_bar')) additionalTypes.add('Sports Bar');
    if (place.types.contains('beer_garden')) additionalTypes.add('Beer Garden');
    if (place.types.contains('cocktail_bar')) {
      additionalTypes.add('Cocktail Bar');
    }
    if (place.types.contains('wine_bar')) additionalTypes.add('Wine Bar');
    if (place.types.contains('lounge')) additionalTypes.add('Lounge');
    if (place.types.contains('pub')) additionalTypes.add('Pub');

    return additionalTypes.isNotEmpty ? additionalTypes.first : null;
  }

  /// Get activity level based on place properties
  ActivityLevel _getActivityLevel(NearbyPlace place) {
    // Simulate activity level based on rating and user reviews
    // In a real app, this could come from real-time data
    final rating = place.rating ?? 3.0;
    final reviews = place.userRatingsTotal ?? 0;

    // Higher rating + more reviews = more likely to be busy
    final activityScore = (rating * 0.4) + (reviews / 500 * 0.6);

    if (activityScore > 2.5) {
      return ActivityLevel.busy;
    } else if (activityScore > 1.5) {
      return ActivityLevel.moderate;
    } else {
      return ActivityLevel.calm;
    }
  }

  /// Build activity level badge
  Widget _buildActivityBadge(ActivityLevel level) {
    Color badgeColor;
    String badgeText;

    switch (level) {
      case ActivityLevel.busy:
        badgeColor = const Color(0xFFE53935); // Red
        badgeText = 'BUSY';
        break;
      case ActivityLevel.moderate:
        badgeColor = const Color(0xFFFFA726); // Orange
        badgeText = 'MODERATE';
        break;
      case ActivityLevel.calm:
        badgeColor = const Color(0xFF43A047); // Green
        badgeText = 'CALM';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        badgeText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No places nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'There are currently no places\nwithin a 4 km radius.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// Get category icon
  IconData _getCategoryIcon(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.bar:
        return Icons.local_bar;
      case PlaceCategory.restaurant:
        return Icons.restaurant;
      case PlaceCategory.nightClub:
        return Icons.nightlife;
      case PlaceCategory.cafe:
        return Icons.coffee;
      case PlaceCategory.shoppingMall:
        return Icons.shopping_bag;
      case PlaceCategory.cinema:
        return Icons.movie;
      case PlaceCategory.park:
        return Icons.park;
      case PlaceCategory.gym:
        return Icons.fitness_center;
      case PlaceCategory.spa:
        return Icons.spa;
      case PlaceCategory.other:
        return Icons.place;
    }
  }

  /// Get category color
  Color _getCategoryColor(PlaceCategory category) {
    switch (category) {
      case PlaceCategory.bar:
        return const Color(0xFFE91E63); // Pink
      case PlaceCategory.restaurant:
        return const Color(0xFFFF5722); // Deep Orange
      case PlaceCategory.nightClub:
        return const Color(0xFF9C27B0); // Purple
      case PlaceCategory.cafe:
        return const Color(0xFF795548); // Brown
      case PlaceCategory.shoppingMall:
        return const Color(0xFF2196F3); // Blue
      case PlaceCategory.cinema:
        return const Color(0xFFFF9800); // Orange
      case PlaceCategory.park:
        return const Color(0xFF4CAF50); // Green
      case PlaceCategory.gym:
        return const Color(0xFFF44336); // Red
      case PlaceCategory.spa:
        return const Color(0xFF00BCD4); // Cyan
      case PlaceCategory.other:
        return const Color(0xFF607D8B); // Blue Grey
    }
  }
}
