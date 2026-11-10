import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'gps/gps_source.dart';
import 'map_service.dart';

/// GPS real quando a plataforma tiver; senão cai no simulador.
class GpsMapService implements MapService {
  GpsMapService() {
    if (gpsAvailable) {
      status.value = 'Aguardando sinal de GPS…';
      _sub = watchGps().listen(
        (p) {
          _current = p;
          status.value = 'GPS ativo';
          _ctrl.add(p);
        },
        onError: (Object e) => status.value = '$e',
      );
    } else {
      _mock = MockMapService();
      status.value = 'GPS indisponível aqui – posição simulada';
      _sub = _mock!.positionStream.listen((p) {
        _current = p;
        _ctrl.add(p);
      });
    }
  }

  final _ctrl = StreamController<VehiclePosition>.broadcast();
  MockMapService? _mock;
  StreamSubscription<VehiclePosition>? _sub;
  VehiclePosition _current = VehiclePosition(LatLng(-23.5505, -46.6333), 0, 0);

  @override
  final ValueNotifier<String> status = ValueNotifier('');

  @override
  VehiclePosition get current => _current;

  @override
  Stream<VehiclePosition> get positionStream => _ctrl.stream;

  @override
  void dispose() {
    _sub?.cancel();
    _mock?.dispose();
    _ctrl.close();
    status.dispose();
  }
}
