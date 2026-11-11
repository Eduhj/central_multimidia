import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/player_controller.dart';
import '../../core/app_theme.dart';
import 'big_button.dart';

class TopBar extends StatelessWidget {
  const TopBar({super.key, required this.tab, required this.onTab});

  final int tab;
  final ValueChanged<int> onTab;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            const SizedBox(width: 70, child: ClockText()),
            const Spacer(),
            _tab(0, Icons.music_note, 'Música'),
            const SizedBox(width: 8),
            _tab(1, Icons.radio, 'Rádio'),
            const SizedBox(width: 8),
            _tab(2, Icons.camera_rear, 'Ré'),
            const Spacer(),
            const SizedBox(
                width: 70,
                child: Align(
                    alignment: Alignment.centerRight,
                    child: _PlayerStatusDot())),
          ],
        ),
      ),
    );
  }

  Widget _tab(int i, IconData icon, String label) => BigButton(
        width: 160,
        height: 48,
        selected: tab == i,
        onPressed: () => onTab(i),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 26),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 20)),
        ]),
      );
}

class _PlayerStatusDot extends StatelessWidget {
  const _PlayerStatusDot();

  @override
  Widget build(BuildContext context) {
    final connected =
        context.select<PlayerController, bool>((c) => c.state.connected);
    return Tooltip(
      message: connected ? 'Player conectado' : 'Player offline',
      child: Icon(Icons.circle,
          size: 18, color: connected ? AppColors.ok : AppColors.warn),
    );
  }
}

class ClockText extends StatefulWidget {
  const ClockText({super.key});

  @override
  State<ClockText> createState() => _ClockTextState();
}

class _ClockTextState extends State<ClockText> {
  late final Timer _t;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _t.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    return Text('${two(_now.hour)}:${two(_now.minute)}',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold));
  }
}
