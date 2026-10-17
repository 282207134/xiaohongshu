# Android 模拟器测试

日期：2026-10-17。测试已通过，应用保留在模拟器中可继续体验。

## 环境

- 模拟器：`flutter_emulator`，设备 ID `emulator-5556`。
- 系统：Android 15，API 35，x86_64。
- 屏幕：1080 × 1920，420 dpi。
- 工具链：Flutter 3.47.7 / Dart 3.13.5。
- 安装包：Debug，应用标识 `com.example.life_notes`。

## 结果

| 场景 | 结果 | 证据 |
| --- | --- | --- |
| 原生构建、安装和启动 | 通过，正常显示双列瀑布流 | [首页](screenshots/android/00-native-home.png) |
| 详情、点赞与收藏 | 通过，重新加载数据后状态保留 | [详情](screenshots/android/02-note-detail.png) |
| 个人主页收藏列表 | 通过，显示已收藏笔记 | [收藏](screenshots/android/03-profile-saved.png) |
| 中文搜索 | 通过，搜索“猫咪”返回对应笔记 | [搜索](screenshots/android/04-search.png) |
| 标题、正文、封面与草稿 | 通过，保存后重新进入恢复内容 | [草稿](screenshots/android/05-publish-draft.png) |
| 发布笔记 | 通过，首页出现新笔记且数据重新加载后存在 | [发布后首页](screenshots/android/06-published.png) |
| 商品详情与购物袋 | 通过，加入商品、数量与合计正确 | [购物袋](screenshots/android/08-cart.png) |
| 示例聊天 | 通过，中文发送与本地记录保存正常 | [聊天](screenshots/android/09-chat.png) |
| Android 系统相册 | 通过，选择测试图片后返回编辑页并显示封面 | [系统选择器](screenshots/android/10-system-photo-picker.png)、[图片导入](screenshots/android/11-photo-imported.png) |
| 系统返回键 | 通过，未完成笔记弹出保存草稿提示 | [返回保护](screenshots/android/12-system-back-draft.png) |
| 进程关闭后恢复 | 通过，结束进程并重新启动，所选相册图片仍从草稿恢复 | [重启后的草稿](screenshots/android/13-photo-draft-after-restart.png) |

## 实现与复现

新增 `integration_test/app_test.dart` 和 `test_driver/integration_test.dart`。完整端到端场景返回 `All tests passed`。测试结束时恢复运行前的本地记录，使用独立的时间戳标题避免笔记名称冲突。

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d emulator-5556
```

系统相册与进程重启检查在普通应用安装包中补充执行。测试图片来自项目内的参考素材，仅放入开发模拟器。测试没有使用已连接的实体手机，也没有向外部平台发送内容。

本次补充了 `android:enableOnBackInvokedCallback="true"`，并验证系统返回键能够触发发布页草稿保护。已保存当前普通应用的 x86_64 模拟器安装包：`artifacts/android/shiguang-emulator-debug.apk`。

首次原生构建需要准备 Gradle、Android 插件与依赖；这些依赖已缓存。iOS、Android 实体手机、其他系统版本、性能压力、弱网、真实登录、支付和实时消息仍需后续专项验证。
