import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'package:unity_ads_plugin/unity_ads_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'services/advertising_service.dart';
import 'services/game_id_service.dart';
import 'services/virtual_device_service.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GameIdService and get first game ID
  await GameIdService.initializeGameIds();
  final initialGameId = await GameIdService.getNextGameId();

  // Initialize Unity Ads with platform-specific Game ID
  await UnityAds.init(
    gameId: Platform.isIOS ? '5859176' : '5850242',
    testMode: false,
    onComplete: () {
      print('Unity Ads Initialization Complete');
    },
    onFailed: (error, message) {
      print('Unity Ads Initialization Failed: $error $message');
    },
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap To Paid',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const AdScreen(),
    );
  }
}

class AdScreen extends StatefulWidget {
  const AdScreen({super.key});

  @override
  State<AdScreen> createState() => _AdScreenState();
}

class _AdScreenState extends State<AdScreen> {
  int totalAdsPlayed = 0;
  Map<String, int> adsPlayedByTime = {};
  Timer? _timer;
  Timer? _adInfoTimer;
  final TextEditingController _gameIdController = TextEditingController();
  String _currentGameId = '';
  bool _isEditingGameId = false;
  final _prefs = SharedPreferences.getInstance();
  bool _isRewardedAdLoaded = false;
  bool _isInterstitialAdLoaded = false;
  bool _isBannerLoaded = false;
  Map<String, dynamic> _gameIdStats = {
    'total_ids': 0,
    'used_count': 0,
    'remaining_count': 0,
    'current_id': 'None'
  };
  bool _isRewardedAdReady = false;
  bool _isInterstitialAdReady = false;
  bool _isLoadingAd = false;
  String _currentlyLoadingAdType = '';
  Map<String, String> _virtualDeviceInfo = {};
  bool _unityInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeGameIds();
    _loadSavedData();
    _loadBannerAd();
    _loadAdInfo();
    _initializeVirtualDevice();

    _timer = Timer.periodic(const Duration(hours: 2), (timer) {
      _updateAdsPlayedRecord();
    });

    _adInfoTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadAdInfo();
    });
  }

  Future<void> _initializeGameIds() async {
    print('Initializing Game IDs...');
    await GameIdService.resetGameIds(); // Reset game IDs on app start
    await GameIdService.initializeGameIds();
    await _loadNextGameId();
    await _updateGameIdStats();
    print('Game IDs initialized. Current stats: $_gameIdStats');
  }

  Future<void> _loadNextGameId() async {
    print('Loading next game ID...');
    final nextId = await GameIdService.getNextGameId();
    print('Next game ID selected: $nextId');
    setState(() {
      _currentGameId = nextId;
      _gameIdController.text = nextId;
    });

    // Initialize Unity Ads with new game ID
    await UnityAds.init(
      gameId: nextId,
      testMode: false,
      onComplete: () {
        print('Unity Ads Initialization Complete with Game ID: $nextId');
        _loadAds();
      },
      onFailed: (error, message) {
        print('Unity Ads Initialization Failed: $error $message');
        _loadNextGameId(); // Try with next ID if current one fails
      },
    );
  }

  Future<void> _updateGameIdStats() async {
    print('Updating game ID stats...');
    final stats = await GameIdService.getGameIdStats();
    print('New stats: $stats');
    if (mounted) {
      setState(() {
        _gameIdStats = Map<String, dynamic>.from(stats);
      });
    }
  }

  Future<void> _initializeVirtualDevice() async {
    await VirtualDeviceService.loadSavedDeviceInfo();
    setState(() {
      _virtualDeviceInfo = VirtualDeviceService.getCurrentDeviceInfo();
    });
  }

  Future<void> _rotateVirtualDeviceInfo() async {
    setState(() {
      _virtualDeviceInfo = VirtualDeviceService.generateNewDeviceInfo();
      _unityInitialized = false;
    });
    await VirtualDeviceService.saveCurrentDeviceInfo();
    await _reinitializeUnityAds();
  }

  Future<void> _reinitializeUnityAds() async {
    final nextId = await GameIdService.getNextGameId();
    await UnityAds.init(
      gameId: nextId,
      testMode: false,
      onComplete: () {
        setState(() {
          _unityInitialized = true;
        });
        print('Unity Ads reinitialized with new virtual device info');
      },
      onFailed: (error, message) {
        print('Unity Ads reinitialization failed: $error $message');
        _loadNextGameId();
      },
    );
  }

  Future<void> _loadSavedData() async {
    final prefs = await _prefs;
    setState(() {
      totalAdsPlayed = prefs.getInt('total_ads_played') ?? 0;
      final adsTimeData = prefs.getString('ads_played_by_time') ?? '{}';
      adsPlayedByTime = Map<String, int>.from(
        Map<String, dynamic>.from(
          Uri.splitQueryString(adsTimeData).map(
            (key, value) => MapEntry(key, int.parse(value)),
          ),
        ),
      );
    });
  }

  Future<void> _saveData() async {
    final prefs = await _prefs;
    await prefs.setInt('total_ads_played', totalAdsPlayed);
    final adsTimeData = Uri(
        queryParameters: adsPlayedByTime
            .map((key, value) => MapEntry(key, value.toString()))).query;
    await prefs.setString('ads_played_by_time', adsTimeData);
  }

  Future<void> _resetApp() async {
    final prefs = await _prefs;
    await prefs.clear(); // Clear all stored preferences
    setState(() {
      totalAdsPlayed = 0;
      adsPlayedByTime = {};
      _currentGameId = '';
      _gameIdController.text = _currentGameId;
      _isRewardedAdReady = false;
      _isInterstitialAdReady = false;
      _isLoadingAd = false;
      _currentlyLoadingAdType = '';
    });
    _loadAdInfo();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('App has been reset!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset App'),
          content: const Text(
            'Are you sure you want to reset the app? This will clear all data and start fresh.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Reset',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                _resetApp();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _loadAds() async {
    // Load Rewarded Ad
    await UnityAds.load(
      placementId: 'Rewarded_Android',
      onComplete: (placementId) {
        print('Rewarded Ad loaded: $placementId');
        setState(() {
          _isRewardedAdLoaded = true;
        });
      },
      onFailed: (placementId, error, message) {
        print('Rewarded Ad load failed: $error $message');
        setState(() {
          _isRewardedAdLoaded = false;
        });
      },
    );

    // Load Interstitial Ad
    await UnityAds.load(
      placementId: 'Interstitial_Android',
      onComplete: (placementId) {
        print('Interstitial Ad loaded: $placementId');
        setState(() {
          _isInterstitialAdLoaded = true;
        });
      },
      onFailed: (placementId, error, message) {
        print('Interstitial Ad load failed: $error $message');
        setState(() {
          _isInterstitialAdLoaded = false;
        });
      },
    );
  }

  Future<void> _loadBannerAd() async {
    UnityAds.load(
      placementId: 'Banner_Android',
      onComplete: (placementId) {
        print('Banner loaded: $placementId');
        setState(() {
          _isBannerLoaded = true;
        });
      },
      onFailed: (placementId, error, message) {
        print('Banner load failed: $error $message');
        setState(() {
          _isBannerLoaded = false;
        });
      },
    );
  }

  Future<void> _loadAdInfo() async {
    print('Loading ad info...');
    if (mounted) {
      await _updateGameIdStats(); // Update stats when loading ad info
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _adInfoTimer?.cancel();
    _gameIdController.dispose();
    super.dispose();
  }

  void _updateAdsPlayedRecord() {
    if (mounted) {
      setState(() {
        final now = DateTime.now();
        final timeKey = '${now.hour ~/ 2 * 2}-${(now.hour ~/ 2 * 2 + 2) % 24}';
        adsPlayedByTime[timeKey] = (adsPlayedByTime[timeKey] ?? 0) + 1;
      });
      _saveData(); // Save data after updating
    }
  }

  Future<void> _loadAd(String placementId) async {
    if (_isLoadingAd) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please wait, another ad is being loaded...'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingAd = true;
      _currentlyLoadingAdType = placementId;
    });

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loading ad...'),
          duration: Duration(seconds: 2),
        ),
      );

      // Get the correct placement ID based on platform
      final String adPlacementId = Platform.isIOS
          ? (placementId == 'Rewarded_Android'
              ? 'Rewarded_iOS'
              : 'Interstitial_iOS')
          : placementId;

      await UnityAds.load(
        placementId: adPlacementId,
        onComplete: (placementId) {
          print('Ad loaded successfully: $placementId');
          setState(() {
            _isLoadingAd = false;
            _currentlyLoadingAdType = '';
            if (Platform.isIOS) {
              if (placementId == 'Rewarded_iOS') {
                _isRewardedAdReady = true;
              } else {
                _isInterstitialAdReady = true;
              }
            } else {
              if (placementId == 'Rewarded_Android') {
                _isRewardedAdReady = true;
              } else {
                _isInterstitialAdReady = true;
              }
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ad ready to play! Tap again to watch.'),
              backgroundColor: Colors.green,
            ),
          );
        },
        onFailed: (placementId, error, message) {
          print('Ad load failed: $error $message');
          setState(() {
            _isLoadingAd = false;
            _currentlyLoadingAdType = '';
            if (Platform.isIOS) {
              if (placementId == 'Rewarded_iOS') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            } else {
              if (placementId == 'Rewarded_Android') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load ad: $message'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      print('Error loading ad: $e');
      setState(() {
        _isLoadingAd = false;
        _currentlyLoadingAdType = '';
      });
    }
  }

  Future<void> _showAd(String placementId) async {
    try {
      final String adPlacementId = Platform.isIOS
          ? (placementId == 'Rewarded_Android'
              ? 'Rewarded_iOS'
              : 'Interstitial_iOS')
          : placementId;

      await UnityAds.showVideoAd(
        placementId: adPlacementId,
        onStart: (placementId) => print('Ad $placementId started'),
        onClick: (placementId) => print('Ad $placementId click'),
        onSkipped: (placementId) async {
          print('Ad $placementId skipped');
          setState(() {
            if (Platform.isIOS) {
              if (placementId == 'Rewarded_iOS') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            } else {
              if (placementId == 'Rewarded_Android') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            }
          });
          await _loadAd(placementId);
        },
        onComplete: (placementId) async {
          print('Ad $placementId completed');
          setState(() {
            totalAdsPlayed++;
            if (Platform.isIOS) {
              if (placementId == 'Rewarded_iOS') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            } else {
              if (placementId == 'Rewarded_Android') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            }
          });
          _updateAdsPlayedRecord();
          _saveData();
          await _loadAd(placementId);
        },
        onFailed: (placementId, error, message) async {
          print('Ad $placementId failed: $error $message');
          setState(() {
            if (Platform.isIOS) {
              if (placementId == 'Rewarded_iOS') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            } else {
              if (placementId == 'Rewarded_Android') {
                _isRewardedAdReady = false;
              } else {
                _isInterstitialAdReady = false;
              }
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to show ad: $message'),
              backgroundColor: Colors.red,
            ),
          );
          await _loadAd(placementId);
        },
      );
    } catch (e) {
      print('Error showing ad: $e');
      setState(() {
        if (Platform.isIOS) {
          if (placementId == 'Rewarded_iOS') {
            _isRewardedAdReady = false;
          } else {
            _isInterstitialAdReady = false;
          }
        } else {
          if (placementId == 'Rewarded_Android') {
            _isRewardedAdReady = false;
          } else {
            _isInterstitialAdReady = false;
          }
        }
      });
      await _loadAd(placementId);
    }
  }

  Future<void> _onAdButtonTap(String placementId) async {
    final bool isReady = placementId == 'Rewarded_Android'
        ? _isRewardedAdReady
        : _isInterstitialAdReady;

    if (isReady) {
      await _showAd(placementId);
    } else {
      await _loadAd(placementId);
    }
  }

  Widget _buildAdButton({
    required String text,
    required String adType,
    required Color activeColor,
  }) {
    final bool isReady = adType == 'Rewarded_Android'
        ? _isRewardedAdReady
        : _isInterstitialAdReady;
    final bool isLoading = _isLoadingAd && _currentlyLoadingAdType == adType;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : () => _onAdButtonTap(adType),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: isLoading
              ? Colors.grey
              : (isReady ? activeColor : Colors.grey[400]),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            if (isLoading) const SizedBox(width: 10),
            Text(
              isLoading
                  ? 'Loading...'
                  : (isReady ? 'Tap to Play $text' : 'Tap to Load $text'),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameIdStatsBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Game ID Stats',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text('Current ID: ${_gameIdStats['current_id'] ?? 'None'}'),
              Text('Total IDs: ${_gameIdStats['total_ids'] ?? 0}'),
              Text('Used IDs: ${_gameIdStats['used_count'] ?? 0}'),
              Text('Remaining IDs: ${_gameIdStats['remaining_count'] ?? 0}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      print('Resetting game IDs...');
                      await GameIdService.resetGameIds();
                      await _loadNextGameId();
                      await _updateGameIdStats();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text('Reset Game IDs'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVirtualDeviceInfoBox() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Virtual Device Info',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _unityInitialized ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _unityInitialized ? 'Connected' : 'Disconnected',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  'Device: ${_virtualDeviceInfo['device_name'] ?? 'Loading...'}'),
              Text('IMEI: ${_virtualDeviceInfo['imei'] ?? 'Loading...'}'),
              Text('MAC: ${_virtualDeviceInfo['mac_address'] ?? 'Loading...'}'),
              Text(
                  'Bluetooth: ${_virtualDeviceInfo['bluetooth_address'] ?? 'Loading...'}'),
              Text(
                  'Android ID: ${_virtualDeviceInfo['android_id'] ?? 'Loading...'}'),
              Text(
                  'Build: ${_virtualDeviceInfo['build_number'] ?? 'Loading...'}'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Auto-rotates after each ad',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onAdComplete() async {
    print('Ad completed, rotating virtual device info and game ID...');
    await _rotateVirtualDeviceInfo();
    GameIdService
        .markCurrentIdAsUsed(); // Only mark as used after successful completion
    await _loadNextGameId();
    await _updateGameIdStats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap To Paid'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showResetConfirmation,
            tooltip: 'Reset App',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 80),
          child: Column(
            children: [
              _buildVirtualDeviceInfoBox(),
              const SizedBox(height: 16),
              _buildGameIdStatsBox(),
              const SizedBox(height: 16),
              Text(
                'Total Ads Played: $totalAdsPlayed',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ads played in 2-hour intervals:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...adsPlayedByTime.entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '${entry.key}hrs: ${entry.value} ads',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _buildAdButton(
                      text: 'Rewarded Ad',
                      adType: 'Rewarded_Android',
                      activeColor: Colors.green,
                    ),
                    const SizedBox(height: 12),
                    _buildAdButton(
                      text: 'Interstitial Ad',
                      adType: 'Interstitial_Android',
                      activeColor: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomSheet: _isBannerLoaded
          ? Container(
              height: 50,
              color: Colors.black12,
              child: UnityBannerAd(
                size: BannerSize.standard,
                placementId: 'Banner_Android',
                onLoad: (placementId) => print('Banner loaded: $placementId'),
                onClick: (placementId) => print('Banner clicked: $placementId'),
                onFailed: (placementId, error, message) =>
                    print('Banner Ad $placementId failed: $error $message'),
              ),
            )
          : null,
    );
  }
}
