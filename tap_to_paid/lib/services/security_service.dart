import 'dart:math';
import 'dart:async';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/material.dart';

class SecurityService {
  static final Random _random = Random.secure();
  static Timer? _ipRotationTimer;
  static Timer? _locationCheckTimer;
  static bool _isInitialized = false;
  static String? _currentIp;
  static String? _currentCountry;
  static bool _isIreland = false;
  static String? _spoofedIp;

  // Irish IP ranges (major ISPs and data centers in Ireland)
  static const List<String> _irishIpRanges = [
    '159.134.', // Vodafone Ireland
    '176.34.', // AWS Dublin
    '178.167.', // Virgin Media Ireland
    '185.111.', // Irish Hosting
    '188.141.', // Three Ireland
    '213.94.', // Eir Business
    '217.78.', // BT Ireland
    '185.85.', // Dublin IX
  ];

  // Irish mobile carrier codes
  static const List<String> _irishCarriers = [
    'Vodafone IE',
    'Three Ireland',
    'Eir Mobile',
    'Tesco Mobile Ireland',
    '48 Ireland',
  ];

  static Future<Map<String, dynamic>> checkRealIp() async {
    try {
      final response = await http.get(Uri.parse('http://ip-api.com/json'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentIp = data['query'];
        _currentCountry = data['country'];
        _isIreland = data['country'] == 'Ireland';

        // Generate spoofed IP if needed
        if (_spoofedIp == null || !_isIreland) {
          _spoofedIp = generateIrishIp();
        }

        print('SecurityService: IP Check Result:');
        print('Real IP: $_currentIp');
        print('Spoofed IP: $_spoofedIp');
        print('Country: $_currentCountry');
        print('Is Ireland: $_isIreland');

        return {
          'real_ip': _currentIp,
          'spoofed_ip': _spoofedIp,
          'country': _currentCountry,
          'isIreland': _isIreland,
        };
      }
      throw Exception('Failed to get IP info');
    } catch (e) {
      print('SecurityService Error: $e');
      return {
        'real_ip': 'Error',
        'spoofed_ip': _spoofedIp ?? generateIrishIp(),
        'country': 'Unknown',
        'isIreland': false,
      };
    }
  }

  static Future<bool> initializeSecurity(BuildContext context) async {
    if (!_isIreland) {
      print('SecurityService: Access denied - Not in Ireland');
      return false;
    }
    print('SecurityService: Access granted - Ireland IP detected');
    return true;
  }

  static void startLocationCheck(BuildContext context) {
    _locationCheckTimer?.cancel();
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final ipInfo = await checkRealIp();
      if (!ipInfo['isIreland']) {
        // Force stop app if location is not Ireland
        SystemNavigator.pop();
      }
    });
  }

  static String generateIrishIp() {
    final range = _irishIpRanges[_random.nextInt(_irishIpRanges.length)];
    return '$range${_random.nextInt(256)}.${_random.nextInt(256)}';
  }

  static Map<String, String> generateDeviceInfo() {
    return {
      'carrier': _irishCarriers[_random.nextInt(_irishCarriers.length)],
      'network_type': ['4G', '5G'][_random.nextInt(2)],
      'timezone': 'Europe/Dublin',
      'locale': 'en_IE',
      'country_code': 'IE',
    };
  }

  static Future<void> _applySecurityMeasures() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (await deviceInfo.androidInfo != null) {
        await SystemChannels.platform
            .invokeMethod('SystemNavigator.routeObserved');
      }
    } catch (e) {
      print('Security measures application error: $e');
    }
  }

  static void startIpRotation() {
    _ipRotationTimer?.cancel();
    _ipRotationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _rotateIp();
    });
  }

  static Future<void> _rotateIp() async {
    try {
      _spoofedIp = generateIrishIp();
      print('SecurityService: Rotated to new spoofed IP: $_spoofedIp');

      final deviceInfo = generateDeviceInfo();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_ip', _spoofedIp!);
      await prefs.setString('carrier', deviceInfo['carrier']!);
      await prefs.setString('network_type', deviceInfo['network_type']!);
    } catch (e) {
      print('IP rotation error: $e');
    }
  }

  static Future<Map<String, dynamic>> getCurrentSecurityInfo() async {
    if (_currentIp == null || _currentCountry == null) {
      await checkRealIp();
    }
    return {
      'real_ip': _currentIp ?? 'Unknown',
      'spoofed_ip': _spoofedIp ?? generateIrishIp(),
      'country': _currentCountry ?? 'Unknown',
      'isIreland': _isIreland,
    };
  }

  static void dispose() {
    _ipRotationTimer?.cancel();
    _locationCheckTimer?.cancel();
    _isInitialized = false;
  }
}
