import 'dart:async';
import 'dart:js_interop';

import 'package:latlong2/latlong.dart';
import 'package:web/web.dart' as web;

import '../map_service.dart';

const bool gpsAvailable = true;

Stream<VehiclePosition> watchGps() {
  late final StreamController<VehiclePosition> ctrl;
  int? watchId;
  double lastHeading = 0;

  ctrl = StreamController<VehiclePosition>(
    onListen: () {
      watchId = web.window.navigator.geolocation.watchPosition(
        (web.GeolocationPosition p) {
          final c = p.coords;
          final h = c.heading;
          if (h != null && !h.isNaN) lastHeading = h;
          final s = c.speed;
          ctrl.add(VehiclePosition(
            LatLng(c.latitude, c.longitude),
            lastHeading,
            (s == null || s.isNaN) ? 0 : s * 3.6,
          ));
        }.toJS,
        (web.GeolocationPositionError e) {
          ctrl.addError(switch (e.code) {
            1 => 'Permissão de localização negada',
            2 => 'Posição indisponível',
            3 => 'Tempo esgotado ao obter posição',
            _ => 'Erro de GPS',
          });
        }.toJS,
        web.PositionOptions(
          enableHighAccuracy: true,
          maximumAge: 1000,
          timeout: 20000,
        ),
      );
    },
    onCancel: () {
      final id = watchId;
      if (id != null) web.window.navigator.geolocation.clearWatch(id);
    },
  );
  return ctrl.stream;
}
