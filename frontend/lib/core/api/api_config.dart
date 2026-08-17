class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('SAFEBITE_API_URL');
    if (override.isNotEmpty) return override;
    return 'https://safe-bite-bocd.onrender.com/api';
  }
}
