import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'ad_card.dart';
import 'ad_controller.dart';

/// Ads are restricted to discovery; forms and all other routes remain ad-free.
class AdHost extends ConsumerStatefulWidget {
  const AdHost({super.key, required this.child});
  final Widget child;
  @override
  ConsumerState<AdHost> createState() => _AdHostState();
}

class _AdHostState extends ConsumerState<AdHost> {
  bool? active;
  late final AdController _controller;
  bool _typing() {
    final context = FocusManager.instance.primaryFocus?.context;
    return context != null && (context.widget is EditableText ||
      context.findAncestorWidgetOfExactType<EditableText>() != null);
  }
  void _sync() {
    if (!mounted) return;
    final shouldShow = !_typing();
    if (active == shouldShow) return;
    active = shouldShow;
    if (shouldShow) { _controller.enter('/'); } else { _controller.leave(); }
  }
  @override
  void initState() {
    super.initState();
    _controller = ref.read(adControllerProvider);
    FocusManager.instance.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }
  @override
  void dispose() {
    FocusManager.instance.removeListener(_sync);
    // The route change removes this host; provider persists its session counters.
    _controller.leave(notify: false);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    final ads = ref.watch(adControllerProvider);
    final floating = ads.floating, inline = ads.inline;
    return Stack(children: [
      Column(children: [
        Expanded(child: widget.child),
        if (inline != null) Padding(padding: const EdgeInsets.all(8), child: AdCard(ad: inline)),
      ]),
      if (floating != null && floating.placement == 'modal')
        Positioned.fill(child: Center(child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340), child: AdCard(ad: floating)))),
      if (floating != null && floating.placement != 'modal') Positioned(
        left: floating.placement == 'banner' || floating.position == 'bottom-left' ? 12 : null,
        right: floating.placement == 'banner' || floating.position != 'bottom-left' ? 12 : null,
        top: floating.position == 'top' ? 12 : null,
        bottom: floating.position != 'top' ? 12 : null,
        child: Align(alignment: floating.position == 'bottom-left' ? Alignment.centerLeft : Alignment.centerRight,
          child: ConstrainedBox(constraints: BoxConstraints(maxWidth: floating.placement == 'banner' ? 700 : 340), child: AdCard(ad: floating))),
      ),
    ]);
  }
}
