import 'package:dio/dio.dart';

/// Remote Data Source for Converter (Currency & Time)
class ConverterRemoteDataSource {
  final Dio _dio;
  final String baseUrl = 'https://api.exchangerate-api.com/v4/latest';

  ConverterRemoteDataSource(this._dio);

  /// Get currency exchange rates
  Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    try {
      final response = await _dio.get(
        '$baseUrl/$baseCurrency',
        options: Options(
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      if (response.statusCode == 200) {
        return {
          'rates': response.data['rates'] ?? {},
          'base': baseCurrency,
        };
      }
      return _getMockExchangeRates();
    } on DioException {
      return _getMockExchangeRates();
    }
  }

  /// Get mock exchange rates (fallback)
  Map<String, dynamic> _getMockExchangeRates() {
    return {
      'rates': {
        'IDR': 15650.0,
        'USD': 1.0,
        'EUR': 0.92,
        'GBP': 0.79,
        'JPY': 149.50,
      },
      'base': 'USD',
    };
  }

  /// Convert currency
  Future<double> convertCurrency(
    String fromCurrency,
    String toCurrency,
    double amount,
  ) async {
    final rates = await getExchangeRates(fromCurrency);
    final rateMap = rates['rates'] as Map<String, dynamic>? ?? {};

    if (rateMap.containsKey(toCurrency)) {
      return amount * (rateMap[toCurrency] as num).toDouble();
    }
    return 0;
  }
}
