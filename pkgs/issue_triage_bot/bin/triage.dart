// ignore_for_file: avoid_print

import 'dart:io' as io;

import 'package:args/args.dart';
import 'package:github/github.dart';
import 'package:http/http.dart' as http;
import 'package:issue_triage_bot/src/common.dart';
import 'package:issue_triage_bot/src/gemini.dart';
import 'package:issue_triage_bot/src/github.dart';
import 'package:issue_triage_bot/triage.dart';

void main(List<String> arguments) async {
  final argParser = ArgParser();
  argParser.addFlag(
    'dry-run',
    negatable: false,
    help: 'Perform triage but don\'t make any actual changes to the issue.',
  );
  argParser.addFlag(
    'force',
    negatable: false,
    help: 'Make changes to the issue even if it already looks triaged.',
  );
  argParser.addFlag(
    'release',
    negatable: false,
    help:
        'true: fluttercandies/flutter_photo_manager, false: fluttercandies/triage_bot_for_flutter_photo_manager',
  );
  argParser.addFlag('help', abbr: 'h', negatable: false, help: 'Print this usage information.');

  final ArgResults results;
  try {
    results = argParser.parse(arguments);
  } on ArgParserException catch (e) {
    _printUsage(argParser, error: e.message);
    io.exit(64);
  }

  if (results.flag('help') || results.rest.isEmpty) {
    _printUsage(argParser);
    io.exit(results.flag('help') ? 0 : 64);
  }

  final String issue = results.rest.first;
  final bool dryRun = results.flag('dry-run');
  final bool forceTriage = results.flag('force');
  final bool release = results.flag('release');
  final int issueId = _extractIssueId(issue, release);

  final client = http.Client();
  try {
    final github = GitHub(auth: Authentication.withToken(githubToken), client: client);
    final githubService = GithubService(github: github);
    final geminiService = GeminiService(apiKey: geminiKey, httpClient: client);

    await triage(
      issueId,
      dryRun: dryRun,
      forceTriage: forceTriage,
      isProductionRepo: release,
      githubService: githubService,
      geminiService: geminiService,
      logger: Logger(),
    );
  } finally {
    client.close();
  }
}

int _extractIssueId(String input, bool isRelease) {
  // Accept either an issue number or a url (i.e.,
  // https://github.com/fluttercandies/flutter_photo_manager/issues/1215).
  final repoSlug = getRepositorySlug(isRelease).toString();
  final issueToken = '$repoSlug/issues/';
  if (input.contains(issueToken)) {
    return int.parse(input.substring(input.indexOf(issueToken) + issueToken.length));
  }
  return int.parse(input);
}

const String usage = '''
A tool to triage issues from https://github.com/fluttercandies/flutter_photo_manager.

usage: dart bin/triage.dart [options] <issue>''';

void _printUsage(ArgParser parser, {String? error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print(usage);
  print('');
  print(parser.usage);
}
