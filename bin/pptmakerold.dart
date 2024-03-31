import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_pptx/dart_pptx.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:remove_markdown/remove_markdown.dart';
import 'package:prompts/prompts.dart' as prompts;

// import '../src/security/security.dart';

const String version = '0.0.1';
String apiKey = '';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Show additional command output.',
    )
    ..addFlag(
      'version',
      negatable: false,
      help: 'Print the tool version.',
    );
}

void printUsage(ArgParser argParser) {
  print('Usage: dart classmaker.dart <flags> [arguments]');
  print(argParser.usage);
}

void main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  try {
    final ArgResults results = argParser.parse(arguments);
    bool verbose = false;

    // Process the parsed arguments.
    if (results.wasParsed('help')) {
      printUsage(argParser);
      return;
    }
    if (results.wasParsed('version')) {
      print('classmaker version: $version');
      return;
    }
    if (results.wasParsed('verbose')) {
      verbose = true;
    }

    // Act on the arguments provided.
    // print('Positional arguments: ${results.rest}');
    // if (verbose) {
    //   print('[VERBOSE] All arguments: ${results.arguments}');
    // }

    final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

    String topic = prompts.get('Topic of the presentation:');
    int slides = prompts.getInt(
      'Number of slides',
      defaultsTo: 10,
      chevron: false,
    );
    String fileName = prompts.get(
      'File name',
      defaultsTo: 'my_presentation.pptx',
    );
    String author = prompts.get(
      'Author name',
      defaultsTo: 'My Name',
    );

    String language = prompts.choose<String>(
      'Presentation language',
      [
        'Spanish',
        'English',
      ],
      defaultsTo: 'Spanish',
      interactive: true,
    )!;

    final String prompt = 'Write the structure of a presentation about $topic. '
        'It should be $slides slides long. '
        'The presentation should be in JSON Format. '
        'The presentation should be in $language. '
        'The author name is $author.'
        'If there are any quotes, they should use single quotes instead of double quotes.\n'
        'Double quotes should only appear when the JSON structure requires it.\n'
        'Every slide should described as an object of the following types: \n'
        'Title Slide: { "type": "title", "title": "example", "author": "Example Name" }\n'
        'Title and Bullets Slide: { "type": "title-and-bullets", "title": "example", "subtitle": "example", "bullets": ["Bullet 1", "Bullet 2", "Bullet 3"] }\n'
        'The response should be an array of such objects.';
    final content = [Content.text(prompt)];
    print('Generating presentation...');
    final response = await model.generateContent(
      content,
      safetySettings: [
        // SafetySetting(
        //   HarmCategory.unspecified,
        //   HarmBlockThreshold.none,
        // ),
      ],
      generationConfig: GenerationConfig(
        maxOutputTokens: 9999999,
      ),
    );

    // print('=========');
    // print(response.text);
    // print('=========');

    try {
      String markdownString = response.text ?? '[]';
      String cleanText = markdownString.removeMarkdown();

      List<dynamic> parsed = jsonDecode(cleanText);
      List<Map> items = parsed.map((e) => e as Map).toList();

      final pres = PowerPoint();
      for (var item in items) {
        if (item['type'] == 'title') {
          pres.addTitleSlide(
            title: TextValue.uniform(item['title']),
            author: TextValue.uniform(item['author']),
          );
        } else if (item['type'] == 'title-and-bullets') {
          pres.addTitleAndBulletsSlide(
            title: TextValue.uniform(item['title']),
            bullets: (item['bullets'] as List)
                .map((e) => TextValue.uniform(e))
                .toList(),
          );
        }
        // pres.addAgendaSlide(
        //   title: TextValue.uniform(item.title),
        //   subtitle: TextValue.uniform(item.content),
        // );
      }

      final bytes = await pres.save();
      final file = File(fileName);
      await file.writeAsBytes(bytes as List<int>);
      print('Presentation generated!');
    } catch (e) {
      rethrow;
    }

    return;

    // build_powerpoint();
  } on FormatException catch (e) {
    // Print usage information if an invalid argument was provided.
    print(e);
    print(e.message);
    print('');
    printUsage(argParser);
  }
}
