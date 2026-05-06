import 'package:flutter/material.dart';
import '../../data/repositories/converter_repository.dart';

/// Converter Provider for Currency & Time
class ConverterProvider extends ChangeNotifier {
  final ConverterRepository _converterRepository;

  Map<String, dynamic> _exchangeRates = {};
  double _convertedAmount = 0;
  bool _isLoading = false;
  String? _error;

  ConverterProvider(this._converterRepository);

  Map<String, dynamic> get exchangeRates => _exchangeRates;
  double get convertedAmount => _convertedAmount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Convert currency
  Future<void> convertCurrency(
    String fromCurrency,
    String toCurrency,
    double amount,
  ) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _convertedAmount = await _converterRepository.convertCurrency(
        fromCurrency,
        toCurrency,
        amount,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get exchange rates
  Future<void> getExchangeRates(String baseCurrency) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exchangeRates = await _converterRepository.getExchangeRates(baseCurrency);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convert time (mock implementation)
  Map<String, String> convertTime(String hour) {
    final int h = int.tryParse(hour) ?? 12;
    
    // Assuming input is UTC (London time)
    final wib = (h + 7) % 24; // WIB = UTC + 7
    final wita = (h + 8) % 24; // WITA = UTC + 8
    final wit = (h + 9) % 24; // WIT = UTC + 9
    
    return {
      'London': '$h:00',
      'WIB': '$wib:00',
      'WITA': '$wita:00',
      'WIT': '$wit:00',
    };
  }
}
