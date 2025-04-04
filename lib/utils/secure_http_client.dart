// Copyright © 2025 Digital Relics. All Rights Reserved.
import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:crypto/crypto.dart';
import '../config/config.dart';
import '../logic/logging_handler.dart';

/// A secure HTTP client that implements certificate pinning
/// to protect against man-in-the-middle attacks
class SecureHttpClient {
  static final SecureHttpClient _instance = SecureHttpClient._internal();
  factory SecureHttpClient() => _instance;

  late final Dio _dio;

  // Use certificate fingerprint from Config
  static String get _certificateFingerprint => Config.certificateFingerprint;

  SecureHttpClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: Config.apiUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
      ),
    );

    // Only apply certificate pinning for non-web platforms and if enabled
    if (!kIsWeb && Config.enableCertificatePinning) {
      _dio.httpClientAdapter = _createPinnedAdapter();
      LogService.logInfo('🔒 Certificate pinning enabled with fingerprint: $_certificateFingerprint');
    } else if (!kIsWeb) {
      LogService.logInfo('⚠️ Certificate pinning is disabled');
    }

    // Add logging interceptor for debugging
    _dio.interceptors.add(
      LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (object) => LogService.logDebug('🌐 DIO: $object'),
      ),
    );
  }

  /// Create an HTTP client adapter with certificate pinning
  HttpClientAdapter _createPinnedAdapter() {
    return IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.badCertificateCallback = (X509Certificate cert, String host, int port) {
          // Calculate the SHA-256 fingerprint of the certificate
          final certBytes = cert.der;
          final digest = sha256.convert(certBytes);
          final fingerprint = _formatFingerprint(digest.bytes);

          // Check if the fingerprint matches our pinned fingerprint
          final bool isValid = fingerprint == _certificateFingerprint;

          if (!isValid) {
            LogService.logError('🔒 Certificate pinning failed! Expected: $_certificateFingerprint, Got: $fingerprint');
          } else {
            LogService.logDebug('🔒 Certificate pinning successful for $host');
          }

          return isValid;
        };
        return client;
      },
    );
  }

  /// Format the fingerprint to match the OpenSSL format
  String _formatFingerprint(List<int> bytes) {
    return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0').toUpperCase()).join(':');
  }

  /// Get the Dio instance for direct use
  Dio get dio => _dio;

  /// Perform a GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters, options: _mergeOptions(headers, options));
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Perform a POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: _mergeOptions(headers, options),
      );
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  /// Merge custom headers with options
  Options? _mergeOptions(Map<String, dynamic>? headers, Options? options) {
    if (headers == null && options == null) return null;

    final mergedOptions = options ?? Options();
    if (headers != null) {
      mergedOptions.headers = {...?mergedOptions.headers, ...headers};
    }
    return mergedOptions;
  }

  /// Handle and log errors
  void _handleError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.badCertificate) {
        LogService.logError('🔒 Certificate validation failed! Possible security breach detected.');
      }
    }
  }
}
