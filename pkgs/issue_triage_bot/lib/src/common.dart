// ignore_for_file: avoid_print

import 'dart:io';

String? _envFileTokenOrEnvironment({required String key}) {
  final envFile = File('.env');
  if (envFile.existsSync()) {
    final env = <String, String>{};
    for (final String line
        in envFile.readAsLinesSync().map((line) => line.trim())) {
      if (line.isEmpty || line.startsWith('#')) continue;
      final int split = line.indexOf('=');
      env[line.substring(0, split).trim()] = line.substring(split + 1).trim();
    }
    return env[key];
  } else {
    return Platform.environment[key];
  }
}

String get githubToken {
  final String? token = _envFileTokenOrEnvironment(key: 'GITHUB_TOKEN');
  if (token == null) {
    throw StateError('This tool expects a github access token in the '
        'GITHUB_TOKEN environment variable.');
  }
  return token;
}

String get geminiKey {
  final String? token = _envFileTokenOrEnvironment(key: 'GEMINI_API_KEY');
  if (token == null) {
    throw StateError('This tool expects a gemini api key in the '
        'GEMINI_API_KEY environment variable.');
  }
  return token;
}

/// Maximal length of body used for querying.
const bodyLengthLimit = 10 * 1024;

/// The [body], truncated if larger than [bodyLengthLimit].
String trimmedBody(String body) {
  return body.length > bodyLengthLimit
      ? body = body.substring(0, bodyLengthLimit)
      : body;
}

class Logger {
  void log(String message) {
    print(message);
  }
}
