import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/question_provider.dart';
import '../../providers/location_provider.dart';
import '../../widgets/custom_widgets.dart';
import '../../navigation/navigation.dart';
import '../../../notifications/notification_service.dart';

/// Home Screen
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<QuestionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('EduFun'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppNavigation.profile);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Card
              CustomCard(
                backgroundColor: const Color(0xFF1D4ED8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, ${authProvider.currentUser?.username}! 👋',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Level ${authProvider.currentUser?.level ?? 1} • ${authProvider.currentUser?.xp ?? 0} XP',
                      style: TextStyle(
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        minHeight: 8,
                        value: 0.32,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '68 XP lagi untuk naik level',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'Quick Category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _CategoryBadge(label: 'Math', icon: Icons.calculate),
                  _CategoryBadge(label: 'Science', icon: Icons.science),
                  _CategoryBadge(label: 'General', icon: Icons.public),
                ],
              ),
              const SizedBox(height: 24),

              // Features Grid
              const Text(
                'Choose Your Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              GridView(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // Quiz
                  _FeatureCard(
                    icon: Icons.quiz,
                    title: 'Quiz',
                    color: Colors.blue,
                    onTap: () =>
                        Navigator.pushNamed(context, AppNavigation.quiz),
                  ),
                  // Image Guessing
                  _FeatureCard(
                    icon: Icons.image,
                    title: 'Guess Image',
                    color: Colors.green,
                    onTap: () => Navigator.pushNamed(
                        context, AppNavigation.tebakGambar),
                  ),
                  // Chatbot
                  _FeatureCard(
                    icon: Icons.chat,
                    title: 'AI Chat',
                    color: Colors.purple,
                    onTap: () =>
                        Navigator.pushNamed(context, AppNavigation.chatbot),
                  ),
                  // Converter
                  _FeatureCard(
                    icon: Icons.currency_exchange,
                    title: 'Converter',
                    color: Colors.orange,
                    onTap: () =>
                        Navigator.pushNamed(context, AppNavigation.converter),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Consumer<LocationProvider>(
                builder: (context, locationProvider, _) {
                  return CustomCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'GPS & Reminder',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(locationProvider.locationLabel),
                        if (locationProvider.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              locationProvider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: locationProvider.isLoading
                                  ? null
                                  : () => locationProvider.fetchLocation(),
                              icon: const Icon(Icons.my_location),
                              label: const Text('Ambil Lokasi'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                await context
                                    .read<NotificationService>()
                                    .showDailyReminderNow();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Reminder berhasil dikirim'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.notifications_active),
                              label: const Text('Tes Reminder'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Leaderboard Preview
              const Text(
                'Top Players',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '🥇 Champion Player - 950 points\n🥈 Smart Learner - 850 points\n🥉 Quiz Master - 780 points',
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(
                          context, AppNavigation.leaderboard),
                      child: const Text('View Full Leaderboard'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      backgroundColor: color.withValues(alpha: 0.1),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final IconData icon;

  const _CategoryBadge({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      side: const BorderSide(color: Color(0xFFD1D5DB)),
      backgroundColor: const Color(0xFFF8FAFC),
    );
  }
}
