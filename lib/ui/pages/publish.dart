import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../theme.dart';
import '../widgets/keyboard_bar.dart';

class PublishPage extends StatefulWidget {
  const PublishPage({super.key, required this.store});
  final AppStore store;
  @override
  State<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends State<PublishPage> {
  final title = TextEditingController(),
      body = TextEditingController(),
      tags = TextEditingController();
  final form = GlobalKey<FormState>();
  final titleFocus = FocusNode(), bodyFocus = FocusNode();
  List<String> images = [];
  String category = '生活';
  bool busy = false;
  bool canPop = false;
  bool leaving = false;
  void finish([bool? result]) {
    setState(() => canPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, result);
    });
  }

  @override
  void initState() {
    super.initState();
    final d = widget.store.draft;
    if (d != null) {
      title.text = d['title'] as String? ?? '';
      body.text = d['body'] as String? ?? '';
      tags.text = d['tags'] as String? ?? '';
      images = List<String>.from(d['images'] as List? ?? []);
      category = d['category'] as String? ?? '生活';
    }
  }

  @override
  void dispose() {
    title.dispose();
    body.dispose();
    tags.dispose();
    titleFocus.dispose();
    bodyFocus.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      final files = await ImagePicker().pickMultiImage(
        maxWidth: 1400,
        maxHeight: 1600,
        imageQuality: 80,
        limit: 9,
      );
      final chosen = <String>[];
      for (final f in files.take(9 - images.length)) {
        final bytes = await f.readAsBytes();
        if (bytes.length > 1500000) {
          if (mounted) toast(context, '单张图片请小于 1.5 MB');
          continue;
        }
        chosen.add('data:image/jpeg;base64,${base64Encode(bytes)}');
      }
      if (mounted) setState(() => images.addAll(chosen));
    } catch (_) {
      if (mounted) toast(context, '暂时无法读取相册，请检查相册权限后重试。');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> saveDraft() async {
    if (busy) return;
    setState(() => busy = true);
    await widget.store.saveDraft({
      'title': title.text,
      'body': body.text,
      'tags': tags.text,
      'images': images,
      'category': category,
    });
    if (!mounted) return;
    setState(() => busy = false);
    toast(context, widget.store.storageError ?? '草稿已保存，下次发布可继续编辑');
  }

  Future<void> publish() async {
    if (busy) return;
    if (!form.currentState!.validate()) {
      titleFocus.requestFocus();
      return;
    }
    FocusScope.of(context).unfocus();
    if (images.isEmpty) {
      toast(context, '先为这篇笔记添加一张图片吧');
      return;
    }
    setState(() => busy = true);
    final note = Note(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      title: title.text.trim(),
      body: body.text.trim(),
      category: category,
      author: widget.store.nickname,
      authorId: 'me',
      avatar: widget.store.avatar,
      location: '本地',
      date: DateTime.now().toIso8601String(),
      tags: tags.text
          .split(RegExp(r'[#，,\s]+'))
          .where((t) => t.isNotEmpty)
          .take(8)
          .toList(),
      images: List.of(images),
    );
    await widget.store.publish(note);
    if (!mounted) return;
    if (widget.store.storageError != null) {
      setState(() => busy = false);
      toast(context, widget.store.storageError!);
    } else {
      finish(true);
    }
  }

  Future<void> leave() async {
    if (busy || leaving || canPop) return;
    if (title.text.isEmpty &&
        body.text.isEmpty &&
        tags.text.isEmpty &&
        images.isEmpty) {
      finish();
      return;
    }
    leaving = true;
    FocusScope.of(context).unfocus();
    final choice = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('把灵感留在草稿里？'),
        content: const Text('保存后，下次打开发布页面可以继续编辑。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, 'discard'),
            child: const Text('放弃编辑'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, 'stay'),
            child: const Text('继续编辑'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, 'save'),
            child: const Text('保存草稿'),
          ),
        ],
      ),
    );
    leaving = false;
    if (!mounted) return;
    if (choice == 'save') {
      await saveDraft();
      if (mounted && widget.store.storageError == null) finish();
    } else if (choice == 'discard') {
      finish();
    }
  }

  @override
  Widget build(BuildContext context) => PopScope<bool>(
    canPop: canPop,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) leave();
    },
    child: Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: '关闭编辑',
          onPressed: busy ? null : leave,
          icon: const Icon(CupertinoIcons.xmark, size: 22),
        ),
        title: const Text('记录这一刻'),
        actions: [
          TextButton(
            onPressed: busy ? null : saveDraft,
            child: const Text('存草稿'),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Form(
            key: form,
            child: ListView(
              key: const ValueKey('publish-form-scroll'),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(24),
              children: [
                const Text(
                  '每一份日常，都值得被看见。',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    ...images.asMap().entries.map(
                      (e) => SizedBox(
                        width: 100,
                        height: 128,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: AppImage(e.value),
                            ),
                            if (e.key == 0)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  color: Colors.black38,
                                  child: const Text(
                                    '封面',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: IconButton(
                                tooltip: '删除图片',
                                onPressed: busy
                                    ? null
                                    : () => setState(
                                        () => images.removeAt(e.key),
                                      ),
                                icon: const Icon(
                                  CupertinoIcons.xmark_circle_fill,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (images.length < 9)
                      InkWell(
                        onTap: busy ? null : pick,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 100,
                          height: 128,
                          decoration: BoxDecoration(
                            color: canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE6E6E8)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (busy)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                const Icon(
                                  CupertinoIcons.plus,
                                  size: 28,
                                  color: muted,
                                ),
                              const SizedBox(height: 8),
                              Text(
                                '添加图片 ${images.length}/9',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),
                if (images.isEmpty) ...[
                  const Text(
                    '也可以先选一张灵感封面',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: 6,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (c, i) {
                        final source = widget
                            .store
                            .seedNotes[[8, 2, 0, 9, 3, 14][i]]
                            .images
                            .first;
                        return InkWell(
                          onTap: busy
                              ? null
                              : () => setState(() => images.add(source)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: AppImage(source, width: 70, height: 70),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                TextFormField(
                  key: const ValueKey('publish-title'),
                  controller: title,
                  focusNode: titleFocus,
                  readOnly: busy,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) => bodyFocus.requestFocus(),
                  maxLength: 30,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    hintText: '给这份日常起个标题',
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                  validator: (v) => (v ?? '').trim().isEmpty ? '请输入笔记标题' : null,
                ),
                TextFormField(
                  key: const ValueKey('publish-body'),
                  controller: body,
                  focusNode: bodyFocus,
                  readOnly: busy,
                  textInputAction: TextInputAction.newline,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 2000,
                  decoration: const InputDecoration(
                    hintText: '分享你的故事、感受，或是一个小小的发现…',
                    filled: false,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                const Divider(),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('publish-tags'),
                  controller: tags,
                  readOnly: busy,
                  textInputAction: TextInputAction.done,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    hintText: '添加话题，用空格分隔',
                    prefixIcon: Icon(CupertinoIcons.number, size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.square_grid_2x2,
                      size: 19,
                      color: muted,
                    ),
                    const SizedBox(width: 10),
                    const Text('选择频道'),
                    const Spacer(),
                    DropdownButton<String>(
                      value: category,
                      underline: const SizedBox(),
                      items: categories
                          .where((c) => c != '推荐')
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: busy
                          ? null
                          : (c) => setState(() => category = c!),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: KeyboardBar(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 712,
                child: FilledButton(
                  key: const ValueKey('publish-submit'),
                  onPressed: busy ? null : publish,
                  child: Text(busy ? '正在保存…' : '发布笔记'),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '本地体验：笔记将保存在当前设备中',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
