// lib/services/retry_service.dart
import 'dart:async';
import 'dart:math';
import 'package:test_athkar_app/services/error_logging_service.dart';

/// استراتيجية إعادة المحاولة
enum RetryStrategy {
  /// إعادة محاولة فورية بدون تأخير
  immediate,
  
  /// تأخير ثابت بين المحاولات
  fixedDelay,
  
  /// تأخير أسي (يتضاعف مع كل محاولة)
  exponentialBackoff,
  
  /// تأخير أسي مع عنصر عشوائي (لتجنب التزامن)
  exponentialBackoffWithJitter,
}

/// تكوين إعادة المحاولة
class RetryConfig {
  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;
  final RetryStrategy strategy;
  final double exponentialBase;
  final List<Type> retryableExceptions;
  
  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.strategy = RetryStrategy.exponentialBackoff,
    this.exponentialBase = 2.0,
    this.retryableExceptions = const [],
  });
  
  /// تكوين افتراضي لطلبات الشبكة
  static const RetryConfig networkDefault = RetryConfig(
    maxAttempts: 3,
    initialDelay: Duration(seconds: 1),
    maxDelay: Duration(seconds: 10),
    strategy: RetryStrategy.exponentialBackoffWithJitter,
  );
  
  /// تكوين افتراضي لقاعدة البيانات
  static const RetryConfig databaseDefault = RetryConfig(
    maxAttempts: 5,
    initialDelay: Duration(milliseconds: 100),
    maxDelay: Duration(seconds: 5),
    strategy: RetryStrategy.exponentialBackoff,
  );
  
  /// تكوين افتراضي للعمليات السريعة
  static const RetryConfig quickDefault = RetryConfig(
    maxAttempts: 2,
    initialDelay: Duration(milliseconds: 100),
    maxDelay: Duration(seconds: 1),
    strategy: RetryStrategy.fixedDelay,
  );
}

/// نتيجة عملية إعادة المحاولة
class RetryResult<T> {
  final bool success;
  final T? value;
  final dynamic error;
  final int attempts;
  final Duration totalDuration;
  
  RetryResult({
    required this.success,
    this.value,
    this.error,
    required this.attempts,
    required this.totalDuration,
  });
  
  bool get failed => !success;
}

/// خدمة إعادة المحاولة
class RetryService {
  final ErrorLoggingService _errorLoggingService;
  final Random _random = Random();
  
  RetryService({
    required ErrorLoggingService errorLoggingService,
  }) : _errorLoggingService = errorLoggingService;
  
  /// تنفيذ عملية مع إعادة المحاولة
  Future<RetryResult<T>> executeWithRetry<T>({
    required Future<T> Function() operation,
    required String operationName,
    RetryConfig? config,
    bool Function(dynamic error)? shouldRetry,
    void Function(int attempt, dynamic error)? onRetry,
    void Function(dynamic error)? onError,
  }) async {
    config ??= RetryConfig();
    
    final startTime = DateTime.now();
    int attempt = 0;
    dynamic lastError;
    
    while (attempt < config.maxAttempts) {
      attempt++;
      
      try {
        // تنفيذ العملية
        final result = await operation();
        
        // نجحت العملية
        return RetryResult<T>(
          success: true,
          value: result,
          attempts: attempt,
          totalDuration: DateTime.now().difference(startTime),
        );
      } catch (e) {
        lastError = e;
        
        // تسجيل الخطأ
        _errorLoggingService.logError(
          'RetryService',
          'فشلت المحاولة $attempt من $operationName',
          e
        );
        
        // استدعاء معالج الخطأ إذا كان موجوداً
        onError?.call(e);
        
        // التحقق من إمكانية إعادة المحاولة
        if (!_shouldRetryError(e, config, shouldRetry)) {
          break;
        }
        
        // التحقق من وصولنا للحد الأقصى من المحاولات
        if (attempt >= config.maxAttempts) {
          break;
        }
        
        // حساب التأخير
        final delay = _calculateDelay(attempt, config);
        
        // استدعاء معالج إعادة المحاولة
        onRetry?.call(attempt, e);
        
        // الانتظار قبل المحاولة التالية
        await Future.delayed(delay);
      }
    }
    
    // فشلت جميع المحاولات
    return RetryResult<T>(
      success: false,
      error: lastError,
      attempts: attempt,
      totalDuration: DateTime.now().difference(startTime),
    );
  }
  
  /// تنفيذ عمليات متعددة بالتوازي مع إعادة المحاولة
  Future<List<RetryResult<T>>> executeMultipleWithRetry<T>({
    required List<Future<T> Function()> operations,
    required String operationName,
    RetryConfig? config,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    final futures = operations.map((operation) => 
      executeWithRetry(
        operation: operation,
        operationName: operationName,
        config: config,
        shouldRetry: shouldRetry,
      )
    ).toList();
    
    return Future.wait(futures);
  }
  
  /// تنفيذ عملية مع مهلة زمنية وإعادة محاولة
  Future<RetryResult<T>> executeWithTimeout<T>({
    required Future<T> Function() operation,
    required String operationName,
    required Duration timeout,
    RetryConfig? config,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    return executeWithRetry(
      operation: () => operation().timeout(timeout),
      operationName: operationName,
      config: config ?? RetryConfig(
        maxAttempts: 3,
        strategy: RetryStrategy.exponentialBackoff,
      ),
      shouldRetry: (error) {
        if (error is TimeoutException) return true;
        return shouldRetry?.call(error) ?? false;
      },
    );
  }
  
  /// إعادة المحاولة غير المتزامنة (تعمل في الخلفية)
  Future<void> executeAsyncWithRetry({
    required Future<void> Function() operation,
    required String operationName,
    RetryConfig? config,
    void Function(RetryResult<void>)? onComplete,
  }) async {
    // تنفيذ في الخلفية
    Future(() async {
      final result = await executeWithRetry(
        operation: operation,
        operationName: operationName,
        config: config,
      );
      
      onComplete?.call(result);
    });
  }
  
  /// التحقق من إمكانية إعادة المحاولة للخطأ
  bool _shouldRetryError(
    dynamic error,
    RetryConfig config,
    bool Function(dynamic)? customChecker,
  ) {
    // إذا كان هناك فاحص مخصص، استخدمه
    if (customChecker != null) {
      return customChecker(error);
    }
    
    // التحقق من قائمة الاستثناءات القابلة للإعادة
    if (config.retryableExceptions.isNotEmpty) {
      return config.retryableExceptions.any((type) => error.runtimeType == type);
    }
    
    // بشكل افتراضي، أعد المحاولة لجميع الأخطاء
    return true;
  }
  
  /// حساب التأخير بناءً على الاستراتيجية
  Duration _calculateDelay(int attempt, RetryConfig config) {
    switch (config.strategy) {
      case RetryStrategy.immediate:
        return Duration.zero;
        
      case RetryStrategy.fixedDelay:
        return config.initialDelay;
        
      case RetryStrategy.exponentialBackoff:
        final delay = config.initialDelay * pow(config.exponentialBase, attempt - 1);
        return Duration(
          milliseconds: min(delay.inMilliseconds, config.maxDelay.inMilliseconds)
        );
        
      case RetryStrategy.exponentialBackoffWithJitter:
        final baseDelay = config.initialDelay * pow(config.exponentialBase, attempt - 1);
        final jitter = _random.nextDouble() * baseDelay.inMilliseconds * 0.5;
        final totalDelay = baseDelay.inMilliseconds + jitter;
        return Duration(
          milliseconds: min(totalDelay.toInt(), config.maxDelay.inMilliseconds)
        );
    }
  }
  
  /// إنشاء سياسة إعادة محاولة مخصصة
  RetryConfig createCustomConfig({
    int? maxAttempts,
    Duration? initialDelay,
    Duration? maxDelay,
    RetryStrategy? strategy,
    double? exponentialBase,
    List<Type>? retryableExceptions,
  }) {
    return RetryConfig(
      maxAttempts: maxAttempts ?? 3,
      initialDelay: initialDelay ?? const Duration(seconds: 1),
      maxDelay: maxDelay ?? const Duration(seconds: 30),
      strategy: strategy ?? RetryStrategy.exponentialBackoff,
      exponentialBase: exponentialBase ?? 2.0,
      retryableExceptions: retryableExceptions ?? [],
    );
  }
}

/// مثال على استخدام RetryService
class RetryExample {
  final RetryService retryService;
  
  RetryExample({required this.retryService});
  
  /// مثال: جلب بيانات من API مع إعادة المحاولة
  Future<Map<String, dynamic>> fetchDataWithRetry() async {
    final result = await retryService.executeWithRetry<Map<String, dynamic>>(
      operation: () async {
        // عملية جلب البيانات
        final response = await fetchDataFromAPI();
        return response;
      },
      operationName: 'fetch_user_data',
      config: RetryConfig.networkDefault,
      shouldRetry: (error) {
        // أعد المحاولة فقط لأخطاء الشبكة
        return error is NetworkException;
      },
      onRetry: (attempt, error) {
        print('إعادة المحاولة $attempt بسبب: $error');
      },
    );
    
    if (result.success) {
      return result.value!;
    } else {
      throw Exception('فشل جلب البيانات بعد ${result.attempts} محاولات');
    }
  }
  
  /// مثال: حفظ في قاعدة البيانات مع إعادة المحاولة
  Future<void> saveToDatabase(Map<String, dynamic> data) async {
    final result = await retryService.executeWithRetry(
      operation: () async {
        // عملية الحفظ في قاعدة البيانات
        await database.save(data);
      },
      operationName: 'save_to_database',
      config: RetryConfig.databaseDefault,
    );
    
    if (!result.success) {
      throw Exception('فشل الحفظ في قاعدة البيانات');
    }
  }
  
  /// مثال وهمي لجلب البيانات
  Future<Map<String, dynamic>> fetchDataFromAPI() async {
    // محاكاة طلب API
    await Future.delayed(Duration(seconds: 1));
    
    // محاكاة فشل عشوائي
    if (Random().nextBool()) {
      throw NetworkException('Connection timeout');
    }
    
    return {'id': 1, 'name': 'User'};
  }
  
  /// مثال وهمي لقاعدة البيانات
  final database = _MockDatabase();
}

/// استثناء شبكة للأمثلة
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  
  @override
  String toString() => 'NetworkException: $message';
}

/// قاعدة بيانات وهمية للأمثلة
class _MockDatabase {
  Future<void> save(Map<String, dynamic> data) async {
    await Future.delayed(Duration(milliseconds: 100));
    // محاكاة نجاح الحفظ
  }
}