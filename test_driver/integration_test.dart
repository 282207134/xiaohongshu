import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot:
        (String name, List<int> bytes, [Map<String, Object?>? args]) async {
          final directory =
              Platform.environment['SCREENSHOT_DIR'] ??
              'docs/screenshots/android';
          final file = File('$directory/$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes);
          return true;
        },
    // Screenshots are already saved; avoid duplicating their bytes in JSON.
    responseDataCallback: (_) async {},
  );
}
