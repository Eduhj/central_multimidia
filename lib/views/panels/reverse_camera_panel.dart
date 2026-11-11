import 'package:flutter/material.dart';

import '../../core/app_theme.dart';

class ReverseCameraPanel extends StatelessWidget {
  const ReverseCameraPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF202A36), Color(0xFF080B0F)],
              ),
            ),
          ),
          const CustomPaint(painter: _ParkingGuidesPainter()),
          Positioned(
            top: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Text(
                  'CÂMERA DE RÉ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'SIMULAÇÃO • SEM CÂMERA CONECTADA',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.warn,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: _VehiclePlaceholder(),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.bg.withValues(alpha: .8),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Imagem ilustrativa — não representa vídeo ao vivo',
                  style: TextStyle(color: AppColors.textDim, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehiclePlaceholder extends StatelessWidget {
  const _VehiclePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 124,
        height: 68,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              top: 4,
              child: Container(
                width: 78,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  border: Border.all(color: AppColors.textDim, width: 2),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            Container(
              width: 112,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                border: Border.all(color: AppColors.textDim, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.circle, size: 12, color: AppColors.warn),
                  Icon(Icons.circle, size: 12, color: AppColors.warn),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParkingGuidesPainter extends CustomPainter {
  const _ParkingGuidesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;
    final top = size.height * .25;
    final bottom = size.height * .78;

    final lanePaint = Paint()
      ..color = AppColors.ok.withValues(alpha: .75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final lane = Path()
      ..moveTo(center - size.width * .13, top)
      ..lineTo(center - size.width * .29, bottom)
      ..lineTo(center + size.width * .29, bottom)
      ..lineTo(center + size.width * .13, top);
    canvas.drawPath(lane, lanePaint);

    for (final (fraction, color) in [
      (.48, AppColors.ok),
      (.62, AppColors.warn),
      (.76, Colors.redAccent),
    ]) {
      final y = size.height * fraction;
      final guidePaint = Paint()
        ..color = color.withValues(alpha: .72)
        ..strokeWidth = 2;
      final halfWidth = size.width * (.13 + (fraction - .25) * .3);
      canvas.drawLine(
        Offset(center - halfWidth, y),
        Offset(center + halfWidth, y),
        guidePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParkingGuidesPainter oldDelegate) => false;
}
