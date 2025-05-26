import 'package:flutter/material.dart';
import 'package:shared_preferences.dart';
import '../services/ios_ad_service.dart';

class IOSHomeScreen extends StatefulWidget {
  const IOSHomeScreen({super.key});

  @override
  State<IOSHomeScreen> createState() => _IOSHomeScreenState();
}

class _IOSHomeScreenState extends State<IOSHomeScreen> {
  final IOSAdService _adService = IOSAdService();
  int _totalAdsPlayed = 0;
  int _remainingGameIds = 0;
  String _deviceInfo = '';
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _initializeAds();
    _loadStats();
  }

  Future<void> _initializeAds() async {
    await _adService.initialize();
    setState(() {
      _isConnected = true;
    });
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _totalAdsPlayed = prefs.getInt('total_ads_played') ?? 0;
      _remainingGameIds = prefs.getInt('remaining_game_ids') ?? 58;
      _deviceInfo = 'iOS Device';
    });
  }

  Future<void> _showRewardedAd() async {
    if (await _adService.showRewardedAd()) {
      setState(() {
        _totalAdsPlayed++;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_ads_played', _totalAdsPlayed);
    }
  }

  Future<void> _showInterstitialAd() async {
    if (await _adService.showInterstitialAd()) {
      setState(() {
        _totalAdsPlayed++;
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('total_ads_played', _totalAdsPlayed);
    }
  }

  Future<void> _resetGameIds() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _remainingGameIds = 58;
    });
    await prefs.setInt('remaining_game_ids', _remainingGameIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap To Paid'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Virtual Device Info',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Device: $_deviceInfo'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status:'),
                        Text(
                          _isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            color: _isConnected ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Game ID Stats',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text('Total IDs: 58'),
                    Text('Used IDs: ${58 - _remainingGameIds}'),
                    Text('Remaining IDs: $_remainingGameIds'),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _resetGameIds,
                      child: const Text('Reset Game IDs'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Ads Played: $_totalAdsPlayed',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Ads played in 2-hour intervals:',
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _showRewardedAd,
              child: const Text('Tap to Load Rewarded Ad'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showInterstitialAd,
              child: const Text('Tap to Load Interstitial Ad'),
            ),
          ],
        ),
      ),
    );
  }
}
