import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;

  LocationProvider(this._locationService);

  Position? _position;
  bool _isLoading = false;
  String? _error;

  Position? get position => _position;
  bool get isLoading => _isLoading;
  String? get error => _error;

  String get locationLabel {
    if (_position == null) {
      return 'Lokasi belum tersedia';
    }

    return '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
  }

  Future<void> fetchLocation() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _position = await _locationService.getCurrentPosition();
      if (_position == null) {
        _error = 'Izin lokasi ditolak atau GPS tidak aktif';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
