import 'package:html/parser.dart' as html_parser;
import 'package:html2md_plus/html2md_plus.dart' as html2md;
import 'package:test/test.dart';

void main() {
  group('Each call is independent', () {
    test('style options apply to their own call only', () {
      expect(
        html2md
            .convert('<h1>Title</h1>', styleOptions: {'headingStyle': 'atx'}),
        '# Title',
      );
      expect(html2md.convert('<h1>Title</h1>'), 'Title\n=====');
    });

    test('an invalid style option falls back to the default', () {
      expect(
        html2md.convert('<h1>Title</h1>', styleOptions: {'headingStyle': 'x'}),
        'Title\n=====',
      );
    });

    test('image base URL applies to its own call only', () {
      const image = '<img src="a.png">';
      expect(
        html2md.convert(image, imageBaseUrl: 'https://example.com'),
        '![](https://example.com/a.png)',
      );
      expect(html2md.convert(image), '![](a.png)');
    });

    test('ignored elements apply to their own call only', () {
      const html = '<p>keep</p><aside>side</aside>';
      expect(html2md.convert(html, ignore: ['aside']), 'keep');
      expect(html2md.convert(html), 'keep\n\nside');
    });

    test('custom rules apply to their own call only', () {
      final shout = html2md.Rule(
        'shout',
        filters: ['b'],
        replacement: (content, node) => content.toUpperCase(),
      );
      expect(html2md.convert('<b>hi</b>', rules: [shout]), 'HI');
      expect(html2md.convert('<b>hi</b>'), '**hi**');
    });

    test('link references are numbered per call', () {
      const link = '<a href="https://example.com">site</a>';
      const referenced = {'linkStyle': 'referenced'};
      const expected = '[site][1]\n\n[1]: https://example.com';
      expect(html2md.convert(link, styleOptions: referenced), expected);
      expect(html2md.convert(link, styleOptions: referenced), expected);
    });

    test('a converted dom.Node is left unchanged', () {
      final body = html_parser.parse('<p>a   b</p><script>x()</script>').body!;
      final before = body.outerHtml;
      expect(html2md.convert(body), 'a b');
      expect(body.outerHtml, before);
    });
  });

  group('Whitespace', () {
    test('a non-breaking space moves outside of emphasis', () {
      expect(
        html2md.convert('<strong>Text&nbsp;</strong>next'),
        '**Text** next',
      );
    });

    test('an element holding only a non-breaking space keeps it', () {
      expect(
        html2md.convert('<p>media<span>&nbsp;</span>type</p>'),
        'media type',
      );
    });

    test('no space is doubled next to text that already ends with one', () {
      expect(html2md.convert('<p>see <b> bold</b></p>'), 'see **bold**');
    });
  });

  group('Escaping', () {
    test('a ! before a link is escaped so the link stays a link', () {
      expect(
        html2md.convert('<p>Wow!<a href="https://example.com">site</a></p>'),
        r'Wow\![site](https://example.com)',
      );
    });

    test('a ! before an image is escaped', () {
      expect(
        html2md.convert('<div>Wow!<img src="path.png"></div>'),
        r'Wow\!![](path.png)',
      );
    });

    test('underscores in a URL are not escaped', () {
      expect(
        html2md.convert('<p>https://example.com/a_b_c and _x_</p>'),
        r'https://example.com/a_b_c and \_x\_',
      );
    });

    test('text inside inline code is not escaped', () {
      expect(
        html2md.convert('<code>s[:i] + a_b_c * 2</code>'),
        '`s[:i] + a_b_c * 2`',
      );
    });
  });

  group('Elements without readable text', () {
    test('script, style and template are removed', () {
      expect(
        html2md.convert(
          '<head><style>p{}</style><script>x()</script></head>'
          '<body><template><p>t</p></template><p>Hello</p></body>',
        ),
        'Hello',
      );
    });
  });

  group('Code blocks', () {
    const highlighted = '<pre><code class="language-dart">'
        '<span>void</span> main() {\n  <span>print</span>(1);\n'
        '<span>}</span>\n</code></pre>';

    test('fenced code keeps the language and every highlighted span', () {
      expect(
        html2md
            .convert(highlighted, styleOptions: {'codeBlockStyle': 'fenced'}),
        '```dart\nvoid main() {\n  print(1);\n}\n\n```',
      );
    });

    test('indented code indents every line, including the last span', () {
      expect(
        html2md.convert(highlighted),
        '    void main() {\n      print(1);\n    }',
      );
    });
  });

  test('image sources with regular expression characters are kept', () {
    expect(
      html2md.convert(
        '<img src="a+b(1).png">',
        imageBaseUrl: 'https://example.com/',
      ),
      '![](https://example.com/a+b(1).png)',
    );
  });
}
