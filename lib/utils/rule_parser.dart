import 'dart:convert';

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:json_path/json_path.dart';

/// 规则解析器
///
/// 支持 JSON 和 HTML 两种格式的规则解析
/// 用于书源规则中的数据提取
class RuleParser {
  RuleParser._(this.isJson, this._jsonRoot, this._document);

  /// 从原始字符串创建解析器
  ///
  /// 自动检测输入是 JSON 还是 HTML，并选择对应的解析方式
  /// JSON 检测：以 { 或 [ 开头
  factory RuleParser.from(String raw) {
    final trimmed = raw.trimLeft();
    if (_looksLikeJson(trimmed)) {
      final jsonRoot = jsonDecode(raw);
      return RuleParser._(true, jsonRoot, null);
    }
    final document = html_parser.parse(raw);
    return RuleParser._(false, null, document);
  }


  /// 是否为 JSON 格式
  final bool isJson;

  /// JSON 根节点（仅 JSON 格式使用）
  final dynamic _jsonRoot;

  /// HTML 文档对象（仅 HTML 格式使用）
  final dom.Document? _document;

  /// Selects a list of elements or items using a rule.
  ///
  /// For JSON, the rule can be a direct key or JSONPath.
  /// For HTML, the rule can be a CSS selector with optional `@attr`.
  /// If [context] is provided, selection is scoped to that node/root.
  List<dynamic> selectList(String? rule, {dynamic context}) {
    final normalized = rule?.trim() ?? '';
    if (normalized.isEmpty) {
      if (isJson && (context ?? _jsonRoot) is List) {
        return List<dynamic>.from((context ?? _jsonRoot) as List);
      }
      return [];
    }
    if (isJson) {
      return _selectJsonList(context ?? _jsonRoot, normalized);
    }
    return _selectHtmlList(normalized, context: context as dom.Element?);
  }

  /// Selects a single string value using a rule.
  ///
  /// For JSON, values are normalized into strings.
  /// For HTML, returns `text`, `html`, `textNodes`, or attribute values via `@attr`.
  /// If [context] is provided, selection is scoped to that node/root.
  String selectString(String? rule, {dynamic context}) {
    final normalized = rule?.trim() ?? '';
    if (normalized.isEmpty) return '';
    if (isJson) {
      final value = _selectJsonValue(context ?? _jsonRoot, normalized);
      return _stringifyJsonValue(value);
    }
    return _selectHtmlString(normalized, context: context as dom.Element?);
  }

  static bool _looksLikeJson(String value) {
    if (value.isEmpty) return false;
    return value.startsWith('{') || value.startsWith('[');
  }

  static const Set<String> _attrKeys = {
    'text',
    'html',
    'href',
    'src',
    'textNodes',
  };

  static _RuleParts _parseRule(String rule) {
    final segments = rule
        .split('@')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (segments.isEmpty) {
      return const _RuleParts([], null);
    }
    String? attr;
    if (_attrKeys.contains(segments.last)) {
      attr = segments.removeLast();
    }
    final selectors = segments
        .map(_normalizeSelector)
        .where((selector) => selector.isNotEmpty)
        .toList();
    return _RuleParts(selectors, attr);
  }

  static String _normalizeSelector(String selector) {
    final normalized = selector.trim();
    if (normalized.startsWith('class.')) {
      return '.${normalized.substring(6)}';
    }
    if (normalized.startsWith('id.')) {
      return '#${normalized.substring(3)}';
    }
    if (normalized.startsWith('tag.')) {
      return normalized.substring(4);
    }
    return normalized;
  }

  List<dom.Element> _selectHtmlList(
    String rule, {
    dom.Element? context,
  }) {
    final parts = _parseRule(rule);
    if (parts.selectors.isEmpty) return [];
    final selector = parts.selectors.join(' ');
    final root = context ?? _document;
    if (root == null) return [];
    return root.querySelectorAll(selector);
  }

  String _selectHtmlString(
    String rule, {
    dom.Element? context,
  }) {
    final parts = _parseRule(rule);
    dom.Element? target;
    if (parts.selectors.isEmpty) {
      target = context ?? _document?.documentElement;
    } else {
      final selector = parts.selectors.join(' ');
      final root = context ?? _document;
      target = root?.querySelector(selector);
    }
    if (target == null) return '';

    final attr = parts.attr;
    if (attr == null || attr == 'text') {
      return target.text.trim();
    }
    if (attr == 'html') {
      return target.innerHtml.trim();
    }
    if (attr == 'textNodes') {
      return _collectTextNodes(target).trim();
    }
    return target.attributes[attr] ?? '';
  }

  String _collectTextNodes(dom.Element element) {
    final buffer = StringBuffer();
    for (final node in element.nodes) {
      if (node.nodeType == dom.Node.TEXT_NODE) {
        buffer.write(node.text);
      }
    }
    return buffer.toString();
  }

  List<dynamic> _selectJsonList(dynamic root, String rule) {
    final ruleKey = _stripAttr(rule);
    if (root is Map && root[ruleKey] is List) {
      return List<dynamic>.from(root[ruleKey] as List);
    }
    final matches = _readJsonPath(root, ruleKey);
    if (matches.isEmpty) return [];
    final results = <dynamic>[];
    for (final match in matches) {
      final value = match.value;
      if (value is List) {
        results.addAll(value);
      } else if (value != null) {
        results.add(value);
      }
    }
    return results;
  }

  dynamic _selectJsonValue(dynamic root, String rule) {
    final ruleKey = _stripAttr(rule);
    if (root is Map && root.containsKey(ruleKey)) {
      return root[ruleKey];
    }
    if (root is List) {
      final index = int.tryParse(ruleKey);
      if (index != null && index >= 0 && index < root.length) {
        return root[index];
      }
    }
    final matches = _readJsonPath(root, ruleKey);
    if (matches.isEmpty) return null;
    return matches.first.value;
  }

  List<JsonPathMatch> _readJsonPath(dynamic root, String rule) {
    final path = rule.startsWith(r'$.') ? rule : r'$.' + rule;
    try {
      return JsonPath(path).read(root).toList();
    } catch (_) {
      return const <JsonPathMatch>[];
    }
  }

  String _stripAttr(String rule) {
    final parts = rule.split('@');
    if (parts.isEmpty) return rule;
    if (parts.length == 1) return rule;
    final last = parts.last.trim();
    if (_attrKeys.contains(last)) {
      parts.removeLast();
    }
    return parts.join('@').trim();
  }

  String _stringifyJsonValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List) {
      return value
          .map(_stringifyJsonValue)
          .where((v) => v.isNotEmpty)
          .join('\n');
    }
    return jsonEncode(value);
  }
}

class _RuleParts {
  const _RuleParts(this.selectors, this.attr);

  final List<String> selectors;
  final String? attr;
}
