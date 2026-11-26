import 'package:html2md_plus/html2md_plus.dart' as html2md;

void main() {
  const html = '''
<h1>Release notes</h1>
<p>Convert <strong>HTML</strong> to <a href="https://commonmark.org">Markdown</a>.</p>
<ul>
  <li>Tables</li>
  <li>Code blocks</li>
</ul>
<pre><code class="language-dart">print('hello');</code></pre>''';

  print(html2md.convert(
    html,
    styleOptions: {'headingStyle': 'atx', 'codeBlockStyle': 'fenced'},
  ));
}
