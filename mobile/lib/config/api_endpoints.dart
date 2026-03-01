class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authRegister = '/api/auth/register';
  static const String authLogin = '/api/auth/login';
  static const String authRefresh = '/api/auth/refresh';

  // Plates
  static const String plates = '/api/plates';
  static String plateRelease(String id) => '/api/plates/$id';

  // Messages
  static const String messagesSend = '/api/messages';
  static const String messagesInbox = '/api/messages/inbox';
  static const String messagesSent = '/api/messages/sent';
  static const String messagesUnreadCount = '/api/messages/unread-count';
  static String messageDetail(String id) => '/api/messages/$id';
  static String messageMarkRead(String id) => '/api/messages/$id/read';
  static String messageAddReply(String id) => '/api/messages/$id/replies';

  // Reports
  static const String reportsCreate = '/api/reports';

  // Devices
  static const String devicesRegister = '/api/devices';
  static String devicesRemove(String token) => '/api/devices/$token';

  // Health
  static const String health = '/health';
}
