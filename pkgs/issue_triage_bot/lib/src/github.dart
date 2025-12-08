import 'package:github/github.dart';

class GithubService {
  GithubService({required GitHub github}) : _gitHub = github;

  final GitHub _gitHub;

  Future<List<String>> getAllLabels(RepositorySlug repoSlug) async {
    final result = await _gitHub.issues.listLabels(repoSlug).toList();
    return result.map((item) => item.name).toList();
  }

  Future<Issue> fetchIssue(RepositorySlug slug, int issueNumber) async {
    return _gitHub.issues.get(slug, issueNumber);
  }

  Future<List<IssueComment>> fetchIssueComments(RepositorySlug slug, Issue issue) async {
    return _gitHub.issues.listCommentsByIssue(slug, issue.number).toList();
  }

  Future createComment(RepositorySlug sdkSlug, int issueNumber, String comment) async {
    await _gitHub.issues.createComment(sdkSlug, issueNumber, comment);
  }

  Future<void> addLabelsToIssue(
    RepositorySlug sdkSlug,
    int issueNumber,
    List<String> newLabels,
  ) async {
    await _gitHub.issues.addLabelsToIssue(sdkSlug, issueNumber, newLabels);
  }

  /// Update the issue title
  ///
  /// - [slug]: Repository slug
  /// - [issueNumber]: Issue number
  /// - [title]: New title
  Future<Issue> updateIssueTitle(RepositorySlug slug, int issueNumber, String title) async {
    return _gitHub.issues.edit(slug, issueNumber, IssueRequest(title: title));
  }
}

extension IssueExtension on Issue {
  /// Returns whether this issue has any comments.
  ///
  /// Note that the original text for the issue is returned in the `body` field.
  bool get hasComments => commentsCount > 0;

  /// Returns whether this issue has already been triaged.
  ///
  /// Generally, this means the the issue has had an `Platform:` label applied to
  /// it, has had `Status: Need more info` applied to it, or was closed.
  bool get alreadyTriaged {
    if (isClosed) return true;

    return labels.any((label) {
      final name = label.name;
      return name == 'Status: Need more info' || name.startsWith('Platform:');
    });
  }
}
