const adProject = 'lexairdownload';
final adBase = Uri.parse('https://studiolexair.ddns.net');
final adEndpoint = Uri.parse('https://ywrspyrplgwxkwdboaiz.supabase.co/functions/v1/ads-feed');

Uri? adHttpsUrl(Object? raw, {bool allowRelative = false}) {
  if (raw is! String || raw.isEmpty || raw != raw.trim()) return null;
  if (allowRelative && raw.startsWith('/') && !raw.startsWith('//') && !raw.contains('\\')) {
    final u = adBase.resolve(raw);
    return u.scheme == 'https' && u.host == adBase.host ? u : null;
  }
  if (!raw.startsWith('https://')) return null;
  final u = Uri.tryParse(raw);
  return u != null && u.scheme == 'https' && u.host.isNotEmpty && u.userInfo.isEmpty ? u : null;
}

class AdItem {
  const AdItem({required this.id, required this.title, required this.subtitle, required this.badge,
    required this.mediaType, required this.media, required this.poster, required this.target,
    required this.cta, required this.placement, required this.position, required this.delay,
    required this.cooldown, required this.maxViews, required this.autoHide, required this.frequency,
    required this.excluded});
  final String id, title, subtitle, badge, mediaType, cta, placement, position, frequency;
  final Uri media, target;
  final Uri? poster;
  final int delay, cooldown, maxViews, autoHide;
  final List<String> excluded;

  static AdItem? parse(Object? value) {
    if (value is! Map) return null;
    final id = value['id'], media = adHttpsUrl(value['media_url']),
      target = adHttpsUrl(value['target_url'], allowRelative: true);
    final type = value['media_type'], placement = value['placement'];
    if (id is! String || !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id) ||
        media == null || target == null || !['image', 'gif', 'video'].contains(type) ||
        !['corner', 'banner', 'modal', 'inline'].contains(placement)) return null;
    int number(String key, int fallback) => value[key] is num ? (value[key] as num).toInt().clamp(0, 31536000) : fallback;
    String text(String key, [String fallback = '']) => value[key] is String ? value[key] as String : fallback;
    final mode = text('frequency_mode', 'cooldown');
    if (!['once', 'cooldown', 'session'].contains(mode)) return null;
    return AdItem(id: id, title: text('title'), subtitle: text('subtitle'), badge: text('badge'),
      mediaType: type as String, media: media, poster: adHttpsUrl(value['poster_url']), target: target,
      cta: text('cta_label', 'Ver más'), placement: placement as String, position: text('position'),
      delay: number('delay_seconds', 0), cooldown: number('cooldown_hours', 24),
      maxViews: number('max_views_per_session', 1), autoHide: number('auto_hide_seconds', 0),
      frequency: mode, excluded: value['exclude_paths'] is List
        ? (value['exclude_paths'] as List).whereType<String>().toList() : []);
  }
}
