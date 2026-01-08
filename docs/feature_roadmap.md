# 小说阅读器 App 功能迭代方案

> 版本: v1.0  
> 日期: 2026-01-08  
> 目标: 构建完善的设置系统与差异化功能

---

## 1. 功能清单 (Feature List)

| 模块 | 功能项 | 优先级 | 简述 |
|------|--------|--------|------|
| **阅读器个性化** | 字体大小调节 | P0 | 支持 12-30px 字号调节 |
| | 行高调节 | P0 | 支持 1.2-2.5 倍行高 |
| | 自定义字体 | P1 | 支持导入 TTF/OTF 字体文件 |
| | 翻页动画 | P0 | 覆盖/仿真/无动画三种模式 |
| | 背景主题 | P0 | 护眼/羊皮纸/E-ink/夜间模式 |
| | 段落间距 | P1 | 段落间距离调节 |
| | 页边距 | P1 | 左右边距调节 |
| **通用应用设置** | 缓存管理 | P0 | 查看缓存大小、清理缓存 |
| | 预下载策略 | P1 | 预下载章节数量设置 |
| | 数据备份 | P1 | 导出书架数据为 JSON |
| | 数据恢复 | P1 | 从 JSON 恢复书架 |
| | WebDAV 同步 | P2 | 支持 WebDAV 协议同步 |
| | App 锁 | P1 | 指纹/图案锁保护隐私 |
| | 关于页面 | P0 | 版本信息、开源协议 |
| **差异化功能** | TTS 听书 | P1 | 集成系统 TTS 引擎 |
| | 本地导入 | P0 | 支持 EPUB/TXT 文件导入 |
| | 智能换源 | P1 | API 失败时自动切换备用源 |
| | 阅读统计 | P2 | 阅读时长、字数统计 |
| | 书签功能 | P1 | 添加/管理书签 |
| | 笔记功能 | P2 | 章节内添加笔记 |

---

## 2. 设置页 UI 结构建议

### 2.1 整体布局

```
┌─────────────────────────────────────┐
│  ← 设置                    搜索图标  │
├─────────────────────────────────────┤
│                                     │
│  ┌─ 阅读设置 ───────────────────┐  │
│  │  字体大小        [18 ▼]       │  │
│  │  行高            [1.8 ▼]      │  │
│  │  翻页动画        [覆盖 ▼]     │  │
│  │  背景主题        [护眼 ▼]     │  │
│  │  自定义字体      [选择字体 >] │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─ 存储与缓存 ─────────────────┐  │
│  │  缓存大小        128 MB       │  │
│  │  [清理缓存]                  │  │
│  │  预下载章节数    [3 ▼]       │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─ 数据管理 ───────────────────┐  │
│  │  [备份数据]    [恢复数据]    │  │
│  │  WebDAV 同步    [配置 >]     │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─ 隐私与安全 ─────────────────┐  │
│  │  App 锁         [开关]       │  │
│  │  锁定方式      [指纹 ▼]      │  │
│  └───────────────────────────────┘  │
│                                     │
│  ┌─ 关于 ───────────────────────┐  │
│  │  版本号         v1.0.0       │  │
│  │  [检查更新]                  │  │
│  │  开源协议        [查看 >]     │  │
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

### 2.2 交互方式

1. **分组展示**: 使用 `ListView` + `ListTile` 分组，每组有独立标题
2. **滑动调节**: 字体大小、行高等使用 `Slider` 组件
3. **下拉选择**: 翻页动画、主题等使用 `DropdownButton`
4. **开关控件**: App 锁等使用 `Switch` 组件
5. **跳转页面**: 自定义字体、WebDAV 配置等跳转到子页面

### 2.3 主题预览

在设置页顶部添加一个实时预览区域，展示当前设置效果：

```
┌─────────────────────────────────────┐
│  阅读效果预览                        │
│  ┌───────────────────────────────┐  │
│  │  这是一段示例文本，用于预览    │  │
│  │  当前字体大小和主题效果。      │  │
│  │                               │  │
│  │  用户可以实时看到设置变化。    │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

---

## 3. 技术实现概览

### 3.1 阅读器个性化设置

#### 3.1.1 状态管理方案

使用 `Provider` + `ChangeNotifier` 实现全局设置：

```dart
// lib/services/reader_settings_service.dart
class ReaderSettingsService extends ChangeNotifier {
  // 字体大小
  double _fontSize = 18.0;
  double get fontSize => _fontSize;
  
  // 行高
  double _lineHeight = 1.8;
  double get lineHeight => _lineHeight;
  
  // 翻页动画类型
  PageAnimationType _pageAnimation = PageAnimationType.cover;
  PageAnimationType get pageAnimation => _pageAnimation;
  
  // 背景主题
  ReaderTheme _theme = ReaderTheme.eyeProtection;
  ReaderTheme get theme => _theme;
  
  // 自定义字体路径
  String? _customFontPath;
  String? get customFontPath => _customFontPath;
  
  // 更新设置
  void updateFontSize(double value) {
    _fontSize = value;
    notifyListeners();
    _saveSettings();
  }
  
  void updateLineHeight(double value) {
    _lineHeight = value;
    notifyListeners();
    _saveSettings();
  }
  
  // ... 其他更新方法
  
  // 持久化到 SharedPreferences
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('fontSize', _fontSize);
    await prefs.setDouble('lineHeight', _lineHeight);
    // ...
  }
  
  // 从 SharedPreferences 加载
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _fontSize = prefs.getDouble('fontSize') ?? 18.0;
    _lineHeight = prefs.getDouble('lineHeight') ?? 1.8;
    // ...
    notifyListeners();
  }
}

enum PageAnimationType { cover, simulation, none }
enum ReaderTheme { light, dark, eyeProtection, parchment, eInk }
```

#### 3.1.2 在阅读器中使用

```dart
// lib/ui/screens/reader_screen.dart
class ReaderScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ReaderSettingsService>();
    
    return Container(
      color: settings.theme.backgroundColor,
      child: Text(
        chapterContent,
        style: TextStyle(
          fontSize: settings.fontSize,
          height: settings.lineHeight,
          fontFamily: settings.customFontPath,
          color: settings.theme.textColor,
        ),
      ),
    );
  }
}
```

### 3.2 TTS 听书功能

#### 3.2.1 推荐插件

使用 `flutter_tts` 插件：

```yaml
# pubspec.yaml
dependencies:
  flutter_tts: ^4.0.2
```

#### 3.2.2 实现思路

```dart
// lib/services/tts_service.dart
import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;
  
  double _speechRate = 0.5; // 语速
  double get speechRate => _speechRate;
  
  double _volume = 1.0; // 音量
  double get volume => _volume;
  
  String? _currentVoice;
  String? get currentVoice => _currentVoice;
  
  // 初始化
  Future<void> initialize() async {
    await _flutterTts.setSharedInstance(true);
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    
    // 监听播放状态
    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
    });
    
    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
    });
  }
  
  // 获取可用语音列表
  Future<List<String>> getVoices() async {
    final voices = await _flutterTts.getVoices;
    return voices.map((v) => v['name'] as String).toList();
  }
  
  // 播放文本
  Future<void> speak(String text) async {
    if (_isPlaying) {
      await stop();
    }
    await _flutterTts.speak(text);
    _isPlaying = true;
  }
  
  // 暂停
  Future<void> pause() async {
    await _flutterTts.pause();
    _isPlaying = false;
  }
  
  // 继续
  Future<void> resume() async {
    await _flutterTts.continueSpeaking();
    _isPlaying = true;
  }
  
  // 停止
  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
  }
  
  // 设置语速
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }
  
  // 设置音量
  Future<void> setVolume(double vol) async {
    _volume = vol;
    await _flutterTts.setVolume(vol);
  }
  
  // 设置语音
  Future<void> setVoice(String voice) async {
    _currentVoice = voice;
    await _flutterTts.setVoice({'name': voice});
  }
}
```

#### 3.2.3 TTS 控制面板 UI

```dart
// lib/ui/widgets/tts_control_panel.dart
class TTSControlPanel extends StatelessWidget {
  final TTSService ttsService;
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // 播放控制按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous),
                onPressed: () => _playPreviousChapter(),
              ),
              IconButton(
                icon: Icon(ttsService.isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => _togglePlay(),
              ),
              IconButton(
                icon: Icon(Icons.skip_next),
                onPressed: () => _playNextChapter(),
              ),
            ],
          ),
          
          // 语速调节
          Slider(
            value: ttsService.speechRate,
            min: 0.1,
            max: 1.0,
            divisions: 10,
            label: '${(ttsService.speechRate * 100).toInt()}%',
            onChanged: (value) => ttsService.setSpeechRate(value),
          ),
          
          // 语音选择
          DropdownButton<String>(
            value: ttsService.currentVoice,
            items: _voiceOptions,
            onChanged: (value) => ttsService.setVoice(value!),
          ),
        ],
      ),
    );
  }
}
```

### 3.3 自定义字体功能

#### 3.3.1 推荐插件

使用 `file_picker` + `path_provider`：

```yaml
# pubspec.yaml
dependencies:
  file_picker: ^8.0.0+1
  path_provider: ^2.1.2
```

#### 3.3.2 实现思路

```dart
// lib/services/font_service.dart
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FontService {
  static const String _fontsDir = 'custom_fonts';
  
  // 获取自定义字体目录
  Future<Directory> _getFontsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory('${appDir.path}/$_fontsDir');
    
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }
    
    return fontsDir;
  }
  
  // 选择并导入字体
  Future<String?> importFont() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ttf', 'otf'],
    );
    
    if (result == null || result.files.isEmpty) return null;
    
    final file = File(result.files.first.path!);
    final fileName = result.files.first.name;
    final fontsDir = await _getFontsDirectory();
    final targetPath = '${fontsDir.path}/$fileName';
    
    // 复制字体文件到应用目录
    await file.copy(targetPath);
    
    return targetPath;
  }
  
  // 获取已导入的字体列表
  Future<List<String>> getImportedFonts() async {
    final fontsDir = await _getFontsDirectory();
    final entities = await fontsDir.list().toList();
    
    return entities
        .whereType<File>()
        .map((f) => f.path)
        .toList();
  }
  
  // 删除字体
  Future<void> deleteFont(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
```

#### 3.3.3 在 Flutter 中使用自定义字体

```dart
// 在 pubspec.yaml 中声明字体目录
flutter:
  fonts:
    - family: CustomFont
      fonts:
        - asset: assets/fonts/custom.ttf
```

```dart
// 动态加载字体
class CustomFontText extends StatelessWidget {
  final String text;
  final String? fontPath;
  final double fontSize;
  
  @override
  Widget build(BuildContext context) {
    if (fontPath == null) {
      return Text(text, style: TextStyle(fontSize: fontSize));
    }
    
    return FutureBuilder<FontLoader>(
      future: _loadFont(fontPath!),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            text,
            style: TextStyle(
              fontFamily: 'CustomFont',
              fontSize: fontSize,
            ),
          );
        }
        return Text(text, style: TextStyle(fontSize: fontSize));
      },
    );
  }
  
  Future<FontLoader> _loadFont(String path) async {
    final loader = FontLoader('CustomFont');
    final fontData = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.sublistView(fontData)));
    await loader.load();
    return loader;
  }
}
```

### 3.4 智能换源功能

#### 3.4.1 设计思路

```dart
// lib/services/source_switch_service.dart
class SourceSwitchService {
  // 备用 API 源列表
  final List<ApiSource> _backupSources = [
    ApiSource(
      name: '主源',
      baseUrl: 'http://api.ch6vip.com',
      priority: 0,
    ),
    ApiSource(
      name: '备用源1',
      baseUrl: 'http://api.backup1.com',
      priority: 1,
    ),
    ApiSource(
      name: '备用源2',
      baseUrl: 'http://api.backup2.com',
      priority: 2,
    ),
  ];
  
  ApiSource _currentSource = _backupSources.first;
  ApiSource get currentSource => _currentSource;
  
  // 记录每个源的失败次数
  final Map<String, int> _failureCount = {};
  
  // 获取章节内容（自动换源）
  Future<ChapterContent> getChapterContent(String itemId) async {
    for (final source in _sortedSources()) {
      try {
        final content = await _fetchFromSource(source, itemId);
        // 成功后重置失败计数
        _failureCount[source.name] = 0;
        return content;
      } catch (e) {
        _failureCount[source.name] = 
            (_failureCount[source.name] ?? 0) + 1;
        debugPrint('源 ${source.name} 请求失败: $e');
      }
    }
    
    throw ApiException('所有源均不可用');
  }
  
  // 按优先级和失败次数排序源
  List<ApiSource> _sortedSources() {
    return _backupSources
      ..sort((a, b) {
        final aFailures = _failureCount[a.name] ?? 0;
        final bFailures = _failureCount[b.name] ?? 0;
        
        // 先按优先级排序
        if (a.priority != b.priority) {
          return a.priority.compareTo(b.priority);
        }
        // 优先级相同则按失败次数排序
        return aFailures.compareTo(bFailures);
      });
  }
  
  // 手动切换源
  void switchToSource(String sourceName) {
    final source = _backupSources.firstWhere(
      (s) => s.name == sourceName,
      orElse: () => _backupSources.first,
    );
    _currentSource = source;
  }
}

class ApiSource {
  final String name;
  final String baseUrl;
  final int priority;
  
  ApiSource({
    required this.name,
    required this.baseUrl,
    required this.priority,
  });
}
```

### 3.5 本地导入功能

#### 3.5.1 推荐插件

```yaml
# pubspec.yaml
dependencies:
  epub_view: ^3.2.0  # EPUB 解析
  file_picker: ^8.0.0+1
```

#### 3.5.2 实现思路

```dart
// lib/services/local_import_service.dart
import 'package:epub_view/epub_view.dart';
import 'package:file_picker/file_picker.dart';

class LocalImportService {
  // 导入 EPUB 文件
  Future<Book?> importEpub() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['epub'],
    );
    
    if (result == null || result.files.isEmpty) return null;
    
    final file = File(result.files.first.path!);
    final bytes = await file.readAsBytes();
    
    try {
      // 解析 EPUB
      final epub = await EpubReader.openBook(bytes);
      
      // 提取元数据
      final title = epub.Title ?? '未命名书籍';
      final author = epub.Author ?? '未知作者';
      final cover = await _extractCover(epub);
      
      // 提取章节
      final chapters = _extractChapters(epub);
      
      return Book(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        title: title,
        author: author,
        coverUrl: cover,
        chapters: chapters,
        isLocal: true,
        localPath: file.path,
      );
    } catch (e) {
      debugPrint('EPUB 解析失败: $e');
      return null;
    }
  }
  
  // 导入 TXT 文件
  Future<Book?> importTxt() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['txt'],
    );
    
    if (result == null || result.files.isEmpty) return null;
    
    final file = File(result.files.first.path!);
    final content = await file.readAsString();
    
    // 按章节分割（假设章节以"第X章"开头）
    final chapters = _splitTxtIntoChapters(content);
    
    return Book(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: file.path.split('/').last.replaceAll('.txt', ''),
      author: '本地导入',
      chapters: chapters,
      isLocal: true,
      localPath: file.path,
    );
  }
  
  // 提取封面
  Future<String?> _extractCover(EpubBook epub) async {
    try {
      final coverImage = epub.CoverImage;
      if (coverImage != null) {
        // 保存到本地并返回路径
        final bytes = await coverImage.Content.readAsBytes();
        final path = await _saveImage(bytes);
        return path;
      }
    } catch (e) {
      debugPrint('提取封面失败: $e');
    }
    return null;
  }
  
  // 提取章节
  List<Chapter> _extractChapters(EpubBook epub) {
    final chapters = <Chapter>[];
    final chapterList = epub.Chapters;
    
    for (int i = 0; i < chapterList.length; i++) {
      final chapter = chapterList[i];
      chapters.add(Chapter(
        itemId: 'local_${i}',
        title: chapter.Title ?? '第${i + 1}章',
        chapterNumber: i + 1,
      ));
    }
    
    return chapters;
  }
  
  // 分割 TXT 为章节
  List<Chapter> _splitTxtIntoChapters(String content) {
    final chapters = <Chapter>[];
    final chapterPattern = RegExp(r'第[0-9零一二三四五六七八九十百千]+章');
    
    final matches = chapterPattern.allMatches(content);
    int lastIndex = 0;
    
    for (int i = 0; i < matches.length; i++) {
      final match = matches.elementAt(i);
      final title = match.group(0)!;
      final startIndex = match.start;
      
      if (i > 0) {
        final prevMatch = matches.elementAt(i - 1);
        final chapterContent = content.substring(prevMatch.start, startIndex);
        chapters.add(Chapter(
          itemId: 'local_${i - 1}',
          title: prevMatch.group(0)!,
          chapterNumber: i,
        ));
      }
      
      lastIndex = startIndex;
    }
    
    // 添加最后一章
    if (matches.isNotEmpty) {
      final lastMatch = matches.last;
      chapters.add(Chapter(
        itemId: 'local_${chapters.length}',
        title: lastMatch.group(0)!,
        chapterNumber: chapters.length + 1,
      ));
    }
    
    return chapters;
  }
}
```

---

## 4. 实施建议

### 4.1 开发优先级

**第一阶段 (P0 - 核心功能)**
1. 阅读器个性化设置（字体、行高、主题、翻页动画）
2. 缓存管理
3. 本地导入（TXT/EPUB）
4. 完善设置页 UI

**第二阶段 (P1 - 增强功能)**
1. TTS 听书
2. 自定义字体
3. 数据备份/恢复
4. App 锁
5. 书签功能

**第三阶段 (P2 - 高级功能)**
1. WebDAV 同步
2. 智能换源
3. 阅读统计
4. 笔记功能

### 4.2 技术栈补充

```yaml
# pubspec.yaml 新增依赖建议
dependencies:
  # 状态管理
  provider: ^6.1.5+1
  
  # 本地存储
  shared_preferences: ^2.2.3
  hive: ^2.2.3  # 用于大量数据存储
  
  # 文件操作
  file_picker: ^8.0.0+1
  path_provider: ^2.1.2
  
  # TTS
  flutter_tts: ^4.0.2
  
  # EPUB 解析
  epub_view: ^3.2.0
  
  # 安全
  local_auth: ^2.1.8  # 指纹/面容识别
  
  # WebDAV
  webdav_client: ^1.2.0
  
  # UI 组件
  flutter_colorpicker: ^1.0.3
  flutter_slidable: ^3.0.1
```

### 4.3 架构建议

```
lib/
├── models/
│   ├── reader_settings.dart      # 阅读设置模型
│   ├── tts_config.dart           # TTS 配置模型
│   └── font_info.dart            # 字体信息模型
├── services/
│   ├── reader_settings_service.dart  # 阅读设置服务
│   ├── tts_service.dart              # TTS 服务
│   ├── font_service.dart             # 字体管理服务
│   ├── source_switch_service.dart    # 智能换源服务
│   ├── local_import_service.dart     # 本地导入服务
│   ├── cache_service.dart            # 缓存管理服务
│   ├── backup_service.dart           # 备份恢复服务
│   └── security_service.dart         # 安全服务（App锁）
├── ui/
│   ├── screens/
│   │   ├── settings_screen.dart          # 设置主页
│   │   ├── reader_settings_screen.dart   # 阅读设置页
│   │   ├── cache_management_screen.dart  # 缓存管理页
│   │   ├── font_management_screen.dart   # 字体管理页
│   │   ├── tts_settings_screen.dart      # TTS 设置页
│   │   ├── backup_screen.dart            # 备份恢复页
│   │   └── security_screen.dart          # 安全设置页
│   └── widgets/
│       ├── theme_preview.dart            # 主题预览组件
│       ├── tts_control_panel.dart        # TTS 控制面板
│       └── font_selector.dart            # 字体选择器
└── controllers/
    └── settings_controller.dart          # 设置控制器
```

---

## 5. 总结

本方案为小说阅读器 App 提供了完整的功能迭代路线图：

1. **阅读器个性化**：通过 `ReaderSettingsService` 实现全局设置管理，支持字体、主题、翻页动画等核心功能
2. **通用应用设置**：涵盖缓存管理、数据备份、隐私安全等必要功能
3. **差异化功能**：TTS 听书、本地导入、智能换源等功能提升产品竞争力

建议按 P0 → P1 → P2 的优先级逐步实施，确保核心功能稳定后再添加高级特性。
