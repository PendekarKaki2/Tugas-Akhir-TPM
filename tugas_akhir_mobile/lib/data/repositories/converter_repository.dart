import '../sources/remote/converter_remote_data_source.dart';

/// Converter Repository
class ConverterRepository {
  final ConverterRemoteDataSource _remoteDataSource;

  ConverterRepository(this._remoteDataSource);

  /// Convert currency
  Future<double> convertCurrency(
    String fromCurrency,
    String toCurrency,
    double amount,
  ) async {
    return await _remoteDataSource.convertCurrency(
      fromCurrency,
      toCurrency,
      amount,
    );
  }

  /// Get exchange rates
  Future<Map<String, dynamic>> getExchangeRates(String baseCurrency) async {
    return await _remoteDataSource.getExchangeRates(baseCurrency);
  }
}
