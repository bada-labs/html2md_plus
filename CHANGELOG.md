# Changelog

## 2.0.0

First release as `html2md_plus`, the maintained successor of `html2md` 1.3.2.

- Every `convert` call is independent. Before, `styleOptions`, `imageBaseUrl`,
  `ignore` and `rules` stayed in effect for later calls, and each `ignore`
  added another rule that was never removed.
- A converted `dom.Node` is copied first and left unchanged.
- `script`, `style` and `template` are removed with their content, like
  `noscript`. Their text was printed as Markdown before.
- Whitespace at the edges of inline elements moves outside as it is, so
  `<strong>Text&nbsp;</strong>` becomes `**Text**&nbsp;` (jarontai/html2md#50).
  Spaces are no longer doubled next to text that already has one.
- A `!` right before a link or an image is escaped, so `Wow!<a>` no longer
  turns the link into an image (jarontai/html2md#54).
- Text inside URLs and inside inline code is not escaped
  (jarontai/html2md#51).
- Fenced code blocks read the language from the `code` element and keep the
  text of every highlighted span. Indented code blocks indent every line.
- `imageBaseUrl` works with sources that contain `+`, `(` or other regular
  expression characters.
- `Rule.addIgnore`, `Rule.addRules` and `Rule.findRule` are removed; pass
  `ignore` and `rules` to `convert`. `Rule.matches` tells whether a rule
  handles a node.
- Requires Dart 3.6. Depends on `html` only.

## 1.3.2
- Fix compiling warning (https://github.com/jarontai/html2md/issues/41)

## 1.3.1
- Allows multiple `code` blocks within the same `pre` tag

## 1.3.0
- In addition to html stirng, make the `convert` function accept dom.Node as well

## 1.2.6
- Enhance table rules (adapted from guyplusplus/turndown-plugin-gfm)

## 1.2.5
- Export html2md's Node class
- New custom rule test

## 1.2.4
- Doc updates

## 1.2.3
- Doc updates

## 1.2.2
- Minor renaming and doc updates

## 1.2.1
- Fix custom rule exports

## 1.2.0
- Add custom rules

## 1.1.0
- Add support for strike elements

## 1.0.1
- Fix link rules properly converting titles
- Fix image src in windows system

## 1.0.0
- Support null safety

## 0.5.1
- Fix the replacement of thead and tbody

## 0.5.0
- Add basic table support

## 0.3.3
- Avoid parsing ol's empty start attribute

## 0.3.2
- Update analysis_options.yaml
- Cleanup source code
- Bump dependencies

## 0.3.1
- fix fenced codeBlockStyle problem when codeblock has no className

## 0.3.0
- Add ignore list

## 0.2.1
- Fix dependency error

## 0.2.0
- Fix the multiple child issue of indentedCodeBlock rule
- Support Dart 2

## 0.1.7

- Ignore invalid style options

## 0.1.6

- Remove noscript element and cleanup
- Fix pre node
- Update test

## 0.1.5

- Add named optional parameter 'styleOptions' to `convert`

## 0.1.4

- Remove the incorrect default value for 'rootTag'

## 0.1.3

- Fix for crash in Dart 2

## 0.1.2

- Fix 'rootTag' issue

## 0.1.1

- Add named optional parameter 'rootTag' to `convert`
- Add named optional parameter 'imageBaseUrl' to `convert`

## 0.1.0

- Cleanup
- Publish 0.1.0

## 0.0.1

- Initial version
