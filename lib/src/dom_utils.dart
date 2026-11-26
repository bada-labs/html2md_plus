import 'package:html/dom.dart' as dom;

const _blockElements = {
  'address',
  'article',
  'aside',
  'audio',
  'blockquote',
  'body',
  'canvas',
  'center',
  'dd',
  'dir',
  'div',
  'dl',
  'dt',
  'fieldset',
  'figcaption',
  'figure',
  'footer',
  'form',
  'frameset',
  'h1',
  'h2',
  'h3',
  'h4',
  'h5',
  'h6',
  'header',
  'hgroup',
  'hr',
  'html',
  'isindex',
  'li',
  'main',
  'menu',
  'nav',
  'noframes',
  'noscript',
  'ol',
  'output',
  'p',
  'pre',
  'section',
  'table',
  'tbody',
  'td',
  'tfoot',
  'th',
  'thead',
  'tr',
  'ul',
};

const _voidElements = {
  'area',
  'base',
  'br',
  'col',
  'command',
  'embed',
  'hr',
  'img',
  'input',
  'keygen',
  'link',
  'meta',
  'param',
  'source',
  'track',
  'wbr',
};

/// Elements whose content is never readable text.
const _removedElements = {'noscript', 'script', 'style', 'template'};

final _voidElementsSelector = _voidElements.join(',');
final _whitespaceRun = RegExp(r'[ \r\n\t]+');
final _trailingSpace = RegExp(r' $');

String? _elementName(dom.Node? node) =>
    node is dom.Element ? node.localName?.toLowerCase() : null;

bool isBlock(dom.Node? node) => _blockElements.contains(_elementName(node));

bool isVoid(dom.Node? node) => _voidElements.contains(_elementName(node));

bool hasVoid(dom.Node? node) =>
    node is dom.Element &&
    node.querySelectorAll(_voidElementsSelector).isNotEmpty;

dom.Node? nextSibling(dom.Node node) {
  final siblings = node.parentNode?.nodes;
  if (siblings == null) {
    return null;
  }
  final index = siblings.indexOf(node) + 1;
  return index < siblings.length ? siblings[index] : null;
}

dom.Node? previousSibling(dom.Node node) {
  final siblings = node.parentNode?.nodes;
  if (siblings == null) {
    return null;
  }
  final index = siblings.indexOf(node) - 1;
  return index >= 0 ? siblings[index] : null;
}

int countSiblingElements(dom.Node node) =>
    node.parentNode?.nodes.whereType<dom.Element>().length ?? 0;

/// Collapses whitespace the way a browser renders it and removes elements
/// without readable content, walking [root] in document order.
dom.Node collapseWhitespace(dom.Node root) {
  if (root.firstChild == null || _isPre(root)) {
    return root;
  }

  dom.Node? previous;
  dom.Text? previousText;
  var current = _nextNode(previous, root);

  while (current != root) {
    switch (current) {
      case final dom.Text textNode:
        var text = textNode.data.replaceAll(_whitespaceRun, ' ');
        final previousEndsWithSpace =
            previousText == null || previousText.data.endsWith(' ');
        if (previousEndsWithSpace && text.startsWith(' ')) {
          text = text.substring(1);
        }
        if (text.isEmpty) {
          current = _remove(textNode);
          continue;
        }
        textNode.data = text;
        previousText = textNode;
      case final dom.Element element:
        final name = _elementName(element);
        if (_removedElements.contains(name)) {
          current = _remove(element);
          continue;
        }
        if (isBlock(element) || name == 'br') {
          previousText?.data = previousText.data.replaceAll(_trailingSpace, '');
          previousText = null;
        } else if (isVoid(element)) {
          previousText = null;
        }
      default:
        current = _remove(current!);
        continue;
    }

    final next = _nextNode(previous, current!);
    previous = current;
    current = next;
  }

  if (previousText != null) {
    previousText.data = previousText.data.replaceAll(_trailingSpace, '');
    if (previousText.data.isEmpty) {
      _remove(previousText);
    }
  }

  return root;
}

bool _isPre(dom.Node? node) => _elementName(node) == 'pre';

dom.Node? _nextNode(dom.Node? previous, dom.Node current) {
  if ((previous != null && previous.parentNode == current) || _isPre(current)) {
    return nextSibling(current) ?? current.parentNode;
  }
  return current.firstChild ?? nextSibling(current) ?? current.parentNode;
}

dom.Node? _remove(dom.Node node) {
  final next = nextSibling(node) ?? node.parentNode;
  node.remove();
  return next;
}
