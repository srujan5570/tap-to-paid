import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

class IpService {
  // List of Irish IP ranges (these are example ranges - you should use actual Irish IP ranges)
  static const List<String> irishIpRanges = [
    '87.198.', // Vodafone Ireland
    '89.28.', // Eir Ireland
    '92.251.', // Virgin Media Ireland
    '176.34.', // Amazon AWS Ireland
    '157.190.', // Three Ireland
  ];

  static String generateIrishIp() {
    final random = Random();
    final selectedRange = irishIpRanges[random.nextInt(irishIpRanges.length)];
    final thirdOctet = random.nextInt(256);
    final fourthOctet = random.nextInt(256);
    return '$selectedRange$thirdOctet.$fourthOctet';
  }

  static Future<Map<String, String>> getRealIpInfo() async {
    try {
      final ipResponse =
          await http.get(Uri.parse('https://api.ipify.org?format=json'));
      if (ipResponse.statusCode == 200) {
        final ipData = json.decode(ipResponse.body);
        String ip = ipData['ip'];

        final geoResponse =
            await http.get(Uri.parse('http://ip-api.com/json/$ip'));
        if (geoResponse.statusCode == 200) {
          final geoData = json.decode(geoResponse.body);
          return {
            'ip': ip,
            'country': geoData['country'] ?? 'Unknown',
            'countryCode': geoData['countryCode'] ?? 'Unknown',
          };
        }
      }
      return {
        'ip': 'Error',
        'country': 'Unknown',
        'countryCode': 'Unknown',
      };
    } catch (e) {
      return {
        'ip': 'Error',
        'country': 'Unknown',
        'countryCode': 'Unknown',
      };
    }
  }
}
