import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  GeminiService({required String apiKey, required http.Client httpClient})
    : _summarizeModel = GenerativeModel(
        model: summarizationModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.2),
        httpClient: httpClient,
      ),
      _classifyModel = GenerativeModel(
        /// TODO(Amos): 之后有必要的话可以换成微调的模型（指定仓库的历史）
        /// model: 'tunedModels/autotune-triage-tuned-prompt-xxx',
        model: classificationModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(temperature: 0.2),
        httpClient: httpClient,
      );

  /// Possible values for models: gemini-1.5-pro-latest, gemini-1.5-flash-latest,
  /// gemini-1.0-pro-latest, gemini-1.5-flash-exp-0827.
  ///
  static const String classificationModel = 'models/gemini-2.5-flash';
  static const String summarizationModel = 'models/gemini-2.5-flash';

  final GenerativeModel _summarizeModel;
  final GenerativeModel _classifyModel;

  /// Call the summarize model with the given prompt.
  ///
  /// On failures, this will throw a [GenerativeAIException].
  Future<String> summarize(String prompt) async {
    return _query(_summarizeModel, prompt);
  }

  /// Call the classify model with the given prompt.
  ///
  /// On failures, this will throw a [GenerativeAIException].
  Future<List<String>> classify(String prompt) async {
    final result = await _query(_classifyModel, prompt);
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

  Future<String> _query(GenerativeModel model, String prompt) async {
    final response = await model.generateContent([Content.text(prompt)]);
    return (response.text ?? '').trim();
  }
}
