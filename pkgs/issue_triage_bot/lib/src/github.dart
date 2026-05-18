import 'package:github/github.dart';
import 'package:graphql/client.dart';

class GithubService {
  GithubService({required GitHub github}) : _gitHub = github;

  final GitHub _gitHub;

  late final AuthLink _graphQLAuth = AuthLink(getToken: () async => 'Bearer ${_gitHub.auth.token}');
  late final GraphQLClient _graphQLClient = GraphQLClient(
    link: _graphQLAuth.concat(HttpLink('https://api.github.com/graphql')),
    cache: GraphQLCache(),
  );

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

  /// Get the subscription status of the issue
  ///
  /// https://docs.github.com/en/graphql/reference/interfaces#subscribable
  ///
  /// - [slug]: Repository slug
  /// - [issueNumber]: Issue number
  Future<
    ({
      ///  The Node ID of the Subscribable object.
      String issueId,

      /// Check if the viewer is able to change their subscription status for the repository.
      bool viewerCanSubscribe,
    })
  >
  getSubscriptionStatusOfIssue(RepositorySlug slug, int issueNumber) async {
    const queryString = r'''
query GetIssue($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    issue(number: $number) {
      id
      number
      viewerCanSubscribe
      viewerSubscription
    }
  }
}
''';

    final result = await _graphQLClient.query(
      QueryOptions(
        document: gql(queryString),
        variables: {'owner': slug.owner, 'repo': slug.name, 'number': issueNumber},
        fetchPolicy: FetchPolicy.noCache,
        parserFn: (data) {
          final issueData = data['repository']?['issue'];
          if (issueData == null) {
            throw Exception('Issue not found');
          }
          return (
            issueId: issueData['id'] as String,
            viewerCanSubscribe: issueData['viewerCanSubscribe'] as bool,
          );
        },
      ),
    );
    return result.hasException ? throw result.exception! : result.parsedData!;
  }

  /// Unsubscribe issue
  ///
  /// https://docs.github.com/en/graphql/reference/mutations#updatesubscription
  ///
  /// - [slug]: Repository slug
  /// - [issueNumber]: Issue number
  Future<bool> unsubscribeIssue(RepositorySlug slug, int issueNumber) async {
    final (:issueId, :viewerCanSubscribe) = await getSubscriptionStatusOfIssue(slug, issueNumber);
    if (!viewerCanSubscribe) {
      throw Exception('Viewer cannot change subscription status for this issue');
    }

    final mutationString = r'''
mutation UnsubscribeIssue($subscribableId: ID!) {
  updateSubscription(input: {
    subscribableId: $subscribableId,
    state: UNSUBSCRIBED
  }) {
    subscribable {
      id
      viewerSubscription
    }
  }
}
''';

    final result = await _graphQLClient.mutate(
      MutationOptions(
        document: gql(mutationString),
        variables: {'subscribableId': issueId},
        fetchPolicy: FetchPolicy.noCache,
        parserFn: (data) {
          final subscriptionData = data['updateSubscription']?['subscribable'];
          if (subscriptionData == null) {
            throw Exception('Failed to unsubscribe issue');
          }
          return subscriptionData['viewerSubscription'] == 'IGNORED';
        },
      ),
    );
    return result.hasException ? throw result.exception! : result.parsedData!;
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
