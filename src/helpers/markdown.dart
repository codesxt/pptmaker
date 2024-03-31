import 'package:remove_markdown/remove_markdown.dart';

class MarkdownHelper {
  static String removeMarkdown(String text) {
    return text.removeMarkdown();
  }
}
