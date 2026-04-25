import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final double temp;
  final String condition;
  WeatherData({required this.temp, required this.condition});
}

class ExternalDataService {
  static Future<WeatherData?> getLiveWeather(String destination) async {
    try {
      // 1. Geocoding
      final geoUrl = Uri.parse('https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(destination)}&format=json&limit=1');
      final geoRes = await http.get(geoUrl, headers: {'User-Agent': 'BillShareApp'});
      if (geoRes.statusCode != 200) return null;
      
      final List geoData = jsonDecode(geoRes.body);
      if (geoData.isEmpty) return null;
      
      final lat = geoData[0]['lat'];
      final lon = geoData[0]['lon'];

      // 2. Weather
      final weatherUrl = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weather_code');
      final weatherRes = await http.get(weatherUrl);
      if (weatherRes.statusCode != 200) return null;

      final data = jsonDecode(weatherRes.body);
      final temp = data['current']['temperature_2m'];
      final code = data['current']['weather_code'];
      
      return WeatherData(temp: temp.toDouble(), condition: _getWeatherDesc(code));
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getExchangeRate(String destination) async {
    try {
      String targetCurrency = "USD";
      String symbol = "USD";
      if (destination.toLowerCase().contains("nhật")) { targetCurrency = "JPY"; symbol = "JPY"; }
      else if (destination.toLowerCase().contains("thái")) { targetCurrency = "THB"; symbol = "THB"; }
      else if (destination.toLowerCase().contains("hàn")) { targetCurrency = "KRW"; symbol = "KRW"; }
      else if (destination.toLowerCase().contains("châu âu") || destination.toLowerCase().contains("đức") || destination.toLowerCase().contains("pháp")) { targetCurrency = "EUR"; symbol = "EUR"; }
      else if (destination.toLowerCase().contains("singapore")) { targetCurrency = "SGD"; symbol = "SGD"; }
      else if (destination.toLowerCase().contains("anh")) { targetCurrency = "GBP"; symbol = "GBP"; }

      // 1. Get USD/TargetRate
      final url = Uri.parse('https://api.frankfurter.app/latest?from=USD&to=$targetCurrency');
      final res = await http.get(url);
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body);
      final double usdToTarget = data['rates'][targetCurrency]?.toDouble() ?? 1.0;

      // 2. We assume 1 USD = 25450 VND (or we could fetch it if API allowed, but Frankfurter doesn't have VND)
      // To make it safer, we try to get a reference rate or use a stable mock for VND
      const double usdToVnd = 25450.0;
      
      final double targetToVnd = usdToVnd / usdToTarget;
      
      return {
        'rate': targetToVnd,
        'symbol': symbol,
      };
    } catch (e) {
      return null;
    }
  }

  static String _getWeatherDesc(int code) {
    if (code == 0) return "Trời quang";
    if (code <= 3) return "Nhiều mây";
    if (code <= 48) return "Sương mù";
    if (code <= 67) return "Mưa nhỏ";
    if (code <= 82) return "Mưa rào";
    if (code <= 99) return "Có dông";
    return "Bình thường";
  }
}
