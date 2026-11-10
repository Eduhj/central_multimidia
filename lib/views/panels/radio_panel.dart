import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/radio_controller.dart';
import '../../core/app_theme.dart';
import '../../services/radio_service.dart';
import '../widgets/big_button.dart';
import '../widgets/volume_bar.dart';

class RadioPanel extends StatelessWidget {
  const RadioPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.surface, borderRadius: BorderRadius.circular(28)),
      child: Consumer<RadioController>(
        builder: (context, r, _) => Column(
          children: [
            // Banda + power
            Row(children: [
              Expanded(child: _bandButton(r, RadioBand.fm)),
              const SizedBox(width: 10),
              Expanded(child: _bandButton(r, RadioBand.am)),
              const SizedBox(width: 10),
              BigButton(
                width: 56,
                height: 56,
                filled: r.power,
                onPressed: r.togglePower,
                child: const Icon(Icons.power_settings_new, size: 30),
              ),
            ]),

            // Frequência (FittedBox adapta à altura disponível)
            Expanded(
              child: Opacity(
                opacity: r.power ? 1 : .35,
                child: FittedBox(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: r.seeking
                        ? const Text('Buscando…',
                            style: TextStyle(
                                fontSize: 56, color: AppColors.textDim))
                        : Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(r.band.format(r.frequency),
                                  style: const TextStyle(
                                      fontSize: 96,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accent)),
                              const SizedBox(width: 10),
                              Text(r.band.unit,
                                  style: const TextStyle(
                                      fontSize: 30, color: AppColors.textDim)),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            // Sintonia: seek ◀◀  −  +  ▶▶
            Row(children: [
              Expanded(
                  child: BigButton(
                      height: 68,
                      onPressed: r.power ? () => r.seek(up: false) : null,
                      child: const Icon(Icons.fast_rewind, size: 38))),
              const SizedBox(width: 10),
              Expanded(
                  child: BigButton(
                      height: 68,
                      onPressed: r.power ? () => r.step(-1) : null,
                      child: const Icon(Icons.remove, size: 38))),
              const SizedBox(width: 10),
              Expanded(
                  child: BigButton(
                      height: 68,
                      onPressed: r.power ? () => r.step(1) : null,
                      child: const Icon(Icons.add, size: 38))),
              const SizedBox(width: 10),
              Expanded(
                  child: BigButton(
                      height: 68,
                      onPressed: r.power ? () => r.seek(up: true) : null,
                      child: const Icon(Icons.fast_forward, size: 38))),
            ]),
            const SizedBox(height: 10),

            // Favoritas: toque = sintoniza, segurar = salva
            for (var row = 0; row < 2; row++) ...[
              if (row > 0) const SizedBox(height: 8),
              Row(children: [
                for (var col = 0; col < 3; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(child: _preset(r, row * 3 + col)),
                ],
              ]),
            ],
            const SizedBox(height: 6),
            const Text('Toque para sintonizar • Segure para salvar',
                style: TextStyle(fontSize: 14, color: AppColors.textDim)),
            const SizedBox(height: 10),

            VolumeBar(
                value: r.volume,
                onDown: () => r.changeVolume(-5),
                onUp: () => r.changeVolume(5)),
          ],
        ),
      ),
    );
  }

  Widget _bandButton(RadioController r, RadioBand b) => BigButton(
        height: 56,
        selected: r.band == b,
        onPressed: () => r.setBand(b),
        child: Text(b.label, style: const TextStyle(fontSize: 26)),
      );

  Widget _preset(RadioController r, int i) {
    final f = r.presets[r.band]![i];
    return BigButton(
      height: 52,
      selected: r.isPresetActive(i),
      onPressed: () => r.tunePreset(i),
      onLongPress: () => r.savePreset(i),
      child: Text(f == null ? '＋' : r.band.format(f),
          style: TextStyle(
              fontSize: 22, color: f == null ? AppColors.textDim : null)),
    );
  }
}
