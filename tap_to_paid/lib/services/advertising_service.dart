import 'package:advertising_id/advertising_id.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:app_settings/app_settings.dart';

class AdvertisingService {
  static const String _lastResetTimeKey = 'last_ad_id_reset_time';
  static const String _adsCountKey = 'ads_since_last_reset';
  static String? _lastKnownId;

  static Future<String?> getAdvertisingId() async {
    try {
      final String? advertisingId = await AdvertisingId.id(true);
      _lastKnownId = advertisingId;
      return advertisingId;
    } catch (e) {
      print('Error getting advertising ID: $e');
      return null;
    }
  }

  static Future<bool> deleteAndCreateNewId() async {
    try {
      if (Platform.isAndroid) {
        // Store the current ID to compare later
        final currentId = _lastKnownId ?? await getAdvertisingId();

        // Open Android settings for Google services
        await AppSettings.openAppSettings(type: AppSettingsType.settings);

        // Wait for user to potentially make changes
        await Future.delayed(const Duration(seconds: 3));

        // Get new ID and compare
        final newId = await getAdvertisingId();

        if (newId != null && currentId != null && newId != currentId) {
          // ID has changed, reset counters
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_adsCountKey, 0);
          await prefs.setInt(
              _lastResetTimeKey, DateTime.now().millisecondsSinceEpoch);
          return true;
        }

        // If IDs are the same, guide user with specific instructions
        throw Exception('Please follow these steps in Settings:\n'
            '1. Go to Google > Services\n'
            '2. Find "Ads" or "Ads Personalization"\n'
            '3. Tap "Delete advertising ID"\n'
            '4. Confirm deletion\n'
            '5. Toggle "Opt out of Ads Personalization" off and on\n'
            '6. Return to app');
      }
      return false;
    } catch (e) {
      print('Error creating new advertising ID: $e');
      rethrow;
    }
  }

  static Future<bool> resetAdvertisingId() async {
    try {
      if (Platform.isAndroid) {
        await AppSettings.openAppSettings(type: AppSettingsType.settings);
      }

      // Reset the counter and update last reset time
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_adsCountKey, 0);
      await prefs.setInt(
          _lastResetTimeKey, DateTime.now().millisecondsSinceEpoch);

      return true;
    } catch (e) {
      print('Error resetting advertising ID: $e');
      return false;
    }
  }

  static Future<void> incrementAdsCount() async {
    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(_adsCountKey) ?? 0;
    currentCount++;
    await prefs.setInt(_adsCountKey, currentCount);
  }

  static Future<Map<String, dynamic>> getAdInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_adsCountKey) ?? 0;
    final lastResetTime = prefs.getInt(_lastResetTimeKey);
    final currentId = await getAdvertisingId();

    return {
      'currentId': currentId ?? 'Not available',
      'totalAdsPlayed': currentCount,
      'lastResetTime': lastResetTime != null
          ? DateTime.fromMillisecondsSinceEpoch(lastResetTime)
          : null,
    };
  }
}
