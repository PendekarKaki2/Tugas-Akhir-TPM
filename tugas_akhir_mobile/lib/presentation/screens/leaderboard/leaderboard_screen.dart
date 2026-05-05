import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/score_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/custom_widgets.dart';

/// Leaderboard Screen
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ScoreProvider>().getTopScores(20);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        elevation: 0,
      ),
      body: Consumer2<ScoreProvider, LocationProvider>(
        builder: (context, provider, locationProvider, _) {
          if (provider.isLoading) {
            return const LoadingIndicator();
          }

          if (provider.topScores.isEmpty) {
            return const Center(
              child: Text('No scores yet'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.topScores.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.place),
                    title: const Text('Lokasi Pemain'),
                    subtitle: Text(locationProvider.locationLabel),
                    trailing: IconButton(
                      onPressed: () => locationProvider.fetchLocation(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ),
                );
              }

              final scoreIndex = index - 1;
              final score = provider.topScores[scoreIndex];
              final rank = scoreIndex + 1;
              final percentage =
                  (score.score / score.totalQuestions) * 100;
              final distanceKm = _distanceFromCurrent(locationProvider.position, rank);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Rank Badge
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

                      // Player Info
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
                              '${score.category} • ${score.score}/${score.totalQuestions} • ${distanceKm.toStringAsFixed(1)} km',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Score
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
          );
        },
      ),
    );
  }

  double _distanceFromCurrent(Position? position, int rank) {
    if (position == null) {
      return rank * 1.2;
    }

    final offset = rank * 0.001;
    return Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          position.latitude + offset,
          position.longitude + offset,
        ) /
        1000;
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
