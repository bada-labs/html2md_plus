const _availableStyles = {
  'headingStyle': ['setext', 'atx'],
  'hr': ['* * *', '- - -', '_ _ _'],
  'bulletListMarker': ['*', '-', '_'],
  'codeBlockStyle': ['indented', 'fenced'],
  'fence': ['```', '~~~'],
  'emDelimiter': ['_', '*'],
  'strongDelimiter': ['**', '__'],
  'linkStyle': ['inlined', 'referenced'],
  'linkReferenceStyle': ['full', 'collapsed', 'shortcut'],
  'br': ['  '],
};

/// The Markdown syntax chosen for each construct in one conversion.
///
/// Every style starts at its first available value. A requested value that is
/// not available for its style is ignored.
class StyleOptions {
  StyleOptions(Map<String, String>? requestedStyles)
      : _styles = {
          for (final MapEntry(key: name, value: available)
              in _availableStyles.entries)
            name: switch (requestedStyles?[name]) {
              final requested? when available.contains(requested) => requested,
              _ => available.first,
            },
        };

  final Map<String, String> _styles;

  String get headingStyle => _styles['headingStyle']!;
  String get hr => _styles['hr']!;
  String get bulletListMarker => _styles['bulletListMarker']!;
  String get codeBlockStyle => _styles['codeBlockStyle']!;
  String get fence => _styles['fence']!;
  String get emDelimiter => _styles['emDelimiter']!;
  String get strongDelimiter => _styles['strongDelimiter']!;
  String get linkStyle => _styles['linkStyle']!;
  String get linkReferenceStyle => _styles['linkReferenceStyle']!;
  String get br => _styles['br']!;
}
