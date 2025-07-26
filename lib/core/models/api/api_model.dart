enum ApiProviders { chutes, google, pollinations }

class ApiModel {
  final String baseURL;
  final String? baseURL2;
  final String apiKey;
  final String modelName;
  final ApiProviders provider;
  Map<String, String>? headers;

  ApiModel({
    required this.baseURL,
    this.baseURL2,
    required this.apiKey,
    required this.modelName,
    required this.provider,
    this.headers,
  }) {
    headers ??= {"Authorization": "Bearer $apiKey", "Content-Type": "application/json"};
  }
}
