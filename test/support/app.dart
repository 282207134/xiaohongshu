import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:life_notes/data/app_store.dart';
import 'package:life_notes/ui/theme.dart';

Future<AppStore> loadTestStore(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  SharedPreferences.setMockInitialValues({});
  return (await tester.runAsync(AppStore.load))!;
}

Future<void> pumpTestApp(WidgetTester tester, Widget page) async {
  await tester.pumpWidget(MaterialApp(theme: appTheme(), home: page));
  await tester.pumpAndSettle();
}
