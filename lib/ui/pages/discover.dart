import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../data/app_store.dart';
import '../theme.dart';
import '../widgets/note_grid.dart';
import 'search.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key, required this.store});
  final AppStore store;
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  String category = '推荐', location = '广东';
  int channel = 1;
  final searchController = TextEditingController();
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void search([String query = '']) {
    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SearchPage(store: widget.store, initialQuery: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 900;
    var notes = widget.store.filter(
      category: category,
      following: channel == 0,
    );
    if (channel == 2) {
      notes = notes.where((n) => n.location == location).toList();
    }
    if (channel == 1 && category == '推荐') {
      const order = [
        '9',
        '1',
        '3',
        '10',
        '2',
        '15',
        '4',
        '6',
        '13',
        '5',
        '11',
        '12',
        '7',
        '14',
        '8',
      ];
      notes.sort((a, b) {
        if (a.authorId == 'me') return -1;
        if (b.authorId == 'me') return 1;
        return order.indexOf(a.id).compareTo(order.indexOf(b.id));
      });
    }
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 30 : 12,
            wide ? 24 : 10,
            wide ? 30 : 12,
            12,
          ),
          child: Row(
            children: [
              if (!wide)
                const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Text(
                    '拾光',
                    style: TextStyle(
                      color: accent,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                ),
              ...['关注', '发现', '同城'].asMap().entries.map(
                (e) => Padding(
                  padding: EdgeInsets.only(right: wide ? 30 : 20),
                  child: InkWell(
                    onTap: () => setState(() => channel = e.key),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.value,
                          style: TextStyle(
                            fontSize: wide ? 21 : 17,
                            fontWeight: channel == e.key
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: channel == e.key ? ink : muted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: 3,
                          width: 22,
                          decoration: BoxDecoration(
                            color: channel == e.key
                                ? accent
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              if (wide)
                SizedBox(
                  width: 260,
                  child: TextField(
                    key: const ValueKey('discover-search'),
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: search,
                    decoration: InputDecoration(
                      hintText: '搜索你感兴趣的生活',
                      suffixIcon: IconButton(
                        tooltip: '搜索笔记',
                        onPressed: () => search(searchController.text),
                        icon: const Icon(CupertinoIcons.search, size: 19),
                      ),
                      isDense: true,
                    ),
                  ),
                )
              else
                IconButton(
                  onPressed: () => search(),
                  tooltip: '搜索笔记',
                  icon: const Icon(CupertinoIcons.search, size: 24),
                ),
            ],
          ),
        ),
        if (channel == 2)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              children: [
                const Icon(CupertinoIcons.location, size: 16, color: accent),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: location,
                  underline: const SizedBox(),
                  items: widget.store.seedNotes
                      .map((n) => n.location)
                      .toSet()
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  onChanged: (v) => setState(() => location = v!),
                ),
                const SizedBox(width: 8),
                const Text(
                  '发现身边的分享',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
              ],
            ),
          ),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: wide ? 28 : 12),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final c = categories[i];
              return Align(
                child: Semantics(
                  button: true,
                  selected: category == c,
                  child: InkWell(
                    onTap: () => setState(() => category = c),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: category == c ? canvas : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.2,
                          color: category == c ? ink : muted,
                          fontWeight: category == c
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: notes.isEmpty
              ? EmptyState(
                  title: channel == 0 ? '关注，让喜欢的生活更近一点' : '这里还没有笔记',
                  subtitle: channel == 0
                      ? '在笔记详情中关注创作者，分享就会出现在这里。'
                      : '换个频道，发现更多有趣的分享。',
                  icon: CupertinoIcons.square_grid_2x2,
                  action: TextButton(
                    onPressed: () => setState(() {
                      channel = 1;
                      category = '推荐';
                    }),
                    child: const Text('去发现'),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await Future<void>.delayed(
                      const Duration(milliseconds: 450),
                    );
                    if (context.mounted) {
                      toast(context, '已是最新内容');
                    }
                  },
                  child: NoteGrid(notes: notes, store: widget.store),
                ),
        ),
      ],
    );
  }
}
