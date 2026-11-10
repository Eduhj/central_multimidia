import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:car_hmi/controllers/nav_controller.dart';
import 'package:car_hmi/services/map_service.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('map controller zooms within limits and follows vehicle',
      (tester) async {
    final service = FakeMapService();
    final controller = NavController(service);
    controller.init();
    addTearDown(controller.dispose);

    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 600,
        height: 400,
        child: FlutterMap(
          mapController: controller.mapController,
          options: MapOptions(
            initialCenter: controller.position,
            initialZoom: 16,
            minZoom: 3,
            maxZoom: 19,
            onMapReady: controller.onMapReady,
          ),
          children: const [],
        ),
      ),
    ));
    await tester.pumpAndSettle();

    controller.zoom(1);
    await tester.pump();
    expect(controller.mapController.camera.zoom, 17);

    controller.zoom(100);
    await tester.pump();
    expect(controller.mapController.camera.zoom, 19);

    controller.zoom(-100);
    await tester.pump();
    expect(controller.mapController.camera.zoom, 3);

    const newPosition = VehiclePosition(
      LatLng(-22.9, -43.2),
      120,
      35,
    );
    service.emit(newPosition);
    await tester.pump();
    expect(controller.mapController.camera.center, newPosition.latLng);

    controller.onUserGesture();
    const nextPosition = VehiclePosition(
      LatLng(-21.0, -44.0),
      180,
      20,
    );
    service.emit(nextPosition);
    await tester.pump();
    expect(controller.mapController.camera.center, newPosition.latLng);

    controller.recenter();
    await tester.pump();
    expect(controller.mapController.camera.center, nextPosition.latLng);
  });
}
