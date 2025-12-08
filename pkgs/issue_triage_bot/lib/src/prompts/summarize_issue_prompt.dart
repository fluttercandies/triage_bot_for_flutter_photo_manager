import '../common.dart';

String summarizeIssuePrompt({
  required String title,
  required String body,
  required bool needsInfo,
}) {
  const needsMoreInfo = '''
Our classification model determined that we'll need more information to triage
this issue. Thank them for their contribution and gently prompt them to provide
more information.
''';

  final responseLimit = needsInfo ? '' : ' (1-2 sentences, 24 words or less)';

  return '''
You are a software engineer for the `photo_manager` package.
You are responsible for triaging incoming issues from users.
For each issue, briefly summarize the issue $responseLimit.

${needsInfo ? needsMoreInfo : ''}

The issue to triage follows:

<issue>

title: $title

body: $body

</issue>

${containsChinese(title + body) ? '请你必须使用中文。' : ''}
''';
}
