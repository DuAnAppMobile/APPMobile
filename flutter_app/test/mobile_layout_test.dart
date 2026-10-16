import 'package:english_rpg_app/main.dart';
import 'package:english_rpg_app/services/player_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('small phone with keyboard on $platform', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      GoogleFonts.config.allowRuntimeFetching = false;
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });
      expect(
        apiBaseUrl,
        platform == TargetPlatform.android
            ? 'http://10.0.2.2:5137/api'
            : 'http://127.0.0.1:5137/api',
      );
      await tester.pumpWidget(const EnglishRpgApp());
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Tiếp tục'));
      await tester.tap(find.text('Tiếp tục'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bắt đầu'));
      await tester.pumpAndSettle();
      final button = find.widgetWithText(FilledButton, 'Đăng nhập');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump();
      expect(find.text('Vui lòng nhập tên tài khoản.'), findsOneWidget);
      // Leave rendering errors to Flutter's test binding for full diagnostics.
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
