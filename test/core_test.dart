import 'package:flutter_test/flutter_test.dart';

import 'package:car_hmi/core/format.dart';
import 'package:car_hmi/models/player_state.dart';
import 'package:car_hmi/services/radio_service.dart';

void main() {
  group('fmtTime', () {
    test('formats whole and fractional seconds', () {
      expect(fmtTime(0), '0:00');
      expect(fmtTime(9.9), '0:09');
      expect(fmtTime(61.8), '1:01');
      expect(fmtTime(3600), '60:00');
    });

    test('clamps negative and NaN values to zero', () {
      expect(fmtTime(-1), '0:00');
      expect(fmtTime(double.nan), '0:00');
    });
  });

  group('PlayerState', () {
    test('uses the documented defaults', () {
      const state = PlayerState();

      expect(state.status, PlaybackStatus.stopped);
      expect(state.track, isNull);
      expect(state.positionSec, 0);
      expect(state.volume, 50);
      expect(state.connected, isFalse);
      expect(state.message, 'Conectando…');
    });

    test('copyWith preserves unspecified values and replaces provided ones',
        () {
      const track = TrackInfo(
        title: 'Faixa',
        artist: 'Artista',
        album: 'Álbum',
        artUrl: 'https://example.com/art.png',
        durationSec: 123,
      );
      const state = PlayerState(
        status: PlaybackStatus.playing,
        track: track,
        positionSec: 12,
        volume: 70,
        connected: true,
        message: 'Online',
      );

      final updated = state.copyWith(positionSec: 20, volume: 25);

      expect(updated.status, PlaybackStatus.playing);
      expect(updated.track, track);
      expect(updated.positionSec, 20);
      expect(updated.volume, 25);
      expect(updated.connected, isTrue);
      expect(updated.message, 'Online');
    });

    test('TrackInfo equality includes all fields', () {
      const first =
          TrackInfo(title: 'Faixa', artist: 'Artista', durationSec: 10);
      const equal =
          TrackInfo(title: 'Faixa', artist: 'Artista', durationSec: 10);
      const different =
          TrackInfo(title: 'Faixa', artist: 'Artista', durationSec: 11);

      expect(first, equal);
      expect(first.hashCode, equal.hashCode);
      expect(first, isNot(different));
    });
  });

  group('RadioBandX', () {
    test('exposes band ranges, steps, units and labels', () {
      expect(RadioBand.fm.min, 87.5);
      expect(RadioBand.fm.max, 108);
      expect(RadioBand.fm.step, 0.1);
      expect(RadioBand.fm.unit, 'MHz');
      expect(RadioBand.fm.label, 'FM');
      expect(RadioBand.am.min, 530);
      expect(RadioBand.am.max, 1710);
      expect(RadioBand.am.step, 10);
      expect(RadioBand.am.unit, 'kHz');
      expect(RadioBand.am.label, 'AM');
    });

    test('formats and snaps frequencies to the band step', () {
      expect(RadioBand.fm.format(98.5), '98.5');
      expect(RadioBand.am.format(1020), '1020');
      expect(RadioBand.fm.snap(98.56), 98.6);
      expect(RadioBand.am.snap(1024), 1020);
    });
  });
}
