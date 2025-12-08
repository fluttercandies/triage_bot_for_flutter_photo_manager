import 'dart:io';

import 'package:github/github.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'src/common.dart';
import 'src/gemini.dart';
import 'src/github.dart';
import 'src/prompts/assign_area_prompt.dart';
import 'src/prompts/summarize_issue_prompt.dart';
import 'src/prompts/summarize_issue_title_prompt.dart';

RepositorySlug getRepositorySlug(bool isProductionRepo) => isProductionRepo
    ? RepositorySlug('fluttercandies', 'flutter_photo_manager')
    : RepositorySlug('fluttercandies', 'triage_bot_for_flutter_photo_manager');

Future<void> triage(
  int issueNumber, {
  bool dryRun = false,
  bool forceTriage = false,
  bool isProductionRepo = false,
  required GithubService githubService,
  required GeminiService geminiService,
  required Logger logger,
}) async {
  final sdkSlug = getRepositorySlug(isProductionRepo);

  logger.log('Triaging $sdkSlug...\n');

  // retrieve the issue
  final issue = await githubService.fetchIssue(sdkSlug, issueNumber);
  logger.log('## issue ${issue.htmlUrl}\n');
  final existingLabels = [for (final label in issue.labels) label.name];
  if (existingLabels.isNotEmpty) {
    logger.log('labels: ${existingLabels.join(', ')}\n');
  }
  logger.log('"${issue.title}"\n');
  final bodyLines = issue.body.split('\n').where((line) => line.trim().isNotEmpty).toList();
  for (final line in bodyLines.take(4)) {
    logger.log(line);
  }
  if (bodyLines.length > 4) {
    logger.log('...');
  }
  logger.log('');

  /// If the issue has any comments, retrieve and include the last comment in the prompt.
  String? lastComment;
  if (issue.hasComments) {
    final comments = await githubService.fetchIssueComments(sdkSlug, issue);
    final comment = comments.last;

    lastComment =
        '''
---

Here is the last comment on the issue (by user @${comment.user?.login}):

${trimmedBody(comment.body ?? '')}
''';
  }

  /// decide if we should triage
  if (!forceTriage && issue.alreadyTriaged) {
    logger.log('Exiting (issue is already triaged).');
    return;
  }

  final String bodyTrimmed = trimmedBody(issue.body);

  /// ask for classification
  final List<String> newLabels = await handleGemini(
    () => geminiService.classify(
      assignAreaPrompt(title: issue.title, body: bodyTrimmed, lastComment: lastComment),
    ),
  );

  /// If an issue already has a `Type:` label, we don't need to apply more.
  if (existingLabels.any((label) => label.startsWith('Type:'))) {
    newLabels.removeWhere((label) => label.startsWith('Type:'));
  }

  /// ask for the summary
  final String summary = await handleGemini(
    () => geminiService.summarize(
      summarizeIssuePrompt(
        title: issue.title,
        body: bodyTrimmed,
        needsInfo: newLabels.contains('Status: Need more info'),
      ),
    ),
  );

  /// ask for the issue title
  final String issueTitle = await handleGemini(
    () => geminiService.summarize(summarizeIssueTitlePrompt(title: issue.title, body: bodyTrimmed)),
  );

  logger.log('## gemini issue title \n$issueTitle\n');
  logger.log('## gemini summary \n$summary\n');
  logger.log('## gemini classification \n${newLabels.toString()}\n');

  if (dryRun) {
    logger.log('Exiting (dry run mode - not applying changes).');
    return;
  }

  /// perform changes
  logger.log('## github comment \nlabels: $newLabels\n$summary');

  final comment = '**AI Summary:** $summary\n';

  /// create github comment
  await githubService.createComment(sdkSlug, issueNumber, comment);

  final allRepoLabels = await githubService.getAllLabels(sdkSlug);
  final labelAdditions = filterLegalLabels(newLabels, allRepoLabels: allRepoLabels);
  if (labelAdditions.isNotEmpty) {
    labelAdditions.add('Automation: triage');
  }

  /// apply github labels
  if (newLabels.isNotEmpty) {
    await githubService.addLabelsToIssue(sdkSlug, issueNumber, labelAdditions);
  }

  /// update github issue title
  await githubService.updateIssueTitle(sdkSlug, issueNumber, issueTitle);

  logger.log('\n---\n');
  logger.log('Triaged ${issue.htmlUrl}');
}

List<String> filterLegalLabels(List<String> labels, {required List<String> allRepoLabels}) {
  final validLabels = allRepoLabels.toSet();
  return [
    for (final String label in labels)
      if (validLabels.contains(label)) label,
  ]..sort();
}

Future<T> handleGemini<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on GenerativeAIException catch (e) {
    // Failures here can include things like gemini safety issues, ...
    stderr.writeln('Gemini: $e');
    exit(1);
  }
}
