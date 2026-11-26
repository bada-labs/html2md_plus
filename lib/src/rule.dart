import 'node.dart';

/// Returns text appended to the end of the converted Markdown, such as the
/// link reference definitions.
typedef AppendFn = String Function();

/// Decides whether a rule handles [node].
typedef FilterFn = bool Function(Node node);

/// Returns the Markdown for [node], given the already converted [content] of
/// its children.
typedef ReplacementFn = String Function(String content, Node node);

/// Decides which elements it handles and how they become Markdown.
///
/// Rules are equal when their [name]s are equal.
class Rule {
  /// Creates a rule that handles the elements named in [filters], or the
  /// nodes [filterFn] accepts when [filters] is empty.
  Rule(this.name, {this.filters, this.filterFn, this.replacement, this.append})
      : _matcher = _buildMatcher(filters, filterFn);

  /// Unique rule name.
  final String name;

  /// Lowercase names of the elements this rule handles, such as `['aside']`.
  final List<String>? filters;

  /// Decides whether this rule handles a node, when [filters] is empty.
  final FilterFn? filterFn;

  /// Converts a handled node.
  final ReplacementFn? replacement;

  /// Adds text to the end of the output once the whole document is converted.
  final AppendFn? append;

  final FilterFn? _matcher;

  /// Whether this rule handles [node].
  bool matches(Node node) => _matcher?.call(node) ?? false;

  @override
  int get hashCode => name.hashCode;

  @override
  bool operator ==(Object other) => other is Rule && other.name == name;

  static FilterFn? _buildMatcher(List<String>? filters, FilterFn? filterFn) {
    if (filters == null || filters.isEmpty) {
      return filterFn;
    }
    return (node) => filters.contains(node.nodeName);
  }
}
