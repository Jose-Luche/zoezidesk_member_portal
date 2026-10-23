/// Build-time configuration, supplied with
/// `--dart-define-from-file=env/<name>.json`. Nothing here is hardcoded.
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static bool get isConfigured => apiBaseUrl.isNotEmpty;
}
