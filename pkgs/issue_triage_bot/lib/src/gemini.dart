import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;

class GeminiService {
  // Possible values for models: gemini-1.5-pro-latest, gemini-1.5-flash-latest,
  // gemini-1.0-pro-latest, gemini-1.5-flash-exp-0827.
  //
  // TODO(Amos): 目前 models/gemini-1.5-flash-latest 有些问题
  // （https://discuss.ai.google.dev/t/solved-gemini-models-overloading-with-token-windows-of-less-than-20/49579/7）
  //  临时换成 实验性的 gemini-exp-1114
  static const String classificationModel = 'models/gemini-exp-1114';
  static const String summarizationModel = 'models/gemini-exp-1114';

  final GenerativeModel _summarizeModel;
  final GenerativeModel _classifyModel;

  GeminiService({
    required String apiKey,
    required http.Client httpClient,
  })  : _summarizeModel = GenerativeModel(
          model: summarizationModel,
          apiKey: apiKey,
          generationConfig: GenerationConfig(temperature: 0.2),
          httpClient: httpClient,
        ),
        _classifyModel = GenerativeModel(
          // TODO(Amos): 之后有必要的话可以换成微调的模型（指定仓库的历史）
          // model: 'tunedModels/autotune-triage-tuned-prompt-xxx',
          model: classificationModel,
          apiKey: apiKey,
          generationConfig: GenerationConfig(temperature: 0.2),
          httpClient: httpClient,
        );

  /// Call the summarize model with the given prompt.
  ///
  /// On failures, this will throw a [GenerativeAIException].
  Future<String> summarize(String prompt) {
    return _query(_summarizeModel, prompt);
  }

  /// Call the classify model with the given prompt.
  ///
  /// On failures, this will throw a [GenerativeAIException].
  Future<List<String>> classify(String prompt) async {
    final result = await _query(_classifyModel, prompt);
    final labels = result.split(',').map((l) => l.trim()).toList()..sort();
    return labels;
  }

  Future<String> _query(GenerativeModel model, String prompt) async {
    final response = await model.generateContent([Content.text(prompt)]);
    return (response.text ?? '').trim();
  }
}
