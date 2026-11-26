# html2md_plus

[![pub package](https://img.shields.io/pub/v/html2md_plus.svg)](https://pub.dev/packages/html2md_plus)
[![CI](https://github.com/bada-labs/html2md_plus/actions/workflows/ci.yaml/badge.svg)](https://github.com/bada-labs/html2md_plus/actions/workflows/ci.yaml)

Converts HTML to Markdown in pure Dart. Supports CommonMark, GitHub Flavored Markdown tables and custom rules.

This is the maintained successor of [`html2md`](https://pub.dev/packages/html2md), which has not been updated since 1.3.2 (2024). The `convert` function takes the same arguments, and on real web pages it produces the same text, with the bugs below fixed. Bada Labs uses it in its production apps.

## What's different from `html2md` 1.3.2

- **Every call is independent.** In `html2md`, `styleOptions`, `imageBaseUrl`, `ignore` and `rules` stayed in effect for every later call, and each `ignore` added a rule that was never removed. A converted `dom.Node` is no longer modified either.
- **No scripts or styles in the output.** `script`, `style` and `template` are removed with their content. `html2md` printed their JavaScript and CSS as text, which on a typical web page is most of the output.
- **Whitespace stays outside emphasis.** `<strong>Text&nbsp;</strong>` becomes `**Text**&nbsp;` instead of `**Text&nbsp;**`, which is not bold. Spaces are no longer doubled next to text that already has one.
- **Correct escaping.** A `!` right before a link is escaped so the link does not turn into an image. Underscores in URLs and text inside inline code are left as they are.
- **Code blocks keep every line.** Highlighted code split into spans keeps all its text in fenced blocks, keeps the language from `class="language-*"`, and stays indented to the last line in indented blocks.
- **`imageBaseUrl` works with any source**, including ones with `+` or `(`.

The original test suite runs unchanged in this repository. `tool/compare_with_html2md.dart` compares both packages on a folder of HTML pages.

## Migrating from `html2md`

1. In `pubspec.yaml`, replace `html2md` with `html2md_plus`.
2. Replace `package:html2md/html2md.dart` with `package:html2md_plus/html2md_plus.dart`.

If you called `Rule.addIgnore` or `Rule.addRules`, pass `ignore` or `rules` to `convert` instead.

## Usage

```dart
import 'package:html2md_plus/html2md_plus.dart' as html2md;

void main() {
  print(html2md.convert('<h2>Hello <em>world</em></h2>'));
  // Hello _world_
  // -------------
}
```

`convert` accepts an HTML string or a `dom.Node` from `package:html`.

### Options

| Argument | Description |
| --- | --- |
| `rootTag` | Element of an HTML string whose content is converted. Defaults to `html`. |
| `imageBaseUrl` | Put in front of every image source. |
| `styleOptions` | Markdown syntax to use, see below. |
| `ignore` | Element names left out together with their content. |
| `rules` | Custom rules, tried before the built-in ones. |

Style options, with the default first:

| Name | Values |
| --- | --- |
| `headingStyle` | `setext`, `atx` |
| `hr` | `* * *`, `- - -`, `_ _ _` |
| `bulletListMarker` | `*`, `-`, `_` |
| `codeBlockStyle` | `indented`, `fenced` |
| `fence` | ` ``` `, `~~~` |
| `emDelimiter` | `_`, `*` |
| `strongDelimiter` | `**`, `__` |
| `linkStyle` | `inlined`, `referenced` |
| `linkReferenceStyle` | `full`, `collapsed`, `shortcut` |

```dart
html2md.convert(
  html,
  styleOptions: {'headingStyle': 'atx', 'codeBlockStyle': 'fenced'},
  ignore: ['nav', 'footer'],
);
```

### Custom rules

A rule picks elements by name with `filters`, or with any test in `filterFn`, and returns their Markdown from `replacement`. The `content` passed to it is the already converted content of the element.

```dart
html2md.convert(
  html,
  rules: [
    html2md.Rule(
      'aside',
      filters: ['aside'],
      replacement: (content, node) => '\n\n> $content\n\n',
    ),
  ],
);
```

## Scope

This package fixes bugs and keeps up with Dart changes. New features are considered conservatively to keep it small and dependable.

## Credits

Based on [`html2md`](https://pub.dev/packages/html2md) by Jaron Tai, under the BSD 2-Clause license. The table rules are adapted from [turndown-plugin-gfm](https://github.com/mixmark-io/turndown-plugin-gfm) (MIT). Maintained by [Bada Labs](https://badalabs.com).
