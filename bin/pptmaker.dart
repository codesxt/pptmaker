import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:dart_pptx/dart_pptx.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:prompts/prompts.dart' as prompts;

import '../src/helpers/markdown.dart';
import '../src/helpers/slides.dart';

String apiKey = '';
String appName = 'pptmaker';

ArgParser buildParser() {
  return ArgParser()
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    )
    ..addFlag(
      'config',
      abbr: 'c',
      negatable: false,
      help: 'Allows to configure api key.',
    )
    ..addFlag(
      'clear-config',
      abbr: null,
      negatable: false,
      help: 'Clears all configurations.',
    );
}

String getHome() {
  // String os = Platform.operatingSystem;
  String home = "";
  Map<String, String> envVars = Platform.environment;
  if (Platform.isMacOS) {
    home = envVars['HOME'] ?? '';
  } else if (Platform.isLinux) {
    home = envVars['HOME'] ?? '';
  } else if (Platform.isWindows) {
    home = envVars['UserProfile'] ?? '';
  }
  return home;
}

void main(List<String> arguments) async {
  final ArgParser argParser = buildParser();
  String homeDir = getHome();
  File settingsFile = File('$homeDir/.$appName.json');
  if (!settingsFile.existsSync()) {
    settingsFile = await settingsFile.create();
    settingsFile.writeAsStringSync(
      '{ "apikey": "" }',
      flush: true,
    );
  }

  String settingsFileContents = await settingsFile.readAsString();
  Map settings =
      settingsFileContents.isEmpty ? {} : jsonDecode(settingsFileContents);

  String? apiKey = settings['apikey'];
  try {
    final ArgResults results = argParser.parse(arguments);
    // Process the parsed arguments.
    if (results.wasParsed('config')) {
      print('Add a key for the Gemini API.');
      print(
          'You can get one in the following URL: https://makersuite.google.com/app/apikey?hl=es-419');
      String apiKey = prompts.get(
        'Gemini API Key:',
        conceal: true,
      );
      if (apiKey.isNotEmpty) {
        // Guardar apikey
        settingsFile.writeAsStringSync('{ "apikey": "$apiKey" }');
      }
      return;
    }
    if (results.wasParsed('clear-config')) {
      settingsFile.writeAsStringSync(
        '{ "apikey": "" }',
        flush: true,
      );
      return;
    }
  } catch (e) {
    rethrow;
  }

  if (apiKey == null || apiKey.isEmpty) {
    print('A valid API key for the Gemini app is needed.');
    print('Please add one by running \'pptmaker --config\'');
    return;
  }

  final model = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);

  String topic = prompts.get('Topic of the presentation:');
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
  print('\n');

  final chat = model.startChat(
    history: [
      Content.text(
        'You are PPT Maker. You will help in the '
        'generation of PowerPoint presentations.',
      ),
      Content.model(
        [
          TextPart('Hi! I\'m PPT Maker. What can I do for you?'),
        ],
      ),
    ],
  );
  print('> Generating presentation...');

  final String prompt = 'Write the structure of a presentation about $topic. '
      'The presentation should be in $language. '
      'The author name is $author.';
  final startingPrompt = Content.text(prompt);
  GenerateContentResponse response = await chat.sendMessage(startingPrompt);
  // print(response.text);

  final String titlesPrompt = 'Write only the titles of each section. '
      'Write each title in its own line. '
      'Don\'t add a header to the response, only each title. '
      'No bullets at the start of each title. '
      'Don\'t use any markdown in this answer. '
      'Keep the titles in the same language as they were.';

  GenerateContentResponse titlesResponse = await chat.sendMessage(
    Content.text(titlesPrompt),
  );
  // print(titlesResponse.text);

  String sectionTitles = titlesResponse.text!;

  PowerPoint pres = PowerPoint();

  for (var title in sectionTitles.split('\n')) {
    print('>> Expanding on section: $title');

    final String prompt = 'Expand on section: $title.';

    GenerateContentResponse response = await chat.sendMessage(
      Content.text(prompt),
    );

    // print(response.text);
    print('>>> Section $title expanded');

    final String prompt2 = 'Transform the expanded contents of section '
        '$title into JSON objects. \n'
        'Each object should be created using one of the following options: \n'
        ' * Title Slide: { "type": "title", "title": "example", "author": "Example Name" }\n'
        ' * Title and Bullets Slide: { "type": "title-and-bullets", "title": "example", "subtitle": "example", "bullets": ["Bullet 1", "Bullet 2", "Bullet 3"] }\n'
        'One JSON object represents a single slide. '
        'The result should be a JSON Array.';
    GenerateContentResponse response2 = await chat.sendMessage(
      Content.text(prompt2),
    );

    print('>>> Section $title transformed into JSON');
    // print(response2.text);

    String clean = MarkdownHelper.removeMarkdown(response2.text ?? '[]');
    List<dynamic> parsed = jsonDecode(clean);
    List<Map> items = parsed.map((e) => e as Map).toList();

    for (var item in items) {
      SlidesHelper.addJsonToSlide(pres, item);
    }
  }

  final bytes = await pres.save();
  final file = File(fileName);
  await file.writeAsBytes(bytes as List<int>);
  print('Presentation generated and saved as $fileName');
}
