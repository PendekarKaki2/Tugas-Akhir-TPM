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

  /// Convert time between arbitrary timezone offsets.
  ///
  /// [sourceOffsetHours] and each target offset are expressed as hours from UTC.
  /// For example, WIB = 7, WITA = 8, WIT = 9.
  Map<String, String> convertTime({
    required String hour,
    required double sourceOffsetHours,
    required Map<String, double> targetOffsets,
  }) {
    final int h = int.tryParse(hour) ?? 12;
    final normalizedHour = h.clamp(0, 23);

    final baseUtc = DateTime.utc(2000, 1, 1, normalizedHour);
    final sourceOffset = Duration(minutes: (sourceOffsetHours * 60).round());
    final utcTime = baseUtc.subtract(sourceOffset);

    final result = <String, String>{};
    for (final entry in targetOffsets.entries) {
      final targetOffset = Duration(minutes: (entry.value * 60).round());
      final local = utcTime.add(targetOffset);
      final dayShift = local.day - baseUtc.day;
      final suffix = dayShift == 0
          ? ''
          : dayShift > 0
              ? ' (+$dayShift hari)'
              : ' (${dayShift} hari)';
      result[entry.key] = '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}$suffix';
    }

    return result;
  }
}
