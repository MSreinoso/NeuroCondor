String formatDuration(Duration value) {
  final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
  final seconds = value.inSeconds.remainder(60).toString().padLeft(2, '0');
  final tenths = (value.inMilliseconds.remainder(1000) ~/ 100).toString();
  return '$minutes:$seconds.$tenths';
}
