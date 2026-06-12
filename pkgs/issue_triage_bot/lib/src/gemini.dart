import 'package:googleai_dart/googleai_dart.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  GeminiService({required String apiKey, required http.Client httpClient})
    : _client = GoogleAIClient(
        config: GoogleAIConfig(
          authProvider: ApiKeyProvider(apiKey),
          baseUrl: 'https://generativelanguage.googleapis.com',
          apiMode: ApiMode.googleAI,
          apiVersion: ApiVersion.v1beta,
          timeout: const Duration(minutes: 5),
          retryPolicy: const RetryPolicy(
            maxRetries: 3,
            initialDelay: Duration(seconds: 1),
            maxDelay: Duration(seconds: 60),
            jitter: 0.1,
          ),
        ),
        httpClient: httpClient,
      );

  final GoogleAIClient _client;

  /// Possible values for models: gemini-1.5-pro-latest, gemini-1.5-flash-latest,
  /// gemini-1.0-pro-latest, gemini-1.5-flash-exp-0827.
  ///
  /// TODO(Amos): 之后有必要的话可以换成微调的模型（指定仓库的历史），
  /// 通过 [GoogleAIClient.tunedModels] 调用，例如 `autotune-triage-tuned-prompt-xxx`。
  static const String classificationModel = 'gemini-2.5-flash';
  static const String summarizationModel = 'gemini-2.5-flash';

  /// Shared generation configuration for both models.
  static const GenerationConfig _generationConfig = GenerationConfig(temperature: 0.2);

  /// Call the summarize model with the given prompt.
  ///
  /// On failures, this will throw a [GoogleAIException].
  Future<String> summarize(String prompt) async {
    return _query(summarizationModel, prompt);
  }

  /// Call the classify model with the given prompt.
  ///
  /// On failures, this will throw a [GoogleAIException].
  Future<List<String>> classify(String prompt) async {
    final result = await _query(classificationModel, prompt);
    final labels =
        result
            .split(',')
            .map((label) => label.trim())
            .where((label) => label.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return labels;
  }

  Future<String> _query(String model, String prompt) async {
    final response = await _client.models.generateContent(
      model: model,
      request: GenerateContentRequest(
        contents: [Content.text(prompt)],
        generationConfig: _generationConfig,
      ),
    );
    return (response.text ?? '').trim();
  }
}
