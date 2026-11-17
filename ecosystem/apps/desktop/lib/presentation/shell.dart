import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../app/sections.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.currentPath, required this.child});
  final String currentPath;
  final Widget child;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Row(children: [
      SizedBox(width: 240, child: Material(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        child: Column(children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(22, 24, 18, 20),
            child: Row(children: [
              Icon(Icons.graphic_eq_rounded, color: Color(0xff77a7ff)), SizedBox(width: 12),
              Expanded(child: Text('LEXAIR DOWNLOAD',
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5))),
            ]),
          ),
          Expanded(child: ListView.builder(
            itemCount: sections.length,
            itemBuilder: (context, index) {
              final section = sections[index];
              return ListTile(
                dense: true, leading: Icon(section.icon, size: 20),
                title: Text(section.label), selected: currentPath == section.path,
                selectedColor: Theme.of(context).colorScheme.primary,
                selectedTileColor: Theme.of(context).colorScheme.primary.withValues(alpha: .10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                onTap: () => context.go(section.path),
              );
            },
          )),
        ]),
      )),
      Expanded(child: child),
    ]),
  );
}
