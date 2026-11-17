import 'package:flutter_test/flutter_test.dart';
import 'package:lexair_downloader/main.dart';

void main() {
  testWidgets('Muestra el formulario de descarga', (tester) async {
    await tester.pumpWidget(const LexairApp());
    expect(find.text('LEXAIR DOWNLOAD'), findsOneWidget);
    expect(find.text('Descargar contenido'), findsOneWidget);
  });
}
