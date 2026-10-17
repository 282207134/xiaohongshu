import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import 'theme.dart';
import 'pages/discover.dart';
import 'pages/shop.dart';
import 'pages/messages.dart';
import 'pages/profile.dart';
import 'pages/publish.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.store});
  final AppStore store;
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  String? shownError;
  static const labels = ['发现', '购物', '消息', '我'];
  static const icons = [
    CupertinoIcons.compass,
    CupertinoIcons.bag,
    CupertinoIcons.chat_bubble_2,
    CupertinoIcons.person_crop_circle,
  ];
  static const activeIcons = [
    CupertinoIcons.compass_fill,
    CupertinoIcons.bag_fill,
    CupertinoIcons.chat_bubble_2_fill,
    CupertinoIcons.person_crop_circle_fill,
  ];
  Future<void> publish() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => PublishPage(store: widget.store)),
    );
    if (result == true && mounted) {
      setState(() => index = 0);
      toast(context, '笔记发布成功，已加入首页与个人主页');
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (context, _) {
      final s = widget.store;
      if (s.storageError != null && s.storageError != shownError) {
        shownError = s.storageError;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) toast(context, shownError!);
        });
      }
      final wide = MediaQuery.sizeOf(context).width >= 900;
      final content = IndexedStack(
        index: index,
        children: [
          DiscoverPage(store: s),
          ShopPage(store: s),
          MessagesPage(store: s),
          ProfilePage(store: s),
        ],
      );
      return Scaffold(
        body: SafeArea(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Container(
                  width: 210,
                  padding: const EdgeInsets.fromLTRB(22, 32, 22, 20),
                  decoration: const BoxDecoration(
                    border: Border(right: BorderSide(color: Color(0xFFF0F0F2))),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          '拾光',
                          style: TextStyle(
                            fontSize: 36,
                            color: accent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -2,
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 16, top: 5),
                        child: Text(
                          '让日常，发着光',
                          style: TextStyle(
                            color: muted,
                            fontSize: 11,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 46),
                      ...List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => setState(() => index = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: index == i ? canvas : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    index == i ? activeIcons[i] : icons[i],
                                    size: 24,
                                    color: index == i ? ink : muted,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    labels[i],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: index == i
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: index == i ? ink : muted,
                                    ),
                                  ),
                                  if (i == 2 && !s.readChats.contains('1')) ...[
                                    const Spacer(),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: publish,
                          icon: const Icon(CupertinoIcons.plus, size: 20),
                          label: const Text('发布笔记'),
                        ),
                      ),
                      const Spacer(),
                      const Padding(
                        padding: EdgeInsets.only(left: 16),
                        child: Text(
                          '生活的美好\n从一次分享开始',
                          style: TextStyle(
                            color: muted,
                            fontSize: 12,
                            height: 1.8,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Divider(),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () => setState(() => index = 3),
                        child: Row(
                          children: [
                            Avatar(s.avatar, size: 34),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                s.nickname,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const Icon(
                              CupertinoIcons.chevron_right,
                              size: 13,
                              color: muted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(child: content),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : SafeArea(
                child: Container(
                  height: 66,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Color(0xFFF0F0F2))),
                  ),
                  child: Row(
                    children: [
                      nav(0),
                      nav(1),
                      Expanded(
                        child: Center(
                          child: Semantics(
                            label: '发布笔记',
                            button: true,
                            child: InkWell(
                              onTap: publish,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 46,
                                height: 35,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: const Icon(
                                  CupertinoIcons.plus,
                                  color: Colors.white,
                                  size: 27,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      nav(2),
                      nav(3),
                    ],
                  ),
                ),
              ),
      );
    },
  );
  Widget nav(int i) => Expanded(
    child: Semantics(
      selected: index == i,
      button: true,
      label: labels[i],
      child: InkWell(
        onTap: () => setState(() => index = i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              index == i ? activeIcons[i] : icons[i],
              size: 23,
              color: index == i ? ink : muted,
            ),
            const SizedBox(height: 4),
            Text(
              labels[i],
              style: TextStyle(
                fontSize: 10,
                color: index == i ? ink : muted,
                fontWeight: index == i ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
