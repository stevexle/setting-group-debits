import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 90,
      colors: false, // Turn off ANSI colors to avoid messy codes
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.dateAndTime,
    ),
  );

  LogService._internal();

  // Initialization: Should be called in main.dart
  Future<void> init() async {
    if (!kIsWeb) {
      // Pass all uncaught errors from the framework to Crashlytics.
      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      };

      // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics.
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  void info(String message) {
    if (kDebugMode) {
      _logger.i(message);
    }
    // Also log as breadcrumb in Crashlytics if in release
    FirebaseCrashlytics.instance.log(message);
  }

  void warning(String message) {
    if (kDebugMode) {
      _logger.w(message);
    }
    FirebaseCrashlytics.instance.log("WARNING: $message");
  }

  void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.e(message, error: error, stackTrace: stackTrace);
    }
    
    // Record to crashlytics
    FirebaseCrashlytics.instance.recordError(
      error ?? message,
      stackTrace,
      reason: message.toString(),
    );
  }

  void debug(String message) {
    if (kDebugMode) {
      _logger.d(message);
    }
  }

  // Identify the user for better debugging
  Future<void> setUserIdentifier(String identifier) async {
    await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
  }
}

// Global accessor
final log = LogService();
