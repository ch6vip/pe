# PE Reader

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/ch6vip/pe/actions/workflows/ci.yml/badge.svg)](https://github.com/ch6vip/pe/actions)
[![GitHub stars](https://img.shields.io/github/stars/ch6vip/pe?style=social)](https://github.com/ch6vip/pe/stargazers)

一个基于 Flutter 的跨平台开源小说阅读器，兼容 Legado 书源格式。

[English](./README.md) | [简体中文](./README.zh-CN.md)

---

## 📸 应用截图

<div align="center">
  <img src="screenshots/search.png" width="200" alt="搜索页面"/>
  <img src="screenshots/bookshelf.png" width="200" alt="书架页面"/>
  <img src="screenshots/reader.png" width="200" alt="阅读页面"/>
</div>

---

## ✨ 特性

- **跨平台支持**: Android, iOS, Windows, macOS, Linux, Web
- **Legado 兼容**: 完整支持 Legado 书源格式
- **规则引擎**: 强大的 JSON/HTML 解析，带缓存机制
- **现代 UI**: Material Design 3，流畅动画
- **离线优先**: 本地存储，阅读进度跟踪
- **图片缓存**: 智能缓存封面图片
- **搜索优化**: 防抖输入，性能更佳
- **代码质量**: 严格 lint，全面错误处理

---

## 🚀 快速开始

### 环境要求

- Flutter SDK >= 3.19.0
- Dart SDK >= 3.4.3

### 安装步骤

```bash
# 克隆仓库
git clone https://github.com/ch6vip/pe.git
cd pe

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 构建 APK

```bash
flutter build apk --release
```

APK 文件位于：`build/app/outputs/flutter-apk/app-release.apk`

---

## 🏗️ 项目结构

```
lib/
├── core/
│   ├── constants/      # 应用常量
│   ├── errors/         # 异常体系
│   ├── logger/         # 结构化日志
│   ├── network/        # Dio HTTP 客户端
│   ├── storage/        # Preferences 封装
│   └── utils/          # 防抖器等工具
├── models/             # 数据模型
├── services/           # 业务逻辑
├── ui/
│   ├── screens/        # 页面
│   └── widgets/        # 可复用组件
└── controllers/        # 状态管理
```

---

## 🔧 使用说明

### 添加书源

1. 打开应用
2. 进入 **设置** → **书源管理**
3. 添加书源 URL（Legado 格式）
4. 开始搜索书籍！

### 自定义阅读体验

- 字体大小：8-36px
- 行高：1.0-3.0
- 页边距：0-32px
- 多种主题（明亮、暗黑、复古、护眼）

---

## 🧪 测试

```bash
# 运行所有测试
flutter test

# 运行并生成覆盖率报告
flutter test --coverage

# 查看覆盖率报告
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🤝 贡献指南

欢迎贡献！请随时提交 Pull Request。

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 打开 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

## 🙏 致谢

- [Legado](https://github.com/gedoor/legado) - 书源格式规范
- [Flutter](https://flutter.dev) - UI 框架
- [Dio](https://github.com/cfug/dio) - HTTP 客户端
- [Logger](https://github.com/SalathielGenese/logger) - 日志包

---

## 🔗 相关链接

- [GitHub 仓库](https://github.com/ch6vip/pe)
- [问题追踪](https://github.com/ch6vip/pe/issues)
- [CI/CD 流水线](https://github.com/ch6vip/pe/actions)

---

**由 ❤️ 精心打造**
