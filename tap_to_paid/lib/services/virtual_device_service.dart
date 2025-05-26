import 'dart:math';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class VirtualDeviceService {
  static final Random _random = Random.secure();
  static Map<String, String> _currentDeviceInfo = {};

  static String _generateIMEI() {
    // Generate valid IMEI format
    String tac = '86${_random.nextInt(999999).toString().padLeft(6, '0')}';
    String serial = _random.nextInt(999999).toString().padLeft(6, '0');
    String cd = _calculateLuhnCheckDigit('$tac$serial');
    return '$tac$serial$cd';
  }

  static String _calculateLuhnCheckDigit(String number) {
    int sum = 0;
    bool alternate = false;
    for (int i = number.length - 1; i >= 0; i--) {
      int n = int.parse(number[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) {
          n = (n % 10) + 1;
        }
      }
      sum += n;
      alternate = !alternate;
    }
    return ((10 - (sum % 10)) % 10).toString();
  }

  static String _generateAndroidId() {
    // Generate a valid Android ID format (16 chars hex)
    final buffer = StringBuffer();
    for (int i = 0; i < 16; i++) {
      buffer.write(_random.nextInt(16).toRadixString(16));
    }
    return buffer.toString();
  }

  static String _generateMacAddress() {
    List<String> mac = [];
    for (int i = 0; i < 6; i++) {
      mac.add(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return mac.join(':');
  }

  static String _generateBluetoothAddress() {
    List<String> bt = [];
    for (int i = 0; i < 6; i++) {
      bt.add(_random.nextInt(256).toRadixString(16).padLeft(2, '0'));
    }
    return bt.join(':');
  }

  static String _generateDeviceName() {
    List<String> manufacturers = [
      'Samsung',
      'Google',
      'OnePlus',
      'Xiaomi',
      'Oppo',
      'Vivo'
    ];
    List<String> models = ['Galaxy', 'Pixel', 'Nord', 'Redmi', 'Find', 'V'];
    List<String> suffixes = ['Pro', 'Ultra', 'Max', 'Plus', 'Lite'];
    String mfg = manufacturers[_random.nextInt(manufacturers.length)];
    String model = models[_random.nextInt(models.length)];
    String suffix = _random.nextBool()
        ? '_${suffixes[_random.nextInt(suffixes.length)]}'
        : '';
    return '${mfg}_${model}${suffix}_${_random.nextInt(10)}';
  }

  static String _generatePhoneNumber() {
    // Generate Irish phone number format
    List<String> prefixes = ['+353'];
    String prefix = prefixes[_random.nextInt(prefixes.length)];
    String number = _random.nextInt(999999999).toString().padLeft(9, '0');
    return '$prefix$number';
  }

  static String _generateBuildFingerprint() {
    String brand = ['samsung', 'google', 'oneplus'][_random.nextInt(3)];
    String device = ['SM-G', 'Pixel-', 'IN'][_random.nextInt(3)] +
        _random.nextInt(999).toString();
    String version = '${_random.nextInt(5) + 10}'; // Android 10-14
    String buildId = 'QP${_random.nextInt(999)}A${_random.nextInt(999)}';
    return '$brand/$device/$device:$version/REL/$buildId/${_random.nextInt(999999)}:user/release-keys';
  }

  static Map<String, String> generateNewDeviceInfo() {
    _currentDeviceInfo = {
      'device_name': _generateDeviceName(),
      'imei': _generateIMEI(),
      'mac_address': _generateMacAddress(),
      'bluetooth_address': _generateBluetoothAddress(),
      'phone_number': _generatePhoneNumber(),
      'android_id': _generateAndroidId(),
      'build_fingerprint': _generateBuildFingerprint(),
      'build_number': 'virtual_build_${_random.nextInt(999999)}',
      'model': 'Virtual_Device_${_random.nextInt(100)}',
      'manufacturer': 'Virtual_Mfg',
      'android_version': '${_random.nextInt(5) + 10}',
      'screen_density': '${2.0 + _random.nextDouble()}',
      'screen_resolution':
          '${1080 + _random.nextInt(440)}x${1920 + _random.nextInt(580)}',
      'carrier': 'Virtual_Carrier_${_random.nextInt(5)}',
      'network_type': ['4G', '5G'][_random.nextInt(2)],
      'os_build_time':
          '${DateTime.now().millisecondsSinceEpoch - _random.nextInt(10000000)}',
      'kernel_version': '4.${_random.nextInt(20)}.${_random.nextInt(100)}',
      'bootloader_version': 'BL_${_random.nextInt(999)}',
      'radio_version': 'Radio_${_random.nextInt(999)}',
    };
    return _currentDeviceInfo;
  }

  static Future<void> clearUnityCache() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory('${appDir.path}/unity_cache');
      if (await cacheDir.exists()) {
        await cacheDir.delete(recursive: true);
      }

      // Clear shared preferences related to Unity
      final prefs = await SharedPreferences.getInstance();
      final keys =
          prefs.getKeys().where((key) => key.toLowerCase().contains('unity'));
      for (var key in keys) {
        await prefs.remove(key);
      }

      print('Unity cache cleared successfully');
    } catch (e) {
      print('Error clearing Unity cache: $e');
    }
  }

  static Map<String, String> getCurrentDeviceInfo() {
    if (_currentDeviceInfo.isEmpty) {
      return generateNewDeviceInfo();
    }
    return _currentDeviceInfo;
  }

  static Future<void> saveCurrentDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _currentDeviceInfo.forEach((key, value) {
      prefs.setString('virtual_$key', value);
    });
  }

  static Future<void> loadSavedDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentDeviceInfo.isEmpty) {
      generateNewDeviceInfo();
    }
    await saveCurrentDeviceInfo();
  }
}
