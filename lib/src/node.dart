import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' show parse;

import 'dom_utils.dart' as dom_utils;

/// A node of the HTML being converted, as seen by a `Rule`'s functions.
class Node {
  /// Wraps [node].
  Node(this.node);

  /// Parses [input], an HTML string or a `dom.Node`, and returns the node
  /// whose children are converted.
  ///
  /// For a string, that node is the first [rootTag] element, `html` by
  /// default. A `dom.Node` is copied first, so the caller's tree is left as
  /// it was.
  factory Node.root(Object input, {String? rootTag}) {
    final root = switch (input) {
      dom.Node() => input.clone(true),
      _ => parse(input)
          .getElementsByTagName(
            rootTag == null || rootTag.isEmpty ? 'html' : rootTag,
          )
          .first,
    };
    return Node(dom_utils.collapseWhitespace(root));
  }

  /// The wrapped node.
  final dom.Node node;

  dom.Element? get _element => switch (node) {
        final dom.Element element => element,
        _ => null,
      };

  /// Number of child elements.
  int get childNum => _element?.children.length ?? 0;

  /// The `class` attribute of an element, or empty.
  String get className => _element?.className ?? '';

  /// The first child node of an element.
  Node? get firstChild => switch (_element?.firstChild) {
        final dom.Node child => Node(child),
        null => null,
      };

  /// Whether the node has a sibling node on either side.
  bool get hasSiblings =>
      dom_utils.nextSibling(node) != null ||
      dom_utils.previousSibling(node) != null;

  /// Whether this is a link or table cell that shows nothing.
  bool get isBlank =>
      const ['a', 'th', 'td'].contains(nodeName) &&
      textContent.trim().isEmpty &&
      !dom_utils.isVoid(_element) &&
      !dom_utils.hasVoid(_element);

  /// Whether this is a block element.
  bool get isBlock => dom_utils.isBlock(_element);

  /// Whether this is a `code` element or inside one. Text inside code is
  /// kept as it is instead of being escaped.
  bool get isCode {
    for (dom.Node? current = node; current != null; current = current.parent) {
      if (current is dom.Element && current.localName == 'code') {
        return true;
      }
    }
    return false;
  }

  /// Whether this is the first child element of its parent.
  bool get isParentFirstChild => node.parent!.children.first == _element;

  /// Whether this is the last child element of its parent.
  bool get isParentLastChild => node.parent!.children.last == _element;

  /// The next sibling node.
  dom.Node? get nextSibling => dom_utils.nextSibling(node);

  /// The lowercase element name, or empty for other nodes.
  String get nodeName => _element?.localName?.toLowerCase() ?? '';

  /// The DOM node type, such as `dom.Node.ELEMENT_NODE`.
  int get nodeType => node.nodeType;

  /// The HTML of an element, or empty.
  String get outerHTML => _element?.outerHtml ?? '';

  /// Position of this element among its parent's child elements, or -1.
  int get parentChildIndex => switch (_element) {
        null => -1,
        final element => node.parent?.children.indexOf(element) ?? -1,
      };

  /// The lowercase name of the parent element of an element, or empty.
  String get parentElName => _element?.parent?.localName?.toLowerCase() ?? '';

  /// Number of elements among the parent's child nodes.
  int get siblingNum => dom_utils.countSiblingElements(node);

  /// The text of the node and its descendants.
  String get textContent => switch (node) {
        final dom.Text text => text.data,
        _ => _element?.text ?? '',
      };

  /// The wrapped node as an element, or null.
  dom.Element? asElement() => _element;

  /// The child nodes.
  Iterable<Node> childNodes() => node.nodes.map(Node.new);

  /// The attribute [name] of this element.
  String? getAttribute(String name) => _element!.attributes[name];

  /// The attribute [name] of the parent element.
  String? getParentAttribute(String name) => _element!.parent!.attributes[name];
}
