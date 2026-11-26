import 'package:html/dom.dart' as dom;

import 'commonmark_rules.dart';
import 'dom_utils.dart' as dom_utils;
import 'node.dart';
import 'rule.dart';
import 'style_options.dart';
import 'table_rules.dart';

/// Converts [input], an HTML string or a `dom.Node`, to Markdown.
///
/// [rootTag] picks the element of an HTML string whose content is converted,
/// `html` by default. [imageBaseUrl] is put in front of every image source.
///
/// [styleOptions] picks the Markdown syntax. Each first value is the default:
///
/// | Name | Values |
/// | --- | --- |
/// | headingStyle | `setext`, `atx` |
/// | hr | `* * *`, `- - -`, `_ _ _` |
/// | bulletListMarker | `*`, `-`, `_` |
/// | codeBlockStyle | `indented`, `fenced` |
/// | fence | ` ``` `, `~~~` |
/// | emDelimiter | `_`, `*` |
/// | strongDelimiter | `**`, `__` |
/// | linkStyle | `inlined`, `referenced` |
/// | linkReferenceStyle | `full`, `collapsed`, `shortcut` |
///
/// Elements named in [ignore] are left out together with their content.
/// [rules] are tried before the built-in rules, so they can replace them.
///
/// Every call is independent: options and rules apply to that call only.
String convert(
  Object input, {
  String? rootTag,
  String? imageBaseUrl,
  Map<String, String>? styleOptions,
  List<String>? ignore,
  List<Rule>? rules,
}) {
  final linkReferences = <String>[];
  final converter = _Converter([
    ...?rules,
    if (ignore != null && ignore.isNotEmpty)
      Rule('ignore', filters: ignore, replacement: (content, node) => ''),
    ...commonMarkRules(
      StyleOptions(styleOptions),
      imageBaseUrl: imageBaseUrl,
      linkReferences: linkReferences,
    ),
    ...tableRules,
  ]);
  return converter.convert(Node.root(input, rootTag: rootTag));
}

final _leadingNewlines = RegExp(r'^\n*');
final _trailingNewlines = RegExp(r'\n*$');
final _leadingLineBreaks = RegExp(r'^[\t\r\n]+');
final _trailingWhitespace = RegExp(r'[\t\r\n\s]+$');
final _edgeWhitespace = RegExp(
  r'^(([ \t\r\n]*)(\s*))(?:(?=\S)[\s\S]*\S)?((\s*?)([ \t\r\n]*))$',
);

final _defaultRule = Rule(
  'default',
  replacement: (content, node) {
    if (!node.isBlock) {
      return content;
    }
    return content.isEmpty ? '\n\n' : '\n\n$content\n\n';
  },
);

class _Converter {
  _Converter(this._rules);

  final List<Rule> _rules;
  final _appendingRules = <Rule>{};

  String convert(Node root) {
    var output = _convertChildren(root);
    for (final rule in _appendingRules) {
      output = _join(output, rule.append!());
    }
    return output
        .replaceAll(_leadingLineBreaks, '')
        .replaceAll(_trailingWhitespace, '');
  }

  String _convertChildren(Node parent) {
    var output = '';
    for (final node in parent.childNodes()) {
      final replacement = switch (node.node) {
        dom.Text(:final data) => node.isCode ? data : _escape(data),
        dom.Element() => _convertElement(node),
        _ => '',
      };
      output = _join(
          _separateExclamationFromBracket(output, replacement), replacement);
    }
    return output;
  }

  String _convertElement(Node node) {
    final rule = _rules.firstWhere(
      (rule) => rule.matches(node),
      orElse: () => _defaultRule,
    );
    if (rule.append != null) {
      _appendingRules.add(rule);
    }

    var content = _convertChildren(node);
    final (:leading, :trailing) = _flankingWhitespace(node);
    if (leading.isNotEmpty || trailing.isNotEmpty) {
      content = content.trim();
    }
    final replacement = rule.replacement?.call(content, node) ?? content;
    return '$leading$replacement$trailing';
  }

  /// Whitespace at the edges of an inline element moves outside of it, so
  /// that `<b>bold&nbsp;</b>` becomes `**bold**&nbsp;` instead of
  /// `**bold&nbsp;**`, which is not bold in Markdown. A space is dropped when
  /// the neighboring text already provides one.
  ({String leading, String trailing}) _flankingWhitespace(Node node) {
    if (node.isBlock) {
      return (leading: '', trailing: '');
    }
    final edges = _edgeWhitespace.firstMatch(node.textContent)!;
    final [
      leading,
      leadingAscii,
      leadingNonAscii
    ] = [edges[1]!, edges[2]!, edges[3]!];
    final [
      trailing,
      trailingNonAscii,
      trailingAscii
    ] = [edges[4]!, edges[5]!, edges[6]!];
    return (
      leading:
          leadingAscii.isNotEmpty && _isFlankedByWhitespace(node, onLeft: true)
              ? leadingNonAscii
              : leading,
      trailing: trailingAscii.isNotEmpty &&
              _isFlankedByWhitespace(node, onLeft: false)
          ? trailingNonAscii
          : trailing,
    );
  }
}

bool _isFlankedByWhitespace(Node node, {required bool onLeft}) {
  final sibling = onLeft
      ? dom_utils.previousSibling(node.node)
      : dom_utils.nextSibling(node.node);
  final siblingText = switch (sibling) {
    dom.Text(:final data) => data,
    final dom.Element element when !dom_utils.isBlock(element) =>
      element.innerHtml,
    _ => null,
  };
  if (siblingText == null) {
    return false;
  }
  return onLeft ? siblingText.endsWith(' ') : siblingText.startsWith(' ');
}

/// A `!` right before a link or an image would turn the link into an image,
/// or confuse some parsers, so it is escaped.
String _separateExclamationFromBracket(String output, String replacement) {
  final isBeforeBracket =
      replacement.startsWith('[') || replacement.startsWith('![');
  if (isBeforeBracket && output.endsWith('!') && !output.endsWith(r'\!')) {
    return '${output.substring(0, output.length - 1)}\\!';
  }
  return output;
}

String _join(String first, String second) {
  final trailing = _trailingNewlines.stringMatch(first)!;
  final leading = _leadingNewlines.stringMatch(second)!;
  final mostNewlines = trailing.length > leading.length ? trailing : leading;
  final separator = mostNewlines.length < 2 ? mostNewlines : '\n\n';
  return '${first.replaceAll(_trailingNewlines, '')}$separator'
      '${second.replaceAll(_leadingNewlines, '')}';
}

/// Text inside a URL, such as `https://example.com/a_b_c`, is not escaped.
const _notInUrl = r'(?<!(?:https?://|mailto:|tel:)\S*)';

final _escapes = <(RegExp, String Function(Match))>[
  (RegExp(r'\\(\S)'), (match) => '\\\\${match[1]}'),
  (RegExp(r'^(#{1,6} )', multiLine: true), (match) => '\\${match[1]}'),
  (
    RegExp(r'^([-*_] *){3,}$', multiLine: true),
    (match) => match[0]!.split(match[1]!).join('\\${match[1]}'),
  ),
  (
    RegExp(r'^(\W* {0,3})(\d+)\. ', multiLine: true),
    (match) => '${match[1]}${match[2]}\\. ',
  ),
  (
    RegExp(r'^([^\\\w]*)[*+-] ', multiLine: true),
    (match) => match[0]!.replaceAllMapped(
          RegExp('([*+-])'),
          (symbol) => '\\${symbol[1]}',
        ),
  ),
  (RegExp(r'^(\W* {0,3})> '), (match) => '${match[1]}\\> '),
  (
    RegExp('$_notInUrl\\*+(?![*\\s\\W]).+?\\*+'),
    (match) => match[0]!.replaceAll('*', r'\*'),
  ),
  (
    RegExp('${_notInUrl}_+(?![_\\s\\W]).+?_+'),
    (match) => match[0]!.replaceAll('_', r'\_'),
  ),
  (
    RegExp('$_notInUrl`+(?![`\\s\\W]).+?`+'),
    (match) => match[0]!.replaceAll('`', r'\`'),
  ),
  (RegExp('$_notInUrl[\\[\\]]'), (match) => '\\${match[0]}'),
];

String _escape(String text) => _escapes.fold(
      text,
      (escaped, escape) => escaped.replaceAllMapped(escape.$1, escape.$2),
    );
