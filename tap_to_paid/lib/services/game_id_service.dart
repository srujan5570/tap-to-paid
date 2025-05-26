import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class GameIdService {
  static const String _usedIdsKey = 'used_game_ids';
  static const String _currentIdKey = 'current_game_id';
  static List<String> _allGameIds = [];
  static Set<String> _usedIds = {};
  static String? _currentId;

  static final List<String> gameIds = [
    '5859177',
    '5861329',
    '5861331',
    '5861333',
    '5861334',
    '5861336',
    '5861338',
    '5861344',
    '5861346',
    '5861348',
    '5861351',
    '5861361',
    '5861363',
    '5861366',
    '5861369',
    '5861371',
    '5861301',
    '5861373',
    '5861459',
    '5861377',
    '5861379',
    '5861381',
    '5861382',
    '5861385',
    '5861387',
    '5861388',
    '5861390',
    '5861394',
    '5861397',
    '5861438',
    '5861441',
    '5861445',
    '5861447',
    '5861449',
    '5861451',
    '5861453',
    '5861454',
    '5861456',
    '5861436',
    '5861463',
    '5861435',
    '5861433',
    '5861467',
    '5861307',
    '5861431',
    '5861429',
    '5861426',
    '5861424',
    '5861422',
    '5861420',
    '5861419',
    '5861414',
    '5861413',
    '5861411',
    '5861408',
    '5861407',
    '5861402',
    '5850242'
  ];

  static Future<void> initializeGameIds() async {
    final prefs = await SharedPreferences.getInstance();
    _allGameIds = List<String>.from(gameIds);

    // Load used IDs from storage
    final usedIdsString = prefs.getStringList(_usedIdsKey) ?? [];
    _usedIds = Set<String>.from(usedIdsString);

    // Clear current ID to force new selection
    _currentId = null;
    await prefs.remove(_currentIdKey);

    print('GameIdService: Initialized with ${_allGameIds.length} total IDs');
    print('GameIdService: ${_usedIds.length} IDs marked as used');
  }

  static Future<String> getNextGameId() async {
    if (_currentId != null) {
      return _currentId!;
    }

    final availableIds =
        _allGameIds.where((id) => !_usedIds.contains(id)).toList();
    if (availableIds.isEmpty) {
      print('GameIdService: No more unused IDs available, resetting used IDs');
      await resetGameIds();
      return getNextGameId();
    }

    final random = Random();
    _currentId = availableIds[random.nextInt(availableIds.length)];

    // Save current ID
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentIdKey, _currentId!);

    print('GameIdService: Selected new game ID: $_currentId');
    return _currentId!;
  }

  static Future<void> markCurrentIdAsUsed() async {
    if (_currentId == null) {
      print('GameIdService: No current ID to mark as used');
      return;
    }

    _usedIds.add(_currentId!);
    print('GameIdService: Marked $_currentId as used');

    // Save to storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_usedIdsKey, _usedIds.toList());

    // Clear current ID
    _currentId = null;
    await prefs.remove(_currentIdKey);
  }

  static Future<void> resetGameIds() async {
    _usedIds.clear();
    _currentId = null;

    // Clear storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_usedIdsKey);
    await prefs.remove(_currentIdKey);

    print('GameIdService: Reset all game IDs');
  }

  static Future<Map<String, dynamic>> getGameIdStats() async {
    return {
      'total_ids': _allGameIds.length,
      'used_count': _usedIds.length,
      'remaining_count': _allGameIds.length - _usedIds.length,
      'current_id': _currentId ?? 'None'
    };
  }
}
