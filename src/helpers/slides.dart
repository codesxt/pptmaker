import 'package:dart_pptx/dart_pptx.dart';

class SlidesHelper {
  static Slide addJsonToSlide(PowerPoint powerPoint, Map item) {
    if (item['type'] == 'title') {
      return powerPoint.addTitleSlide(
        title: TextValue.uniform(item['title']),
        author: TextValue.uniform(item['author']),
      );
    } else if (item['type'] == 'title-and-bullets') {
      return powerPoint.addTitleAndBulletsSlide(
        title: TextValue.uniform(item['title']),
        subtitle: TextValue.uniform(item['subtitle']),
        bullets: (item['bullets'] as List)
            .map(
              (e) => TextValue.uniform(e),
            )
            .toList(),
      );
    } else {
      throw Exception('Invalid type: ${item['type']}');
    }
  }
}
