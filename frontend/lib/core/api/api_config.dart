class ApiConfig {
  static String get baseUrl {
    const override = String.fromEnvironment('SAFEBITE_API_URL');
    if (override.isNotEmpty) return override;
    return 'https://safebite-backend-knno.onrender.com/api';
  }
}
