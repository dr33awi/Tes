abstract class LoggerService {
  void debug({required String message, dynamic data});
  void info({required String message, dynamic data});
  void warning({required String message, dynamic data});
  void error({required String message, dynamic error, StackTrace? stackTrace});
}