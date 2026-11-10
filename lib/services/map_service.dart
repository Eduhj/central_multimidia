import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

class MapConfig {
  // Para produção: tiles offline/próprios (a política do OSM não permite uso pesado).
  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const userAgent = 'com.example.car_hmi';
}

class VehiclePosition {
  const VehiclePosition(this.latLng, this.heading, this.speedKmh);
  final LatLng latLng;
  final double heading; // graus, 0 = norte
  final double speedKmh;
}

/// Fonte de posição do veículo. GPS real ou simulado.
abstract class MapService {
  VehiclePosition get current;
  Stream<VehiclePosition> get positionStream;
  ValueListenable<String> get status;
  void dispose();
}

class MockMapService implements MapService {
  MockMapService() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  final _ctrl = StreamController<VehiclePosition>.broadcast();
  Timer? _timer;
  double _lat = -23.5505, _lng = -46.6333, _heading = 45;
  static const _speed = 15.0; // m/s ≈ 54 km/h

  @override
  final ValueNotifier<String> status = ValueNotifier('Posição simulada');

  @override
  VehiclePosition get current =>
      VehiclePosition(LatLng(_lat, _lng), _heading, _speed * 3.6);

  @override
  Stream<VehiclePosition> get positionStream => _ctrl.stream;

  void _tick() {
    final r = _heading * pi / 180;
    _lat += cos(r) * _speed / 111320;
    _lng += sin(r) * _speed / (111320 * cos(_lat * pi / 180));
    _heading = (_heading + 3) % 360; // percurso em curva suave
    _ctrl.add(current);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.close();
    status.dispose();
  }
}
