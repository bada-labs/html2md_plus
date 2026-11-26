import 'node.dart';
import 'rule.dart';
import 'style_options.dart';

final _leadingNewlines = RegExp(r'^\n+');
final _trailingNewlines = RegExp(r'\n+$');
final _outerNewlines = RegExp(r'^\n+|\n+$');
final _lineStart = RegExp('^', multiLine: true);
final _codeLanguage = RegExp(r'language-(\S+)');
final _backtickRun = RegExp('`+');

/// The CommonMark rules in the order they are tried.
///
/// [linkReferences] collects the definitions of referenced links while one
/// document is converted.
List<Rule> commonMarkRules(
  StyleOptions style, {
  required String? imageBaseUrl,
  required List<String> linkReferences,
}) {
  String wrap(String delimiter, String content) =>
      content.trim().isEmpty ? '' : '$delimiter$content$delimiter';

  String renderedTitle(Node node) => switch (node.getAttribute('title')) {
        final title? when title.isNotEmpty => ' "$title"',
        _ => '',
      };

  return [
    Rule(
      'paragraph',
      filters: ['p'],
      replacement: (content, node) => '\n\n$content\n\n',
    ),
    Rule(
      'lineBreak',
      filters: ['br'],
      replacement: (content, node) => '${style.br}\n',
    ),
    Rule(
      'heading',
      filters: ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
      replacement: (content, node) {
        final level = int.parse(node.nodeName.substring(1));
        if (style.headingStyle == 'setext' && level < 3) {
          final underline = (level == 1 ? '=' : '-') * content.length;
          return '\n\n$content\n$underline\n\n';
        }
        return '\n\n${'#' * level} $content\n\n';
      },
    ),
    Rule(
      'blockquote',
      filters: ['blockquote'],
      replacement: (content, node) {
        final quoted =
            content.replaceAll(_outerNewlines, '').replaceAll(_lineStart, '> ');
        return '\n\n$quoted\n\n';
      },
    ),
    Rule(
      'list',
      filters: ['ul', 'ol'],
      replacement: (content, node) =>
          node.parentElName == 'li' && node.isParentLastChild
              ? '\n$content'
              : '\n\n$content\n\n',
    ),
    Rule(
      'listItem',
      filters: ['li'],
      replacement: (content, node) {
        final itemContent = content
            .replaceAll(_leadingNewlines, '')
            .replaceAll(_trailingNewlines, '\n')
            .replaceAll('\n', '\n    ');
        var prefix = '${style.bulletListMarker}   ';
        if (node.parentElName == 'ol') {
          final start =
              int.tryParse(node.getParentAttribute('start') ?? '') ?? -1;
          final number = start > -1
              ? start + node.parentChildIndex
              : node.parentChildIndex + 1;
          prefix = '$number.  ';
        }
        final postfix =
            node.nextSibling != null && !itemContent.endsWith('\n') ? '\n' : '';
        return '$prefix$itemContent$postfix';
      },
    ),
    Rule(
      'indentedCodeBlock',
      filterFn: (node) =>
          style.codeBlockStyle == 'indented' &&
          node.nodeName == 'code' &&
          node.parentElName == 'pre',
      replacement: (content, node) {
        final code = node.textContent.replaceAll(_trailingNewlines, '');
        return '\n\n    ${code.replaceAll('\n', '\n    ')}\n\n';
      },
    ),
    Rule(
      'fencedCodeBlock',
      filterFn: (node) =>
          style.codeBlockStyle == 'fenced' &&
          node.nodeName == 'code' &&
          node.parentElName == 'pre',
      replacement: (content, node) {
        final className = node.className;
        final language =
            _codeLanguage.firstMatch(className)?.group(1) ?? className;
        return '\n\n${style.fence}$language\n${node.textContent}\n'
            '${style.fence}\n\n';
      },
    ),
    Rule(
      'horizontalRule',
      filters: ['hr'],
      replacement: (content, node) => '${style.hr}\n',
    ),
    Rule(
      'inlineLink',
      filterFn: (node) =>
          style.linkStyle == 'inlined' &&
          node.nodeName == 'a' &&
          node.getAttribute('href') != null,
      replacement: (content, node) =>
          '[$content](${node.getAttribute('href')}${renderedTitle(node)})',
    ),
    Rule(
      'referenceLink',
      filterFn: (node) =>
          style.linkStyle == 'referenced' &&
          node.nodeName == 'a' &&
          node.getAttribute('href') != null,
      replacement: (content, node) {
        final destination =
            '${node.getAttribute('href')}${renderedTitle(node)}';
        switch (style.linkReferenceStyle) {
          case 'collapsed':
            linkReferences.add('[$content]: $destination');
            return '[$content][]';
          case 'shortcut':
            linkReferences.add('[$content]: $destination');
            return '[$content]';
          default:
            final id = linkReferences.length + 1;
            linkReferences.add('[$id]: $destination');
            return '[$content][$id]';
        }
      },
      append: () =>
          linkReferences.isEmpty ? '' : '\n\n${linkReferences.join('\n')}\n\n',
    ),
    Rule(
      'emphasis',
      filters: ['em', 'i'],
      replacement: (content, node) => wrap(style.emDelimiter, content),
    ),
    Rule(
      'strong',
      filters: ['strong', 'b'],
      replacement: (content, node) => wrap(style.strongDelimiter, content),
    ),
    Rule(
      'strike',
      filters: ['strike', 's', 'del'],
      replacement: (content, node) => wrap('~~', content),
    ),
    Rule(
      'code',
      filters: ['code'],
      replacement: (content, node) {
        if (content.trim().isEmpty) {
          return '';
        }
        final backtickRuns =
            _backtickRun.allMatches(content).map((match) => match[0]).toSet();
        var delimiter = '`';
        while (backtickRuns.contains(delimiter)) {
          delimiter += '`';
        }
        final padding = backtickRuns.isEmpty ? '' : ' ';
        final leading = content.startsWith('`') ? padding : '';
        final trailing = content.endsWith('`') ? padding : '';
        return '$delimiter$leading$content$trailing$delimiter';
      },
    ),
    Rule(
      'image',
      filters: ['img'],
      replacement: (content, node) {
        final source = node.getAttribute('src') ?? '';
        if (source.isEmpty) {
          return '';
        }
        final alt = node.getAttribute('alt') ?? '';
        return '![$alt](${_resolve(source, imageBaseUrl)}${renderedTitle(node)})';
      },
    ),
  ];
}

String _resolve(String source, String? baseUrl) {
  if (baseUrl == null || baseUrl.isEmpty) {
    return source;
  }
  final separator = baseUrl.endsWith('/') || source.startsWith('/') ? '' : '/';
  return '$baseUrl$separator$source';
}
