import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_constants.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  bool _initialized = false;

  factory SupabaseService() => _instance;
  SupabaseService._internal();

  Future<void> init({String? url, String? anonKey}) async {
    if (_initialized) return;

    final supaUrl = url ?? AppConstants.supabaseUrl;
    final supaKey = anonKey ?? AppConstants.supabaseAnonKey;

    if (supaUrl.isEmpty || supaKey.isEmpty || supaUrl.contains('YOUR_') || supaKey.contains('YOUR_')) {
      debugPrint('[SupabaseService] Supabase not configured (placeholder keys). Skipping initialization.');
      return;
    }

    try {
      await Supabase.initialize(
        url: supaUrl,
        anonKey: supaKey,
        // use local storage for web by default
      );
      _initialized = true;
      debugPrint('[SupabaseService] ✓ Initialized Supabase');
    } catch (e) {
      debugPrint('[SupabaseService] ✗ Failed to initialize Supabase: $e');
    }
  }

  /// Whether Supabase has been initialized successfully.
  bool get isReady => _initialized && Supabase.instance.client != null;

  /// Access Supabase client (may throw if not initialized)
  SupabaseClient get client => Supabase.instance.client;
}
