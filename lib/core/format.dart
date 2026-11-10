String fmtTime(double seconds) {
  final t = (seconds.isNaN || seconds < 0) ? 0 : seconds.floor();
  return '${t ~/ 60}:${(t % 60).toString().padLeft(2, '0')}';
}
