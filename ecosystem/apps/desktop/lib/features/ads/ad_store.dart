import 'dart:convert';
import 'package:lexair_storage_core/lexair_storage_core.dart';
import 'package:uuid/uuid.dart';
import 'ad_model.dart';

/// Stored in the app's existing local SQLite database; no credentials are stored.
class AdStore {
  AdStore(this.db);
  final LexairDatabase db;
  Future<String> visitor() async {
    final saved = await db.readSetting('ads_visitor_id');
    if (saved != null && RegExp(r'^v-[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$').hasMatch(saved)) return saved;
    final id = 'v-${const Uuid().v4()}';
    await db.writeSetting('ads_visitor_id', id); return id;
  }
  Future<bool> eligible(AdItem ad, DateTime now, int sessionViews) async {
    if (await db.readSetting('clicked_${ad.id}') == '1') return false;
    final dismissed = int.tryParse(await db.readSetting('dismissed_${ad.id}') ?? '') ?? 0;
    if (dismissed > now.millisecondsSinceEpoch) return false;
    final seen = int.tryParse(await db.readSetting('seen_${ad.id}') ?? '');
    if (seen != null && ad.frequency == 'once') return false;
    if (seen != null && ad.frequency == 'cooldown' &&
        seen + ad.cooldown * 3600000 > now.millisecondsSinceEpoch) return false;
    return sessionViews < ad.maxViews;
  }
  Future<void> seen(AdItem ad, DateTime now) => db.writeSetting('seen_${ad.id}', '${now.millisecondsSinceEpoch}');
  Future<void> clicked(AdItem ad) => db.writeSetting('clicked_${ad.id}', '1');
  Future<void> dismissed(AdItem ad, DateTime now) => db.writeSetting('dismissed_${ad.id}',
      '${now.millisecondsSinceEpoch + ad.cooldown * 3600000}');

  Future<List<Map<String, dynamic>>> pending() async {
    try {
      final decoded = jsonDecode(await db.readSetting('ads_outbox') ?? '[]');
      return (decoded as List).whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    } catch (_) { return []; }
  }
  Future<void> savePending(List<Map<String, dynamic>> events) => db.writeSetting('ads_outbox', jsonEncode(events));
}
