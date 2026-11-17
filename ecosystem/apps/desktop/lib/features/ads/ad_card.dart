import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'ad_controller.dart';
import 'ad_media.dart';
import 'ad_model.dart';

class AdCard extends ConsumerWidget {
  const AdCard({super.key, required this.ad});
  final AdItem ad;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Card(
    clipBehavior: Clip.antiAlias, elevation: 4,
    child: SizedBox(width: 340, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Stack(children: [
        SizedBox(height: 105, width: double.infinity, child: AdMedia(ad: ad)),
        Positioned(right: 2, top: 2, child: IconButton.filledTonal(tooltip: 'Cerrar anuncio',
          onPressed: () => unawaited(ref.read(adControllerProvider).dismiss(ad)), icon: const Icon(Icons.close))),
      ]),
      Padding(padding: const EdgeInsets.fromLTRB(12, 7, 12, 10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(ad.badge.isEmpty ? 'Publicidad' : 'Publicidad · ${ad.badge}', style: Theme.of(context).textTheme.labelSmall),
        Text(ad.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall),
        if (ad.subtitle.isNotEmpty) Text(ad.subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        TextButton(onPressed: () {
          unawaited(ref.read(adControllerProvider).click(ad));
          unawaited(launchUrl(ad.target, mode: LaunchMode.externalApplication).catchError((_) => false));
        }, child: Text(ad.cta)),
      ])),
    ])),
  );
}
