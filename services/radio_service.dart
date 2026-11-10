import 'package:flutter/foundation.dart';

enum RadioBand { fm, am }

extension RadioBandX on RadioBand {
  bool get isFm => this == RadioBand.fm;
  double get min => isFm ? 87.5 : 530;
  double get max => isFm ? 108.0 : 1710;
  double get step => isFm ? 0.1 : 10;
  String get unit => isFm ? 'MHz' : 'kHz';
  String get label => isFm ? 'FM' : 'AM';
  String format(double f) => f.toStringAsFixed(isFm ? 1 : 0);
  double snap(double f) =>
      isFm ? (f * 10).round() / 10 : (f / 10).round() * 10.0;
}

/// Contrato para o futuro módulo receptor (serial/USB/I²C...).
abstract class RadioService {
  Future<void> setPower(bool on);
  Future<void> tune(RadioBand band, double frequency);
  Future<double> seek(RadioBand band, double from, {required bool up});
  Future<void> setVolume(int percent);
  Future<void> dispose();
}

class MockRadioService implements RadioService {
  static const _fm = [88.3, 91.7, 94.5, 98.5, 101.1, 104.9, 107.3];
  static const _am = [560.0, 640.0, 790.0, 1020.0, 1230.0, 1450.0];

  @override
  Future<void> setPower(bool on) async =>
      debugPrint('[RADIO] POWER ${on ? "ON" : "OFF"}');

  @override
  Future<void> tune(RadioBand band, double frequency) async => debugPrint(
      '[RADIO] TUNE ${band.label} ${band.format(frequency)} ${band.unit}');

  @override
  Future<double> seek(RadioBand band, double from, {required bool up}) async {
    await Future<void>.delayed(
        const Duration(milliseconds: 300)); // simula varredura
    final list = band.isFm ? _fm : _am;
    if (up) {
      return list.firstWhere((f) => f > from + 0.01, orElse: () => list.first);
    }
    return list.lastWhere((f) => f < from - 0.01, orElse: () => list.last);
  }

  @override
  Future<void> setVolume(int percent) async =>
      debugPrint('[RADIO] VOL $percent');

  @override
  Future<void> dispose() async {}
}
