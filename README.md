# PE Reader / PE 小说阅读器 (Flutter)

## 概览 / Overview

PE Reader 是一款基于 Flutter 的跨平台开源小说阅读器，面向 **读者、开源贡献者与 Flutter 开发者**。本项目强调 **Legado 书源协议兼容** 与 **可复用的规则解析工具链**，并提供一致的 iOS/Android/Desktop 阅读体验。

PE Reader is a cross‑platform open‑source novel reader built with Flutter. It targets **readers, open‑source contributors, and Flutter developers**, with a focus on **Legado source protocol compatibility** and a **reusable rule‑driven toolchain**, delivering consistent UX across iOS/Android/Desktop.

- **包名 / Package**: `com.pereader.app`
- **平台 / Platforms**: Android, iOS, Windows, macOS, Linux, Web

## 社区价值 / Community Value

- **协议兼容**：实现并验证 Legado 书源格式，便于社区复用成熟书源。
- **可复用工具链**：规则解析器与书源管理器可迁移到其他内容聚合类应用。
- **Flutter 参考实现**：展示复杂 UI/UX、离线缓存、多端一致性与状态管理。
- **跨平台一致性**：同一逻辑与规则在移动端/桌面端/网页端表现一致。

- **Protocol compatibility**: Implements and validates the Legado source schema so existing community sources can be reused.
- **Reusable toolchain**: Rule parser and source manager can be adapted for other content aggregation apps.
- **Flutter reference**: Real‑world implementation of complex UI, offline caching, and state management.
- **Cross‑platform parity**: Consistent behavior across mobile, desktop, and web.

## 协议兼容与工具链 / Protocol Compatibility & Toolchain

- **Legado 书源格式**：兼容社区既有书源生态。
- **规则引擎**：支持自定义搜索、书籍详情、目录、正文规则。
- **调试工具**：内置书源调试界面，便于验证规则与定位问题。

- **Legado format support**: Reuse community sources with minimal changes.
- **Rule engine**: Custom rules for search, book details, chapter list, and content.
- **Debug tools**: Built‑in source debugging UI to validate rules and troubleshoot.

调试入口 / Debug entry:
- `lib/ui/screens/source_debug_screen.dart`

## 面向开发者的复用价值 / Developer Reuse Value

- **规则解析器**可独立复用到其他内容抓取场景。
- **书源管理器**可作为插件化内容聚合框架基础。
- **跨平台 UI 架构**提供 Flutter 复杂应用的工程参考。

- **Rule parser** can be reused for other rule‑based scraping use cases.
- **Source manager** can serve as a base for pluggable aggregation frameworks.
- **Cross‑platform UI architecture** is a practical Flutter reference.

## 主要功能 / Key Features

- Legado 兼容书源 / Legado‑compatible sources
- 书名/作者搜索 / Search by title or author
- 阅读样式自定义 / Reader customization (font, spacing, themes)
- 本地书架与进度 / Local bookshelf with progress tracking
- 章节预加载 / Chapter prefetching
- Material Design 3 UI
- Provider 状态管理 / Provider state management

## 隐私与安全 / Privacy & Security

- 无需账号登录 / No account required
- 阅读进度与设置仅存本地 / Data stored locally
- 网络请求仅访问 **用户添加的书源** / Network requests only to **user‑added sources**

## 内容与合规 / Legal & Content Policy

本项目 **不内置书源**，仅提供阅读框架与工具。用户需自行添加书源并遵守相关版权及服务条款。

PE Reader **does not ship with built‑in sources**. It is a framework/tool; users add their own sources and must comply with copyright and terms of service.

## 技术栈 / Tech Stack

| 类别 / Category | 技术 / Tech | 版本 / Version |
|------|------|------|
| 框架 / Framework | Flutter | >= 3.19.0 |
| 语言 / Language | Dart | >= 3.4.3 |
| 状态管理 / State | Provider | ^6.1.5+1 |
| UI | Material Design 3 | - |
| HTTP | http | ^1.2.1 |
| 本地存储 / Local | shared_preferences | ^2.2.3 |
| HTML 解析 | html | ^0.15.4 |
| JSON 路径 | json_path | ^0.7.1 |

## 项目结构 / Project Structure

```
lib/
  models/
    book.dart
    book_source.dart
    chapter.dart
    chapter_content.dart
  services/
    api_service.dart
    app_log_service.dart
    reader_settings_service.dart
    source_manager_service.dart
    storage_service.dart
  controllers/
    reader_controller.dart
  utils/
    rule_parser.dart
  ui/
    screens/
      search_screen.dart
      results_screen.dart
      detail_screen.dart
      bookshelf_screen.dart
      reader_screen.dart
      settings_screen.dart
      source_management_screen.dart
      source_edit_screen.dart
      source_debug_screen.dart
      app_log_screen.dart
    widgets/
      main_scaffold.dart
```

## 快速开始 / Getting Started

### 前置要求 / Prerequisites

- Flutter SDK >= 3.19.0
- Dart SDK >= 3.4.3
- Android Studio or VS Code

### 安装 / Install

```bash
git clone https://github.com/ch6vip/pe.git
cd pe
flutter pub get
```

### 运行 / Run

```bash
flutter run
# or specify a device
flutter run -d <device-id>
```

### 构建 / Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## 贡献 / Contributing

欢迎提交 Issue 和 Pull Request。建议在实现功能前先开 Issue 进行方案对齐。

We welcome issues and pull requests. Please open an issue to align on approach before major work.

## Roadmap / 开发路线图

- 提升桌面端与 Web 端体验一致性 / Improve desktop & web parity
- 完善规则引擎测试与验证工具 / Expand rule engine tests & validation
- 增加无障碍与阅读体验选项 / Add accessibility and reading presets
- 文档与示例书源模板 / Documentation and template sources

## License

MIT License. See `LICENSE`.
