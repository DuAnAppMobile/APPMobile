import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory(
    Platform.environment['FLUTTER_SCREENSHOTS_DIR'] ?? 'build/ui-screenshots',
  );
  await directory.create(recursive: true);
  await integrationDriver(
    responseDataCallback: null,
    onScreenshot: (name, bytes, [args]) async {
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
  );
}
