import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'ad_model.dart';

class AdMedia extends StatefulWidget {
  const AdMedia({super.key, required this.ad});
  final AdItem ad;
  @override
  State<AdMedia> createState() => _AdMediaState();
}

class _AdMediaState extends State<AdMedia> {
  Player? player;
  VideoController? controller;
  @override
  void initState() {
    super.initState();
    if (widget.ad.mediaType == 'video') {
      try {
        final p = Player(); player = p; controller = VideoController(p);
        unawaited(_play(p));
      } catch (_) { /* An unsupported media engine must not break the app. */ }
    }
  }
  Future<void> _play(Player p) async {
    try { await p.setVolume(0); await p.open(Media(widget.ad.media.toString())); } catch (_) {}
  }
  @override
  void dispose() { if (player != null) unawaited(player!.dispose()); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    if (controller != null) return Video(controller: controller!, controls: NoVideoControls);
    final url = widget.ad.mediaType == 'video' ? widget.ad.poster : widget.ad.media;
    return url == null ? const ColoredBox(color: Colors.black12)
      : Image.network(url.toString(), fit: BoxFit.cover, errorBuilder: (_, error, stack) => const ColoredBox(color: Colors.black12));
  }
}
