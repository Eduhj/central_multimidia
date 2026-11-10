import 'package:flutter/foundation.dart';

import '../services/radio_service.dart';

class RadioController extends ChangeNotifier {
  RadioController(this._service);

  final RadioService _service;

  RadioBand band = RadioBand.fm;
  bool power = true;
  bool seeking = false;
  int volume = 40;

  final Map<RadioBand, double> _freq = {RadioBand.fm: 98.5, RadioBand.am: 1020};
  final Map<RadioBand, List<double?>> presets = {
    RadioBand.fm: [88.3, 98.5, 104.9, null, null, null],
    RadioBand.am: [640, 1020, null, null, null, null],
  };

  double get frequency => _freq[band]!;
  bool isPresetActive(int i) => presets[band]![i] == frequency;

  Future<void> setBand(RadioBand b) async {
    if (b == band) return;
    band = b;
    notifyListeners();
    await _service.tune(b, frequency);
  }

  Future<void> step(int dir) => _tune(frequency + dir * band.step);

  Future<void> _tune(double f) async {
    var v = f;
    if (v > band.max) v = band.min; // wrap-around
    if (v < band.min) v = band.max;
    v = band.snap(v);
    _freq[band] = v;
    notifyListeners();
    await _service.tune(band, v);
  }

  Future<void> seek({required bool up}) async {
    if (seeking) return;
    seeking = true;
    notifyListeners();
    final f = await _service.seek(band, frequency, up: up);
    seeking = false;
    await _tune(f);
  }

  Future<void> tunePreset(int i) async {
    final f = presets[band]![i];
    if (f != null) await _tune(f);
  }

  void savePreset(int i) {
    presets[band]![i] = frequency;
    notifyListeners();
  }

  Future<void> changeVolume(int delta) async {
    volume = (volume + delta).clamp(0, 100).toInt();
    notifyListeners();
    await _service.setVolume(volume);
  }

  Future<void> togglePower() async {
    power = !power;
    notifyListeners();
    await _service.setPower(power);
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
