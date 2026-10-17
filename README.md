# 拾光 · Flutter 生活方式社区

参考用户提供的小红书教学资料，使用 Flutter 独立实现的可交互首版。支持 Android、iOS 工程和 Web 预览，手机端双列瀑布流，大屏使用侧栏和多列布局。

## 已有功能

- 发现：首页瀑布流、频道筛选、关注流、按资料中的地区筛选、下拉刷新。
- 搜索：标题、正文、作者、话题检索，最近搜索与无结果提示。
- 详情：多图滑动与按钮切换、点赞、收藏、关注、评论、复制笔记内容。
- 发布：选择相册图片或灵感封面、标题与正文、话题与频道、草稿保存与恢复、退出编辑提示。
- 购物：20 件示例商品、分类与搜索、商品详情、购物袋增减和合计。
- 消息：示例会话、已读状态、本地发送记录、通知空状态。
- 我的：编辑昵称和简介、已发布笔记、收藏、赞过、关注列表和草稿入口。
- 本地保存：重启后恢复互动、笔记、评论、搜索历史、购物袋、资料和示例聊天。

## 运行

本次开发环境为 Flutter 3.47.7 / Dart 3.13.5。依赖已锁定在 `pubspec.lock`。

```powershell
cd C:\Users\liuyu\Desktop\xiaohongshu
flutter pub get
flutter run -d chrome
```

Android 手机通过 USB 连接并开启调试后，运行 `flutter devices` 确认设备，再运行 `flutter run -d <设备ID>`。当前已完成 Android 15（API 35）x86_64 模拟器构建、安装和端到端测试；Android 真机尚未验证。

iOS 工程需要在 macOS 上使用 Xcode 构建、配置签名并验证相册权限。当前已添加相册访问用途说明，尚未进行 iOS 真机验证。

## 验证与构建

```powershell
flutter analyze
flutter test --concurrency=1
flutter build web --no-wasm-dry-run --output=build/web
```

网页构建可在本地预览：

```powershell
python -m http.server 5173 --bind 127.0.0.1 --directory build/web
```

随后打开 `http://127.0.0.1:5173`。保持使用同一浏览器与端口，才能读到该预览来源的本地记录。
首次 Web 加载可能需要联网获取 Flutter 渲染组件与中文字体。

Android 调试安装包可以通过 `flutter build apk --debug` 构建。本次已验证 `--target-platform android-x64` 的模拟器安装包，保存在 `artifacts/android/shiguang-emulator-debug.apk`，该包用于 x86_64 模拟器。普通 ARM 手机需要重新构建匹配的安装包。

## Android 模拟器端到端测试

先使用 `flutter emulators` 查看已配置的模拟器，启动后通过 `flutter devices` 取得模拟器设备 ID。

```powershell
flutter emulators --launch flutter_emulator
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5556
```

设备 ID 以本机实际返回的结果为准。测试会在目标模拟器中创建测试笔记、草稿、收藏、购物袋及示例聊天记录；应选择用于开发测试的模拟器。脚本在测试结束时恢复原有本地记录，截图保存在 `docs/screenshots/android/`。已验证的具体结果见 [Android 模拟器测试](docs/Android模拟器测试.md)。

## 工程结构

```text
lib/
  main.dart                 启动、中文本地化、加载与错误状态
  data/
    models.dart             笔记、评论、商品模型
    app_store.dart          数据加载、筛选、交互与本地持久化
  ui/
    shell.dart              手机底部导航与大屏侧栏
    theme.dart              颜色、字体、图片与通用状态
    pages/                  发现、搜索、详情、发布、购物、消息、我的
    widgets/note_grid.dart  自适应瀑布流与笔记卡片
assets/
  notes.json                15 篇参考笔记与评论
  products.json             20 件参考商品
  images/                   导入的本地图片与头像
test/                       数据持久化与多尺寸页面测试
docs/参考资料与后续开发.md   资料映射、边界与后续接入顺序
```

## 当前边界

这是可运行的本地 MVP。尚未接入真实账号认证、远程发布、推荐服务、对象存储、消息投递、订单或支付。所有“发布”和“发送”都仅保存到当前设备；示例会话页面已明确说明。

SharedPreferences 用来演示小规模本地保存。相册单图限制为 1.5 MB，最多 9 张；多篇大图笔记可能达到浏览器存储配额，界面会提示保存失败。正式版本应把图片移至文件系统或对象存储，记录移至数据库，不能依赖此演示存储方案承载大量内容。清除应用数据或浏览器站点数据会移除本地记录。

详细的参考范围、服务端接入和上线准备见 [参考资料与后续开发](docs/参考资料与后续开发.md)。

本轮输入框修复、11 项测试及 Android 完整流程验证见 [功能回归与输入修复](docs/功能回归与输入修复.md)。Windows 测试引擎并发运行出现过意外退出，建议使用上述串行测试命令。
