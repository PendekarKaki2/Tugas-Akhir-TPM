import 'package:flutter/material.dart';
import '../../../core/services/data_persistence_service.dart';
import '../../../core/services/database_service.dart';
import '../../../data/models/user_model.dart';

/// Debug Screen untuk testing data persistence
/// Gunakan ini untuk verify bahwa data user tersimpan dengan baik
class DataPersistenceDebugScreen extends StatefulWidget {
  const DataPersistenceDebugScreen({super.key});

  @override
  State<DataPersistenceDebugScreen> createState() =>
      _DataPersistenceDebugScreenState();
}

class _DataPersistenceDebugScreenState
    extends State<DataPersistenceDebugScreen> {
  late DataPersistenceService _persistenceService;
  Map<String, dynamic> _consistencyData = {};
  Map<String, int> _dbStats = {};
  List<UserModel> _allUsers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _persistenceService = DataPersistenceService(DatabaseService());
    _persistenceService.setLoggingEnabled(true);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load consistency data
      _consistencyData =
          await _persistenceService.verifyDataConsistency();

      // Load DB stats
      _dbStats = await _persistenceService.getDatabaseStats();

      // Load all users
      _allUsers = await _persistenceService.getAllUsers();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _clearAllData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'Ini akan menghapus SEMUA data user. Hanya untuk testing!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(context);
              final result =
                  await _persistenceService.clearAllData();
              if (!mounted) {
                return;
              }
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    result
                        ? 'All data cleared successfully'
                        : 'Failed to clear data',
                  ),
                ),
              );
              _loadData();
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Persistence Debug'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Consistency Status
                    _buildConsistencyCard(),
                    const SizedBox(height: 16),

                    // Database Statistics
                    _buildStatsCard(),
                    const SizedBox(height: 16),

                    // All Users List
                    _buildUsersCard(),
                    const SizedBox(height: 16),

                    // Action Buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildConsistencyCard() {
    final status = _consistencyData['status'] ?? 'unknown';
    final isSuccess = status == 'success';

    return Card(
      color: isSuccess ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSuccess ? Icons.check_circle : Icons.error_outline,
                  color: isSuccess ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'Data Consistency Status',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              'Status',
              status.toUpperCase(),
              isSuccess ? Colors.green : Colors.red,
            ),
            if (!isSuccess)
              _buildInfoRow(
                'Error',
                _consistencyData['error']?.toString() ?? 'Unknown',
                Colors.red,
              ),
            if (isSuccess) ...[
              _buildInfoRow(
                'SQLite Users',
                _consistencyData['sqliteUserCount']?.toString() ?? '0',
              ),
              _buildInfoRow(
                'Cached Users',
                _consistencyData['cachedUsersExist'] == true ? 'Yes' : 'No',
              ),
              _buildInfoRow(
                'Current Session User ID',
                _consistencyData['currentSessionUserId']?.toString() ?? 'None',
              ),
              _buildInfoRow(
                'Current Session Username',
                _consistencyData['currentSessionUsername'] ?? 'None',
              ),
              _buildInfoRow(
                'Logged In',
                _consistencyData['isLoggedIn'] == true ? 'Yes' : 'No',
                _consistencyData['isLoggedIn'] == true
                    ? Colors.green
                    : Colors.orange,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Database Statistics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Users',
                  _dbStats['users']?.toString() ?? '0',
                  Icons.person,
                ),
                _buildStatItem(
                  'Scores',
                  _dbStats['scores']?.toString() ?? '0',
                  Icons.score,
                ),
                _buildStatItem(
                  'Questions',
                  _dbStats['questions']?.toString() ?? '0',
                  Icons.quiz,
                ),
                _buildStatItem(
                  'Badges',
                  _dbStats['badges']?.toString() ?? '0',
                  Icons.card_giftcard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'All Users (${_allUsers.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            if (_allUsers.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No users found'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _allUsers.length,
                itemBuilder: (context, index) {
                  final user = _allUsers[index];
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.blue[300],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  '${user.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.username,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Level ${user.level} • ${user.xp} XP',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Created: ${user.createdAt ?? "N/A"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh Data'),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _clearAllData,
          icon: const Icon(Icons.delete_forever),
          label: const Text('Clear All Data (Testing Only)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, [
    Color? valueColor,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String count,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.blue,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
