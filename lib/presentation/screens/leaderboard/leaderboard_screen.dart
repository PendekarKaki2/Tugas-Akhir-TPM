import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';

import '../../providers/score_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_widgets.dart';
import '../../../data/models/score_model.dart';
import '../../../data/models/user_location_model.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final MapController _mapController = MapController();
  double _mapZoom = 5.5;
  LatLng _mapCenter = const LatLng(-2.5489, 118.0149);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ScoreProvider>().getTopScores(50);
      final auth = context.read<AuthProvider>();
      context.read<LocationProvider>().fetchLocation(
            userId: auth.currentUser?.id,
            userName: auth.currentUser?.username,
            points: auth.currentUser?.xp ?? 0,
          );
      context.read<LocationProvider>().loadLeaderboardSnapshots();
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leaderboard'),
          elevation: 0,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'List'),
              Tab(text: 'Map'),
            ],
          ),
        ),
        body: Consumer2<ScoreProvider, LocationProvider>(
          builder: (context, scoreProvider, locationProvider, _) {
            if (scoreProvider.isLoading) {
              return const LoadingIndicator();
            }

            final topScores = scoreProvider.topScores;
            final snapshots = locationProvider.leaderboardSnapshots;
            final joinedPins = _buildJoinedPins(topScores, snapshots);
            final citySummary = _buildCitySummary(joinedPins);

            return TabBarView(
              children: [
                _buildListTab(topScores, locationProvider),
                _buildMapTab(joinedPins, citySummary, locationProvider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListTab(List<ScoreModel> topScores, LocationProvider locationProvider) {
    if (topScores.isEmpty) {
      return const Center(child: Text('No scores yet'));
    }

    return RefreshIndicator(
      onRefresh: () async {
        await context.read<ScoreProvider>().getTopScores(50);
        await context.read<LocationProvider>().loadLeaderboardSnapshots();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topScores.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: const Icon(Icons.place),
                title: const Text('Lokasi Anda'),
                subtitle: Text(locationProvider.locationLabel),
                trailing: IconButton(
                  onPressed: () {
                    final auth = context.read<AuthProvider>();
                    locationProvider.fetchLocation(
                      userId: auth.currentUser?.id,
                      userName: auth.currentUser?.username,
                      points: auth.currentUser?.xp ?? 0,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                ),
              ),
            );
          }

          final scoreIndex = index - 1;
          final score = topScores[scoreIndex];
          final rank = scoreIndex + 1;
          final percentage = score.getPercentage();
          final cityName = _findCityNameForUser(score.userId, locationProvider.leaderboardSnapshots);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getRankColor(rank),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        rank <= 3 ? _getRankEmoji(rank) : '$rank',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Player ${score.userId}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${score.category} • ${score.score}/${score.totalQuestions}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cityName == null ? 'Lokasi belum disimpan' : 'Lokasi: $cityName',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${score.score} points',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMapTab(
    List<_LeaderboardPin> pins,
    Map<String, int> citySummary,
    LocationProvider locationProvider,
  ) {
    final markers = _buildMarkersForZoom(pins, _mapZoom);
    final center = _centerForPins(pins) ?? _mapCenter;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: _mapZoom,
            onPositionChanged: (position, hasGesture) {
              final zoom = position.zoom ?? _mapZoom;
              final centerValue = position.center ?? center;
              setState(() {
                _mapZoom = zoom;
                _mapCenter = centerValue;
              });
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'tugas_akhir_mobile',
            ),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Leaderboard Map', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('Zoom: ${_mapZoom.toStringAsFixed(1)} • semakin dekat, semakin detail pin muncul'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: citySummary.entries
                        .take(3)
                        .map(
                          (entry) => Chip(
                            label: Text('${entry.key}: ${entry.value} pts'),
                            backgroundColor: const Color(0xFFF8FAFC),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_LeaderboardPin> _buildJoinedPins(List<ScoreModel> scores, List<UserLocationModel> snapshots) {
    final latestByUser = <int, UserLocationModel>{};
    for (final snapshot in snapshots) {
      latestByUser[snapshot.userId] = snapshot;
    }

    final pins = <_LeaderboardPin>[];
    for (final score in scores) {
      final snapshot = latestByUser[score.userId];
      if (snapshot == null) continue;
      pins.add(
        _LeaderboardPin(
          userId: score.userId,
          userName: snapshot.userName,
          points: score.score,
          totalQuestions: score.totalQuestions,
          category: score.category,
          locationName: snapshot.locationName,
          position: LatLng(snapshot.latitude, snapshot.longitude),
        ),
      );
    }
    return pins;
  }

  Map<String, int> _buildCitySummary(List<_LeaderboardPin> pins) {
    final summary = <String, int>{};
    for (final pin in pins) {
      summary[pin.locationName] = (summary[pin.locationName] ?? 0) + pin.points;
    }
    final entries = summary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(entries);
  }

  String? _findCityNameForUser(int userId, List<UserLocationModel> snapshots) {
    for (final snapshot in snapshots) {
      if (snapshot.userId == userId) return snapshot.locationName;
    }
    return null;
  }

  List<Marker> _buildMarkersForZoom(List<_LeaderboardPin> pins, double zoom) {
    final grouped = <String, List<_LeaderboardPin>>{};
    final precision = zoom < 7
        ? 1
        : zoom < 10
            ? 2
            : 4;

    for (final pin in pins) {
      final key = _gridKey(pin.position, precision);
      grouped.putIfAbsent(key, () => []).add(pin);
    }

    return grouped.entries.map((entry) {
      final group = entry.value;
      final lat = group.map((e) => e.position.latitude).reduce((a, b) => a + b) / group.length;
      final lng = group.map((e) => e.position.longitude).reduce((a, b) => a + b) / group.length;
      final top = group.reduce((a, b) => a.points >= b.points ? a : b);
      final label = group.length == 1
          ? '${top.userName}\n${top.points} pts\n${top.locationName}'
          : '${group.length} pins\nTop: ${top.locationName}\n${top.points} pts';

      return Marker(
        point: LatLng(lat, lng),
        width: 130,
        height: 72,
        child: _MapMarkerCard(label: label, count: group.length),
      );
    }).toList();
  }

  String _gridKey(LatLng point, int precision) {
    final lat = point.latitude.toStringAsFixed(precision);
    final lng = point.longitude.toStringAsFixed(precision);
    return '$lat,$lng';
  }

  LatLng? _centerForPins(List<_LeaderboardPin> pins) {
    if (pins.isEmpty) return null;
    final lat = pins.map((e) => e.position.latitude).reduce((a, b) => a + b) / pins.length;
    final lng = pins.map((e) => e.position.longitude).reduce((a, b) => a + b) / pins.length;
    return LatLng(lat, lng);
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[300]!;
      case 2:
        return Colors.grey[300]!;
      case 3:
        return Colors.orange[300]!;
      default:
        return Colors.grey[200]!;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}

class _LeaderboardPin {
  final int userId;
  final String userName;
  final int points;
  final int totalQuestions;
  final String category;
  final String locationName;
  final LatLng position;

  _LeaderboardPin({
    required this.userId,
    required this.userName,
    required this.points,
    required this.totalQuestions,
    required this.category,
    required this.locationName,
    required this.position,
  });
}

class _MapMarkerCard extends StatelessWidget {
  final String label;
  final int count;

  const _MapMarkerCard({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF6366F1),
            ),
            child: Center(
              child: Text(
                '$count',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontSize: 11, height: 1.3),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
