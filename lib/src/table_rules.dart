// Adapted from turndown-plugin-gfm.
// MIT License, Copyright (c) 2017+ Dom Christie, guyplusplus.

import 'node.dart';
import 'rule.dart';

const _borderByAlignment = {'left': ':--', 'right': '--:', 'center': ':-:'};

/// The GitHub Flavored Markdown table rules.
final List<Rule> tableRules = [
  Rule(
    'tableCell',
    filters: ['th', 'td'],
    replacement: (content, node) =>
        _cell(content, node) + _spannedCells(node, ''),
  ),
  Rule(
    'tableRow',
    filters: ['tr'],
    replacement: (content, node) {
      if (!_isHeadingRow(node)) {
        return '\n$content';
      }
      final borderCells = StringBuffer();
      for (final cellNode in node.childNodes()) {
        final alignment = (cellNode.getAttribute('align') ?? '').toLowerCase();
        final border = _borderByAlignment[alignment] ?? '---';
        borderCells
          ..write(_cell(border, cellNode))
          ..write(_spannedCells(cellNode, border));
      }
      return borderCells.isEmpty ? '\n$content' : '\n$content\n$borderCells';
    },
  ),
  Rule(
    'table',
    filters: ['table'],
    replacement: (content, node) {
      if (_isNestedTable(node)) {
        return '  ${node.outerHTML}  ';
      }
      return '\n\n${content.replaceAll('\n\n', '\n')}\n\n';
    },
  ),
  Rule(
    'tableSection',
    filters: ['thead', 'tbody', 'tfoot'],
    replacement: (content, node) => content,
  ),
  Rule(
    'captionSection',
    filters: ['caption'],
    replacement: (content, node) =>
        node.parentElName == 'table' && node.isParentFirstChild ? content : '',
  ),
];

bool _isHeadingRow(Node row) {
  var table = row.asElement()?.parent;
  if (const {'thead', 'tfoot', 'tbody'}.contains(row.parentElName)) {
    table = table?.parent;
  }
  return table?.localName == 'table' &&
      table?.querySelector('tr:first-child') == row.asElement();
}

String _cell(String content, Node node) {
  final prefix = node.parentChildIndex == 0 ? '| ' : ' ';
  final singleLine = content.replaceAll('\r\n', '\n').replaceAll('\n', ' ');
  return '$prefix${singleLine.replaceAll('|', r'\|')} |';
}

String _spannedCells(Node node, String spannedCellContent) {
  final colspan = int.tryParse(node.getAttribute('colspan') ?? '') ?? 1;
  return colspan <= 1 ? '' : ' $spannedCellContent |' * (colspan - 1);
}

bool _isNestedTable(Node table) {
  for (var ancestor = table.asElement()?.parent;
      ancestor != null;
      ancestor = ancestor.parent) {
    if (ancestor.localName == 'table') {
      return true;
    }
  }
  return false;
}
