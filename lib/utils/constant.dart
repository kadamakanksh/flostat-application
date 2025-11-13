// constants.dart

class Roles {
  static const String SUPER_ADMIN = "root";
  static const String ADMIN = "admin";
  static const String CONTROLLER = "controller";
  static const String GUEST = "guest";
}

const List<String> giveRoles = [
  "admin",
  "controller",
  "guest",
];

class RoleStatus {
  static const String PENDING = "pending";
  static const String ACTIVE = "active";
  static const String DEACTIVE = "deactive";
}

const List<String> deviceType = [
  "pump",
  "sump",
  "tank",
  "valve",
];

class DeviceType {
  static const String PUMP = "pump";
  static const String SUMP = "sump";
  static const String VALVE = "valve";
  static const String TANK = "tank";
}

class PumpStatus {
  static const String ON = "ON";
  static const String OFF = "OFF";
}

class ValveStatus {
  static const String OPEN = "OPEN";
  static const String CLOSE = "CLOSE";
}

// ---------------- WebSocket / AWS Config -----------------
const String AWS_REGION = String.fromEnvironment('REACT_APP_AWS_REGION');
const String IDENTITY_POOL = String.fromEnvironment('REACT_APP_COGNITO_IDENTITY_POOL_ID');
const String IOT_ENDPOINT = String.fromEnvironment('REACT_APP_IOT_ENDPOINT');
const String BASE_URL_LAMBDA = String.fromEnvironment('REACT_APP_BASE_URL_LAMBDA');

// Topics to auto-(re)subscribe
const List<String> DEFAULT_TOPICS = ["pump/status"];

// Reconnect / backoff
const int BASE_RECONNECT_MS = 1000;   // min backoff
const int MAX_RECONNECT_MS = 30000;   // max backoff
const int KEEPALIVE_SEC = 60;

// Credential refresh cooldown
const int REFRESH_COOLDOWN_MS = 60000;

class Mode {
  static const String MANUAL = "manual";
  static const String AUTO = "auto";
}

class SchedulePendingStatus {
  static const String CREATING = "CREATING";
  static const String UPDATING = "UPDATING";
  static const String DELETING = "DELETING";
}

class ScheduleCompletedStatus {
  static const String CREATED = "CREATED";
  static const String UPDATED = "UPDATED";
  static const String DELETED = "DELETED";
}

// Map pending → completed
final Map<String, String> SCHEDULE_STATUS_MAP = {
  SchedulePendingStatus.CREATING: ScheduleCompletedStatus.CREATED,
  ScheduleCompletedStatus.CREATED: ScheduleCompletedStatus.CREATED,
  SchedulePendingStatus.UPDATING: ScheduleCompletedStatus.UPDATED,
  ScheduleCompletedStatus.UPDATED: ScheduleCompletedStatus.UPDATED,
  SchedulePendingStatus.DELETING: ScheduleCompletedStatus.DELETED,
  ScheduleCompletedStatus.DELETED: ScheduleCompletedStatus.DELETED,
};

class UserDevice {
  static const String MOBILE = "mobile";
  static const String LAPTOP = "laptop";
  static const String DESKTOP = "desktop";
}