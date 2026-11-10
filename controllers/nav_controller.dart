import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/map_service.dart';

class NavController extends ChangeNotifier {
  NavController(this._service);

  final MapService _service;
  final mapController = MapController();
  StreamSubscription<VehiclePosition>? _sub;
  bool _ready = false;

  late LatLng position = _service.current.latLng;
  double heading = 0;
  double speedKmh = 0;
  bool follow = true;

  void init() {
    _sub = _service.positionStream.listen((p) {
      position = p.latLng;
      heading = p.heading;
      speedKmh = p.speedKmh;
      if (follow && _ready) {
        mapController.move(position, mapController.camera.zoom);
      }
      notifyListeners();
    });
  }

  void onMapReady() => _ready = true;

  void onUserGesture() {
    if (follow) {
      follow = false;
      notifyListeners();
    }
  }

  void zoom(double delta) {
    if (!_ready) return;
    final cam = mapController.camera;
    mapController.move(cam.center, (cam.zoom + delta).clamp(3, 19).toDouble());
  }

  void recenter() {
    follow = true;
    if (_ready) mapController.move(position, mapController.camera.zoom);
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    super.dispose();
  }
}
