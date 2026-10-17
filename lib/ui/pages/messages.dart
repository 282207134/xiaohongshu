import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../theme.dart';

const chatNames = ['拾光小助手', '小小风筝', '慢慢', '生活灵感交换站'];
const chatPreviews = [
  '欢迎来到拾光，发现生活的小美好。',
  '周末一起去发现春天吧！',
  '谢谢你喜欢我的摄影笔记。',
  '今天也有认真记录生活呀。',
];
const chatAvatars = [
  'assets/images/avatar_avatar_01.png',
  'assets/images/avatar_avatar_03.png',
  'assets/images/avatar_avatar_05.png',
  'assets/images/avatar_avatar_09.png',
];

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key, required this.store});
  final AppStore store;
  void notifications(BuildContext context, int i) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: Text(['赞和收藏', '新增关注', '评论和@'][i])),
        body: const EmptyState(
          title: '暂时没有新的互动',
          subtitle: '分享一篇日常，让喜欢与你相遇。',
          icon: CupertinoIcons.bell,
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(26, 24, 24, 16),
        child: Row(
          children: [
            const Text(
              '消息',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                for (var i = 0; i < 4; i++) {
                  store.markRead('$i');
                }
                toast(context, '消息已全部标记为已读');
              },
              icon: const Icon(
                CupertinoIcons.checkmark_alt,
                size: 17,
                color: muted,
              ),
              label: const Text(
                '全部已读',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
        child: Row(
          children: List.generate(
            3,
            (i) => Expanded(
              child: InkWell(
                onTap: () => notifications(context, i),
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: [
                          const Color(0xFFFFEEF1),
                          const Color(0xFFEEF3FF),
                          const Color(0xFFECF8F3),
                        ][i],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        [
                          CupertinoIcons.heart_fill,
                          CupertinoIcons.person_fill,
                          CupertinoIcons.chat_bubble_text_fill,
                        ][i],
                        color: [
                          accent,
                          const Color(0xFF5883D8),
                          const Color(0xFF51AB84),
                        ][i],
                        size: 27,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ['赞和收藏', '新增关注', '评论和@'][i],
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            Text('最近聊天', style: TextStyle(fontSize: 13, color: muted)),
            Spacer(),
            Text('示例会话', style: TextStyle(fontSize: 11, color: muted)),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Expanded(
        child: ListView.separated(
          itemCount: 4,
          separatorBuilder: (_, _) => const SizedBox(height: 6),
          itemBuilder: (c, i) {
            final sent = store.sentMessages['$i'];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 10,
              ),
              onTap: () {
                store.markRead('$i');
                Navigator.push(
                  c,
                  MaterialPageRoute<void>(
                    builder: (_) => ChatPage(store: store, index: i),
                  ),
                );
              },
              leading: Badge(
                isLabelVisible: i < 2 && !store.readChats.contains('$i'),
                smallSize: 8,
                child: Avatar(chatAvatars[i], size: 50),
              ),
              title: Text(
                chatNames[i],
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Text(
                  sent != null && sent.isNotEmpty
                      ? '我：${sent.last}'
                      : chatPreviews[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
              ),
              trailing: Text(
                sent != null && sent.isNotEmpty
                    ? '刚刚'
                    : ['09:41', '昨天', '星期三', '星期二'][i],
                style: const TextStyle(color: muted, fontSize: 10),
              ),
            );
          },
        ),
      ),
    ],
  );
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, required this.store, required this.index});
  final AppStore store;
  final int index;
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController(), scroll = ScrollController();
  bool sending = false;
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  Future<void> send() async {
    final text = input.text;
    if (text.trim().isEmpty || sending) return;
    setState(() => sending = true);
    await widget.store.send('${widget.index}', text);
    if (mounted) {
      if (widget.store.storageError == null && input.text == text) {
        input.clear();
      }
      setState(() => sending = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && scroll.hasClients) {
          scroll.animateTo(
            scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.store,
    builder: (c, _) {
      final i = widget.index;
      final messages = widget.store.sentMessages['$i'] ?? [];
      return Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(title: Text(chatNames[i])),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    '本地示例会话 · 发送内容仅保存在当前设备',
                    style: TextStyle(fontSize: 11, color: muted),
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    padding: const EdgeInsets.all(20),
                    children: [
                      bubble(chatPreviews[i], false),
                      if (i == 0)
                        bubble(
                          '你可以浏览笔记、收藏灵感，也可以发布属于你的日常。愿每一份小美好，都被认真看见。',
                          false,
                        ),
                      ...messages.map((m) => bubble(m, true)),
                    ],
                  ),
                ),
                SafeArea(
                  child: Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const ValueKey('chat-message'),
                            controller: input,
                            maxLength: 500,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => send(),
                            decoration: const InputDecoration(
                              hintText: '分享一句今天的心情…',
                              isDense: true,
                              counterText: '',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: sending ? null : send,
                          child: const Text('发送'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
  Widget bubble(String text, bool mine) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Row(
      mainAxisAlignment: mine ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!mine) ...[
          Avatar(chatAvatars[widget.index], size: 34),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: mine ? const Color(0xFFFFE9EF) : Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.7),
            ),
          ),
        ),
        if (mine) ...[
          const SizedBox(width: 10),
          Avatar(widget.store.avatar, size: 34),
        ],
      ],
    ),
  );
}
