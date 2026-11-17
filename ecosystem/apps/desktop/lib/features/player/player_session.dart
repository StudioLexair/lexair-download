import 'dart:async';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

/// Owns one native player. No widgets or file pickers in this layer.
class PlayerSession {
  PlayerSession() : player = Player() {
    video = VideoController(player);
  }
  final Player player;
  late final VideoController video;

  Future<void> openFile(String path) => player.open(Media(path));
  Future<void> playPause() => player.playOrPause();
  Future<void> stop() => player.stop();
  Future<void> seek(Duration position) => player.seek(position);
  Future<void> setVolume(double value) => player.setVolume(value);
  Future<void> setSpeed(double value) => player.setRate(value);
  Future<void> loadSubtitles(String path) => player.setSubtitleTrack(
    SubtitleTrack.uri(Uri.file(path).toString()),
  );
  Future<void> dispose() => player.dispose();
}
