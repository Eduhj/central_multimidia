import '../map_service.dart';

/// Sem GPS nesta plataforma por enquanto (no Linux final: gpsd).
const bool gpsAvailable = false;

Stream<VehiclePosition> watchGps() => Stream<VehiclePosition>.empty();
