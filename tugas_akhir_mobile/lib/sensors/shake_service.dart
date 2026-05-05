import 'dart:async';
import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class ShakeService {
  StreamSubscription<AccelerometerEvent>? _subscription;
  DateTime _lastShake = DateTime.fromMillisecondsSinceEpoch(0);

  void startListening({required void Function() onShake}) {
    stopListening();

    _subscription = accelerometerEvents.listen((event) {
      final force = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z,
      );

      final now = DateTime.now();
      if (force > 18 && now.difference(_lastShake).inMilliseconds > 1200) {
        _lastShake = now;
        onShake();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }
}
