import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'data/app_store.dart';
import 'ui/shell.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  SemanticsHandle? accessibility;
  @override
  void initState() {
    super.initState();
    if (kIsWeb) accessibility = WidgetsBinding.instance.ensureSemantics();
  }

  @override
  void dispose() {
    accessibility?.dispose();
    super.dispose();
  }

  late Future<AppStore> future = AppStore.load();
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '拾光 · 发现生活的美好',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    locale: const Locale('zh', 'CN'),
    supportedLocales: const [Locale('zh', 'CN')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: FutureBuilder<AppStore>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return AppShell(store: snapshot.data!);
        }
        if (snapshot.hasError) {
          return Scaffold(
            body: EmptyState(
              title: '内容暂时没有加载成功',
              subtitle: '请重试，重新载入本地内容。',
              action: FilledButton(
                onPressed: () => setState(() => future = AppStore.load()),
                child: const Text('重新加载'),
              ),
            ),
          );
        }
        return const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '拾光',
                  style: TextStyle(
                    fontSize: 38,
                    color: accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 12),
                Text('发现生活的美好', style: TextStyle(color: muted)),
                SizedBox(height: 28),
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
