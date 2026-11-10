import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../controllers/nav_controller.dart';
import '../../core/app_theme.dart';
import '../../services/map_service.dart';
import '../widgets/big_button.dart';

class MapPanel extends StatelessWidget {
  const MapPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final nav = context.read<NavController>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: [
          FlutterMap(
            mapController: nav.mapController,
            options: MapOptions(
              initialCenter: nav.position,
              initialZoom: 16,
              minZoom: 3,
              maxZoom: 19,
              onMapReady: nav.onMapReady,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture)
                  nav.onUserGesture(); // arrastou = sai do "seguir"
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.tileUrl,
                userAgentPackageName: MapConfig.userAgent,
              ),
              // Só o marcador reconstrói a cada posição nova.
              Selector<NavController, ({LatLng p, double h})>(
                selector: (_, n) => (p: n.position, h: n.heading),
                builder: (_, v, __) => MarkerLayer(markers: [
                  Marker(
                    point: v.p,
                    width: 64,
                    height: 64,
                    child: Transform.rotate(
                      angle: v.h * pi / 180,
                      child: const Icon(Icons.navigation,
                          size: 48, color: AppColors.accent),
                    ),
                  ),
                ]),
              ),
              const RichAttributionWidget(
                alignment: AttributionAlignment.bottomLeft,
                attributions: [
                  TextSourceAttribution('© OpenStreetMap contributors')
                ],
              ),
            ],
          ),

          // Velocidade
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: .85),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Selector<NavController, double>(
                selector: (_, n) => n.speedKmh.roundToDouble(),
                builder: (_, v, __) => Text('${v.toInt()} km/h',
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold)),
              ),
            ),
          ),

          // Controles grandes
          Positioned(
            right: 12,
            bottom: 12,
            child: Column(
              children: [
                BigButton(
                    width: 72,
                    height: 72,
                    onPressed: () => nav.zoom(1),
                    child: const Icon(Icons.add, size: 40)),
                const SizedBox(height: 10),
                BigButton(
                    width: 72,
                    height: 72,
                    onPressed: () => nav.zoom(-1),
                    child: const Icon(Icons.remove, size: 40)),
                const SizedBox(height: 10),
                Selector<NavController, bool>(
                  selector: (_, n) => n.follow,
                  builder: (_, follow, __) => BigButton(
                    width: 72,
                    height: 72,
                    filled: follow,
                    onPressed: nav.recenter,
                    child: const Icon(Icons.my_location, size: 36),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
