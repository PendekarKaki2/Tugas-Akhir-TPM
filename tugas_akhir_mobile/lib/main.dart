import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/services/database_service.dart';
import 'core/services/location_service.dart';
import 'core/services/biometric_service.dart';
import 'data/repositories/user_repository.dart';
import 'data/repositories/question_repository.dart';
import 'data/repositories/score_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/converter_repository.dart';
import 'data/sources/local/user_local_data_source.dart';
import 'data/sources/local/question_local_data_source.dart';
import 'data/sources/local/score_local_data_source.dart';
import 'data/sources/remote/chat_remote_data_source.dart';
import 'data/sources/remote/converter_remote_data_source.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/question_provider.dart';
import 'presentation/providers/score_provider.dart';
import 'presentation/providers/chat_provider.dart';
import 'presentation/providers/converter_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/providers/location_provider.dart';
import 'presentation/screens/splash/splash_screen.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/register_screen.dart';
import 'presentation/screens/game/quiz/quiz_screen.dart';
import 'presentation/screens/game/tebak_gambar/tebak_gambar_screen.dart';
import 'presentation/screens/chatbot/chatbot_screen.dart';
import 'presentation/screens/converter/converter_screen.dart';
import 'presentation/screens/profile/profile_screen.dart';
import 'presentation/screens/leaderboard/leaderboard_screen.dart';
import 'presentation/screens/feedback/feedback_screen.dart';
import 'presentation/navigation/navigation.dart';
import 'presentation/navigation/app_shell.dart';
import 'notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize Dio
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    // Initialize Database Service
    final databaseService = DatabaseService();

    // Initialize Data Sources
    final userLocalDataSource = UserLocalDataSource(databaseService);
    final questionLocalDataSource = QuestionLocalDataSource(databaseService);
    final scoreLocalDataSource = ScoreLocalDataSource(databaseService);
    final chatRemoteDataSource = ChatRemoteDataSource(dio);
    final converterRemoteDataSource = ConverterRemoteDataSource(dio);

    // Initialize Repositories
    final userRepository = UserRepository(userLocalDataSource);
    final questionRepository = QuestionRepository(questionLocalDataSource);
    final scoreRepository = ScoreRepository(scoreLocalDataSource);
    final chatRepository = ChatRepository(chatRemoteDataSource);
    final converterRepository = ConverterRepository(converterRemoteDataSource);
    final locationService = LocationService();
    final biometricService = BiometricService();
    final notificationService = NotificationService();
    notificationService.initialize();

    return MultiProvider(
      providers: [
        // Providers
        ChangeNotifierProvider(
          create: (_) => AuthProvider(userRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => QuestionProvider(questionRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ScoreProvider(scoreRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ChatProvider(chatRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ConverterProvider(converterRepository),
        ),
        ChangeNotifierProvider(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => LocationProvider(locationService),
        ),
        Provider<BiometricService>.value(value: biometricService),
        Provider<NotificationService>.value(value: notificationService),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'EduFun',
            locale: const Locale('id', 'ID'),
            supportedLocales: const [
              Locale('id', 'ID'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            debugShowCheckedModeBanner: false,
            initialRoute: AppNavigation.splash,
            routes: {
              AppNavigation.splash: (context) => const SplashScreen(),
              AppNavigation.login: (context) => const LoginScreen(),
              AppNavigation.register: (context) => const RegisterScreen(),
              AppNavigation.home: (context) => const AppShell(),
              AppNavigation.quiz: (context) => const QuizScreen(),
              AppNavigation.tebakGambar: (context) =>
                  const TebakGambarScreen(),
              AppNavigation.chatbot: (context) => const ChatbotScreen(),
              AppNavigation.converter: (context) => const ConverterScreen(),
              AppNavigation.profile: (context) => const ProfileScreen(),
              AppNavigation.leaderboard: (context) =>
                  const LeaderboardScreen(),
              AppNavigation.feedback: (context) => const FeedbackScreen(),
            },
          );
        },
      ),
    );
  }
}
