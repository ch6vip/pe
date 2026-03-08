<div align="right">
  <a href="README.zh-CN.md">🇨🇳 简体中文</a>
</div>

# PE Reader

[![Flutter](https://img.shields.io/badge/Flutter-3.19%2B-blue?logo=flutter)](https://flutter.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CI](https://github.com/ch6vip/pe/actions/workflows/ci.yml/badge.svg)](https://github.com/ch6vip/pe/actions)
[![GitHub stars](https://img.shields.io/github/stars/ch6vip/pe?style=social)](https://github.com/ch6vip/pe/stargazers)

A cross-platform open-source novel reader built with Flutter, compatible with Legado book source format.

[简体中文](./README.zh-CN.md) | [English](./README.md)

---

## 📸 Screenshots

<div align="center">
  <img src="screenshots/search.png" width="200" alt="Search Screen"/>
  <img src="screenshots/bookshelf.png" width="200" alt="Bookshelf Screen"/>
  <img src="screenshots/reader.png" width="200" alt="Reader Screen"/>
</div>

---

## ✨ Features

- **Cross-platform**: Android, iOS, Windows, macOS, Linux, Web
- **Legado Compatible**: Full support for Legado book source format
- **Rule Engine**: Powerful JSON/HTML parsing with caching
- **Modern UI**: Material Design 3 with smooth animations
- **Offline-first**: Local storage with progress tracking
- **Image Caching**: Smart caching for book covers
- **Search**: Debounced search input for better performance
- **Code Quality**: Strict linting, comprehensive error handling

---

## 🚀 Quick Start

### Prerequisites

- Flutter SDK >= 3.19.0
- Dart SDK >= 3.4.3

### Installation

```bash
# Clone the repository
git clone https://github.com/ch6vip/pe.git
cd pe

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Build APK

```bash
flutter build apk --release
```

The APK will be available at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants
│   ├── errors/         # Exception hierarchy
│   ├── logger/         # Structured logging
│   ├── network/        # Dio HTTP client
│   ├── storage/        # Preferences wrapper
│   └── utils/          # Debouncer, etc.
├── models/             # Data models
├── services/           # Business logic
├── ui/
│   ├── screens/        # Pages
│   └── widgets/        # Reusable components
└── controllers/        # State management
```

---

## 🔧 Configuration

### Add Book Sources

1. Open the app
2. Go to **Settings** → **Source Management**
3. Add a source URL (Legado format)
4. Start searching for books!

### Customize Reading Experience

- Font size: 8-36px
- Line height: 1.0-3.0
- Margins: 0-32px
- Multiple themes (light, dark, sepia, green)

---

## 🧪 Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- [Legado](https://github.com/gedoor/legado) - Book source format specification
- [Flutter](https://flutter.dev) - UI framework
- [Dio](https://github.com/cfug/dio) - HTTP client
- [Logger](https://github.com/SalathielGenese/logger) - Logging package

---

## 🔗 Links

- [GitHub Repository](https://github.com/ch6vip/pe)
- [Issue Tracker](https://github.com/ch6vip/pe/issues)
- [CI/CD Pipeline](https://github.com/ch6vip/pe/actions)

---

**Made with ❤️ by ch6vip**
