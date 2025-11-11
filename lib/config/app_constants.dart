class AppConstants {
  // 🔹 Base URL of your backend
  static const String baseUrl = "https://us9si083nf.execute-api.ap-south-1.amazonaws.com/";

  // 🔹 API Endpoints
  static const String deviceApi = "${baseUrl}api/v1/device";
  static const String orgApi = "${baseUrl}api/v1/org";

  // 🔹 Keys used for storing data locally
  static const String authTokenKey = "auth_token";
  static const String selectedOrgKey = "selected_org";
  static const String userDataKey = "user_data";
  static const String defaultOrgId = "no_org_found";
 
}
