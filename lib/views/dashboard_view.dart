import 'package:flutter/material.dart';

import 'panels/map_panel.dart';
import 'panels/player_panel.dart';
import 'panels/radio_panel.dart';
import 'panels/reverse_camera_panel.dart';
import 'widgets/top_bar.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  int _tab = 0; // Música, Rádio ou câmera de ré simulada

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            TopBar(tab: _tab, onTab: (i) => setState(() => _tab = i)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Row(
                  children: [
                    const Expanded(flex: 11, child: MapPanel()),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 9,
                      // IndexedStack mantém os painéis montados ao trocar de aba.
                      child: IndexedStack(
                        index: _tab,
                        children: const [
                          PlayerPanel(),
                          RadioPanel(),
                          ReverseCameraPanel(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
