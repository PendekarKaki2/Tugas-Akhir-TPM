import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../core/services/location_service.dart';
import '../../data/models/user_location_model.dart';
import '../../data/repositories/user_location_repository.dart';

class LocationProvider extends ChangeNotifier {
  final LocationService _locationService;
  final UserLocationRepository _locationRepository;

  LocationProvider(this._locationService, this._locationRepository);

  Position? _position;
  bool _isLoading = false;
  String? _error;
  String? _resolvedLocationName;
  List<UserLocationModel> _leaderboardSnapshots = [];

  Position? get position => _position;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get resolvedLocationName => _resolvedLocationName;
  List<UserLocationModel> get leaderboardSnapshots => _leaderboardSnapshots;

  String get locationLabel {
    if (_position == null) {
      return 'Lokasi belum tersedia';
    }

    final resolved = _resolvedLocationName;
    if (resolved != null && resolved.isNotEmpty) {
      return '$resolved (${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)})';
    }

    return '${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}';
  }

  Future<void> fetchLocation({int? userId, String? userName, int points = 0}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _position = await _locationService.getCurrentPosition();
      if (_position == null) {
        _error = 'Izin lokasi ditolak atau GPS tidak aktif';
        return;
      }

      _resolvedLocationName = await _resolveLocationName(_position!);

      if (userId != null && userName != null) {
        await _locationRepository.saveSnapshot(
          UserLocationModel(
            userId: userId,
            userName: userName,
            latitude: _position!.latitude,
            longitude: _position!.longitude,
            locationName: _resolvedLocationName ?? 'Unknown area',
            points: points,
          ),
        );
        await loadLeaderboardSnapshots();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboardSnapshots() async {
    try {
      _leaderboardSnapshots = await _locationRepository.getLatestSnapshots();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<String?> _resolveLocationName(Position position) async {
    if (kIsWeb) {
      return null;
    }

    try {
      final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isEmpty) return null;

      final place = placemarks.first;
      final parts = <String>[];
      final locality = place.locality ?? place.subAdministrativeArea;
      final adminArea = place.administrativeArea;
      if (locality != null && locality.isNotEmpty) parts.add(locality);
      if (adminArea != null && adminArea.isNotEmpty && adminArea != locality) parts.add(adminArea);
      if (parts.isEmpty && (place.country?.isNotEmpty ?? false)) parts.add(place.country!);
      return parts.isEmpty ? null : parts.join(', ');
    } catch (_) {
      return null;
    }
  }
}
