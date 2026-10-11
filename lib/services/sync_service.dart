import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/database_helper.dart';

class SyncService {
  static Future<void> initialize() async {
    // Replace with real credentials in production
    await Supabase.initialize(
      url: 'https://xyzcompany.supabase.co',
      publishableKey: 'public-anon-key',
    );
  }

  static Future<void> syncScoreBackground() async {
    // In a real app, use connectivity_plus to check for Wi-Fi.
    // For simplicity, we proceed directly.
    bool hasWifi = true; // Simulating active Wi-Fi connection check
    
    if (hasWifi) {
      final userProfile = await DatabaseHelper.instance.getUserProfile();
      if (userProfile != null) {
        final streak = userProfile['streak'];
        
        try {
          await Supabase.instance.client
              .from('leaderboards')
              .upsert({
                'device_id': 'local_user', // Use a UUID in production
                'streak': streak,
                'last_sync': DateTime.now().toIso8601String(),
              });
        } catch (e) {
          // Sync failed silently, will retry later
        }
      }
    }
  }
}
