import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:car_hmi/controllers/player_controller.dart';
import 'package:car_hmi/controllers/radio_controller.dart';
import 'package:car_hmi/models/player_state.dart';
import 'package:car_hmi/services/radio_service.dart';
import 'package:car_hmi/views/panels/player_panel.dart';
import 'package:car_hmi/views/panels/radio_panel.dart';
import 'package:car_hmi/views/widgets/big_button.dart';
import 'package:car_hmi/views/widgets/top_bar.dart';
import 'package:car_hmi/views/widgets/volume_bar.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('BigButton invokes tap and long-press callbacks', (tester) async {
    var taps = 0;
    var longPresses = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BigButton(
          onPressed: () => taps++,
          onLongPress: () => longPresses++,
          child: const Text('Ação'),
        ),
      ),
    ));

    await tester.tap(find.text('Ação'));
    await tester.pump();
    await tester.longPress(find.text('Ação'));
    await tester.pump();

    expect(taps, 1);
    expect(longPresses, 1);
  });

  testWidgets('VolumeBar displays the value and triggers both controls',
      (tester) async {
    var down = 0;
    var up = 0;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: VolumeBar(value: 65, onDown: () => down++, onUp: () => up++),
      ),
    ));

    expect(find.text('65%'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_down));
    await tester.tap(find.byIcon(Icons.volume_up));

    expect(down, 1);
    expect(up, 1);
  });

  testWidgets('TopBar reports tab selection and player connection',
      (tester) async {
    final controller = PlayerController(FakePlayerService());
    addTearDown(controller.dispose);
    var selectedTab = -1;

    await tester.pumpWidget(ChangeNotifierProvider<PlayerController>.value(
      value: controller,
      child: MaterialApp(
        home: Scaffold(
          body: TopBar(tab: 0, onTab: (tab) => selectedTab = tab),
        ),
      ),
    ));

    expect(find.text('Música'), findsOneWidget);
    expect(find.text('Rádio'), findsOneWidget);
    expect(find.byTooltip('Player offline'), findsOneWidget);

    await tester.tap(find.text('Rádio'));
    expect(selectedTab, 1);
  });

  testWidgets('PlayerPanel reflects state and forwards transport controls',
      (tester) async {
    final service = FakePlayerService();
    final controller = PlayerController(service);
    addTearDown(controller.dispose);
    controller.init();

    await tester.pumpWidget(ChangeNotifierProvider<PlayerController>.value(
      value: controller,
      child: const MaterialApp(home: Scaffold(body: PlayerPanel())),
    ));

    service.emit(const PlayerState(
      status: PlaybackStatus.playing,
      track: TrackInfo(
        title: 'Minha faixa',
        artist: 'Meu artista',
        album: 'Meu álbum',
        durationSec: 180,
      ),
      positionSec: 30,
      volume: 55,
      connected: true,
    ));
    await tester.pump();

    expect(find.text('Minha faixa'), findsOneWidget);
    expect(find.text('Meu artista'), findsOneWidget);
    expect(find.text('Meu álbum'), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.text('0:30'), findsOneWidget);
    expect(find.text('3:00'), findsOneWidget);
    expect(find.text('55%'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.tap(find.byIcon(Icons.skip_previous));
    await tester.tap(find.byIcon(Icons.skip_next));
    await tester.pump();

    expect(service.commands, ['playPause', 'previous', 'next']);
  });

  testWidgets('RadioPanel changes band, tunes and controls power/volume',
      (tester) async {
    final service = FakeRadioService();
    final controller = RadioController(service);
    addTearDown(controller.dispose);

    await tester.pumpWidget(ChangeNotifierProvider<RadioController>.value(
      value: controller,
      child: const MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 900, height: 700, child: RadioPanel()),
        ),
      ),
    ));

    expect(find.text('98.5'), findsNWidgets(2));
    await tester.tap(find.text('AM'));
    await tester.pump();
    expect(find.text('1020'), findsNWidgets(2));
    expect(service.tunes, [(RadioBand.am, 1020)]);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(controller.frequency, 1030);

    await tester.tap(find.byIcon(Icons.power_settings_new));
    await tester.pump();
    expect(controller.power, isFalse);
    expect(service.powers, [false]);

    await tester.tap(find.byIcon(Icons.volume_up));
    await tester.pump();
    expect(controller.volume, 45);
    expect(service.volumes, [45]);
  });
}
