// Compares html2md_plus with html2md 1.3.2 on every .html file in a folder.
//
// dart run tool/compare_with_html2md.dart <folder> [out folder]
import 'dart:io';

import 'package:html/parser.dart' as html_parser;
import 'package:html2md/html2md.dart' as original;
import 'package:html2md_plus/html2md_plus.dart' as plus;

void main(List<String> arguments) {
  final pages = Directory(arguments.first)
      .listSync()
      .whereType<File>()
      .where((file) => file.path.endsWith('.html'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  final outDirectory = arguments.length > 1 ? Directory(arguments[1]) : null;
  outDirectory?.createSync(recursive: true);

  var identical = 0;
  final originalWatch = Stopwatch();
  final plusWatch = Stopwatch();
  for (final page in pages) {
    final html = page.readAsStringSync();
    originalWatch.start();
    final expected = original.convert(_withoutScriptsAndStyles(html));
    originalWatch.stop();
    plusWatch.start();
    final actual = plus.convert(html);
    plusWatch.stop();
    final name = page.uri.pathSegments.last;
    if (expected == actual) {
      identical++;
    } else {
      stdout.writeln('DIFF $name');
      File('${outDirectory?.path}/$name.original.md')
          .writeAsStringSync(expected);
      File('${outDirectory?.path}/$name.plus.md').writeAsStringSync(actual);
    }
  }
  stdout
    ..writeln('$identical / ${pages.length} identical')
    ..writeln('html2md ${originalWatch.elapsedMilliseconds} ms, '
        'html2md_plus ${plusWatch.elapsedMilliseconds} ms');
}

/// html2md keeps the text of these elements, html2md_plus drops it. Removing
/// them first leaves only the other differences.
String _withoutScriptsAndStyles(String html) {
  final document = html_parser.parse(html);
  for (final element in document.querySelectorAll('script, style, template')) {
    element.remove();
  }
  return document.outerHtml;
}
