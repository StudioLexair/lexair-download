import 'package:flutter/material.dart';
import 'player_session.dart';

class PlayerControls extends StatelessWidget {
  const PlayerControls({super.key, required this.session, required this.enabled});
  final PlayerSession session;
  final bool enabled;

  String format(Duration d) {
    final h = d.inHours;
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final player = session.player;
    return Column(children: [
      StreamBuilder<Duration>(stream: player.stream.duration, initialData: Duration.zero,
        builder: (context, durationSnap) => StreamBuilder<Duration>(
          stream: player.stream.position, initialData: Duration.zero,
          builder: (context, positionSnap) {
            final total = durationSnap.data ?? Duration.zero;
            final position = positionSnap.data ?? Duration.zero;
            final max = total.inMilliseconds.toDouble();
            return Row(children: [
              Text(format(position)),
              Expanded(child: Slider(value: max > 0 ? position.inMilliseconds.toDouble().clamp(0.0, max) : 0,
                max: max > 0 ? max : 1,
                onChanged: enabled && max > 0 ? (v) => session.seek(Duration(milliseconds: v.round())) : null)),
              Text(format(total)),
            ]);
          },
        )),
      Row(children: [
        StreamBuilder<bool>(stream: player.stream.playing, initialData: false,
          builder: (context, snap) => IconButton.filledTonal(
            onPressed: enabled ? session.playPause : null,
            tooltip: snap.data == true ? 'Pausar' : 'Reproducir',
            icon: Icon(snap.data == true ? Icons.pause : Icons.play_arrow))),
        IconButton(onPressed: enabled ? session.stop : null, tooltip: 'Detener', icon: const Icon(Icons.stop)),
        const SizedBox(width: 12), const Icon(Icons.volume_up_outlined, size: 20),
        SizedBox(width: 130, child: StreamBuilder<double>(stream: player.stream.volume, initialData: 100,
          builder: (context, snap) => Slider(value: (snap.data ?? 100).clamp(0, 100), max: 100,
            onChanged: enabled ? session.setVolume : null))),
        const Spacer(),
        const Text('Velocidad'), const SizedBox(width: 8),
        StreamBuilder<double>(stream: player.stream.rate, initialData: 1,
          builder: (context, snap) => DropdownButton<double>(
            value: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].contains(snap.data) ? snap.data : 1.0,
            items: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((x) => DropdownMenuItem(value: x, child: Text('${x}x'))).toList(),
            onChanged: enabled ? (value) { if (value != null) session.setSpeed(value); } : null)),
      ]),
    ]);
  }
}
