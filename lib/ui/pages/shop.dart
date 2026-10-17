import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../../data/app_store.dart';
import '../../data/models.dart';
import '../theme.dart';

String money(double v) =>
    v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

class ShopPage extends StatefulWidget {
  const ShopPage({super.key, required this.store});
  final AppStore store;
  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  String query = '', category = '全部';
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void bag() => Navigator.push(
    context,
    MaterialPageRoute<void>(builder: (_) => CartPage(store: widget.store)),
  );
  void detail(Product p) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(c).height * .85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: AppImage(p.image, fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                '¥ ${money(p.price)}',
                style: const TextStyle(
                  color: accent,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                p.title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '精选生活好物 · 参考资料中的示例商品',
                style: TextStyle(color: muted, fontSize: 12),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    widget.store.addToCart(p);
                    Navigator.pop(c);
                    toast(context, '已加入购物袋');
                  },
                  icon: const Icon(CupertinoIcons.bag_badge_plus, size: 20),
                  label: const Text('加入购物袋'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final list = s.products
        .where(
          (p) =>
              (query.isEmpty || p.title.contains(query)) &&
              (category == '全部' ||
                  (category == '美味食光'
                      ? ![3, 4, 5, 6, 11, 15, 16, 20].contains(p.id)
                      : [3, 4, 5, 6, 11, 15, 16, 20].contains(p.id))),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            wide ? 28 : 16,
            wide ? 26 : 14,
            wide ? 28 : 16,
            16,
          ),
          child: Row(
            children: [
              const Text(
                '好物商店',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                onPressed: bag,
                tooltip: '购物袋',
                icon: Badge(
                  isLabelVisible: s.cartCount > 0,
                  label: Text('${s.cartCount}'),
                  child: const Icon(CupertinoIcons.bag, size: 24),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: search,
            onChanged: (v) => setState(() => query = v.trim()),
            decoration: InputDecoration(
              hintText: '寻找让生活更好的小物',
              prefixIcon: const Icon(CupertinoIcons.search, size: 18),
              isDense: true,
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: '清空商品搜索',
                      onPressed: () {
                        search.clear();
                        setState(() => query = '');
                      },
                      icon: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 17,
                        color: muted,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: 3,
            separatorBuilder: (_, _) => const SizedBox(width: 28),
            itemBuilder: (c, i) {
              final label = ['全部', '美味食光', '生活好物'][i];
              final image = s.products[[19, 6, 2][i]].image;
              return InkWell(
                onTap: () => setState(() => category = label),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: canvas,
                        border: Border.all(
                          color: category == label
                              ? accent
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: ClipOval(child: AppImage(image)),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: category == label ? accent : ink,
                        fontWeight: category == label
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                category == '全部' ? '发现心动好物' : category,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Text(
                '好好生活，慢慢挑选',
                style: TextStyle(fontSize: 11, color: muted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: list.isEmpty
              ? const EmptyState(
                  title: '还没有找到这件好物',
                  subtitle: '换个关键词试试看。',
                  icon: CupertinoIcons.bag,
                )
              : LayoutBuilder(
                  builder: (c, b) => MasonryGridView.count(
                    crossAxisCount: b.maxWidth > 1000
                        ? 4
                        : b.maxWidth > 650
                        ? 3
                        : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    itemCount: list.length,
                    itemBuilder: (c, i) {
                      final p = list[i];
                      return InkWell(
                        onTap: () => detail(p),
                        borderRadius: BorderRadius.circular(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: AppImage(p.image),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Text(
                                p.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 3,
                              ),
                              child: Text(
                                '¥ ${money(p.price)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: accent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class CartPage extends StatelessWidget {
  const CartPage({super.key, required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: store,
    builder: (context, _) {
      final items = store.products
          .where((p) => store.cart.containsKey(p.id))
          .toList();
      return Scaffold(
        appBar: AppBar(title: Text('购物袋（${store.cartCount}）')),
        body: items.isEmpty
            ? EmptyState(
                title: '购物袋还是空的',
                subtitle: '挑一件喜欢的好物，让日常多一点期待。',
                icon: CupertinoIcons.bag,
                action: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('去逛逛'),
                ),
              )
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const Divider(height: 32),
                    itemBuilder: (c, i) {
                      final p = items[i];
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: AppImage(p.image, width: 90, height: 100),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  '¥ ${money(p.price)}',
                                  style: const TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: '减少数量',
                                      onPressed: () =>
                                          store.changeQuantity(p, -1),
                                      icon: const Icon(
                                        CupertinoIcons.minus_circle,
                                        size: 22,
                                      ),
                                    ),
                                    Text('${store.cart[p.id]}'),
                                    IconButton(
                                      tooltip: '增加数量',
                                      onPressed: () =>
                                          store.changeQuantity(p, 1),
                                      icon: const Icon(
                                        CupertinoIcons.plus_circle,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
        bottomNavigationBar: items.isEmpty
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('合计'),
                          const Spacer(),
                          Text(
                            '¥ ${store.cartTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 24,
                              color: accent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '演示购物袋，暂不支持下单和支付',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
      );
    },
  );
}
