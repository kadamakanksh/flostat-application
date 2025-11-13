const String BASE_URL = "https://us9si083nf.execute-api.ap-south-1.amazonaws.com/api/v1";

class AuthEndpoints {
  static const String sendOtp = "$BASE_URL/auth/sendOtp";
  static const String verifyOtp = "$BASE_URL/auth/verifyOtp";
  static const String login = "$BASE_URL/auth/login";
  static const String signUp = "$BASE_URL/auth/signUp";
  static const String googleOauth = "$BASE_URL/auth/googleOuth";
}

class OrgEndpoints {
  static const String createOrg = "$BASE_URL/org";
  static const String updateOrg = "$BASE_URL/org/:org_id";
  static const String deleteOrg = "$BASE_URL/org/:org_id";
  static const String getSingleOrg = "$BASE_URL/org/:org_id";
  static const String getAllUsersForOrg = "$BASE_URL/org/:org_id/users";
  static const String getOrgTopics = "$BASE_URL/org/:org_id/getOrgTopics";
  static const String logsOrgTopics = "$BASE_URL/org/logs";
}

class UserEndpoints {
  static const String getAllOrgsOfUser = "$BASE_URL/user/getOrgsUser";
  static const String inviteUser = "$BASE_URL/user/inviteUser";
  static const String acceptInvite = "$BASE_URL/user/acceptInvite";
  static const String updateAccess = "$BASE_URL/user/updateAccess";
  static const String removeUser = "$BASE_URL/user/removeUser";
}

class DeviceEndpoints {
  static const String createDevice = "$BASE_URL/device/create";
  static const String updateDevice = "$BASE_URL/device/updateDevice";
  static const String deleteDevice = "$BASE_URL/device/deleteDevice";
  static const String registerDevice = "$BASE_URL/device/register";
  static const String getOrgAllDevice = "$BASE_URL/device/getOrgDevices";
  static const String getDeviceParents = "$BASE_URL/device/getDeviceParents";
  static const String updateBlock = "$BASE_URL/device/block/updateBlock";
  static const String createBlock = "$BASE_URL/device/block/createBlock";
  static const String deleteBlock = "$BASE_URL/device/block/deleteBlock";
  static const String getBlockById = "$BASE_URL/device/block/getBlockById";
  static const String getBlocksOfOrgId = "$BASE_URL/device/block/getBlocksOfOrgId";
  static const String getDeviceWithStatus = "$BASE_URL/device/getDeviceWithStatus/:org_id";
  static const String updateDeviceStatus = "$BASE_URL/device/updateDeviceStatus";

  static const String getBlockMode = "$BASE_URL/device/block/getBlockMode";
  static const String changeBlockMode = "$BASE_URL/device/block/changeMode";
}

class SupportEndpoints {
  static const String createQuery = "$BASE_URL/user/createQuery";
  static const String updateQuery = "$BASE_URL/user/updateQuery";
  static const String deleteQuery = "$BASE_URL/user/deleteQuery";
  static const String getQuery = "$BASE_URL/user/getQuery";
  static const String getAllOrgQuery = "$BASE_URL/user/getAllOrgQuery";
  static const String customerSupportChat = "$BASE_URL/user/customerSupportChat";
}
