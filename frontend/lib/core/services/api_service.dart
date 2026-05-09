import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({required this.message, this.statusCode, this.data});

  String get userMessage => cleanErrorMessage(message);

  @override
  String toString() => userMessage;

  static String cleanErrorMessage(dynamic value) {
    var message = value?.toString().trim() ?? '';
    if (message.isEmpty || message.toLowerCase() == 'null') {
      return 'Ocurrio un error. Intenta nuevamente.';
    }

    message = message
        .replaceAll(RegExp(r'ApiException:\s*'), '')
        .replaceAll(RegExp(r'Exception:\s*'), '')
        .replaceAll(RegExp(r'Error inesperado:\s*'), '')
        .replaceAll(RegExp(r'^Error al [^:]+:\s*'), '')
        .replaceAll(RegExp(r'^Error al [^:]+ empleado:\s*'), '')
        .replaceAll(RegExp(r'\s*\(Status:\s*null\)\s*'), '')
        .replaceAll(RegExp(r'\s*\(Status:\s*\d+\)\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final lower = message.toLowerCase();
    if (lower.contains('assertionerror') ||
        lower.contains('traceback') ||
        lower.contains('request method') ||
        lower.contains('request url') ||
        lower.contains('<html') ||
        lower.contains('doctype html')) {
      return 'No se pudo completar la operacion. Intenta nuevamente.';
    }

    if (lower.contains('email') &&
        lower.contains('ya existe') &&
        lower.contains('correo')) {
      return 'Ya existe un usuario con ese correo';
    }

    final fieldMatch = RegExp(r'^[a-zA-Z_]+:\s*(.+)$').firstMatch(message);
    if (fieldMatch != null) {
      message = fieldMatch.group(1)?.trim() ?? message;
    }

    return message.isEmpty ? 'Ocurrio un error. Intenta nuevamente.' : message;
  }
}

class ApiService {
  late Dio _dio;
  String? _authToken;

  // Getter público para acceso al cliente Dio
  Dio get dio => _dio;

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: ApiConstants.headers,
        validateStatus: (status) => status! < 500,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar token si existe
          if (_authToken != null) {
            options.headers['Authorization'] = 'Token $_authToken';
          }

          if (kDebugMode) {
            print('🔵 REQUEST: ${options.method} ${options.path}');
            print('Headers: ${options.headers}');
            if (options.data != null) {
              print('Body: ${options.data}');
            }
          }

          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print(
              '🟢 RESPONSE: ${response.statusCode} ${response.requestOptions.path}',
            );
            print('Data: ${response.data}');
          }
          return handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            print(
              '🔴 ERROR: ${error.response?.statusCode} ${error.requestOptions.path}',
            );
            print('Message: ${error.message}');
            print('Data: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Inicializar token desde SharedPreferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
  }

  // Guardar token
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Limpiar token (logout)
  Future<void> clearAuthToken() async {
    _authToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Verificar si está autenticado
  bool get isAuthenticated => _authToken != null;

  // GET request
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw ApiException(
        message: 'No hay conexión a internet. Verifica tu conexión.',
        statusCode: null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado: $e');
    }
  }

  // POST request
  Future<dynamic> post(String path, {dynamic data, Options? options}) async {
    try {
      final response = await _dio.post(path, data: data, options: options);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw ApiException(
        message: 'No hay conexión a internet. Verifica tu conexión.',
        statusCode: null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado: $e');
    }
  }

  // PUT request
  Future<dynamic> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw ApiException(
        message: 'No hay conexión a internet. Verifica tu conexión.',
        statusCode: null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado: $e');
    }
  }

  // PATCH request
  Future<dynamic> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw ApiException(
        message: 'No hay conexión a internet. Verifica tu conexión.',
        statusCode: null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado: $e');
    }
  }

  // DELETE request
  Future<dynamic> delete(String path, {dynamic data}) async {
    try {
      final response = await _dio.delete(path, data: data);
      return _handleResponse(response);
    } on SocketException catch (_) {
      throw ApiException(
        message: 'No hay conexión a internet. Verifica tu conexión.',
        statusCode: null,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Error inesperado: $e');
    }
  }

  dynamic _handleResponse(Response response) {
    if (response.statusCode! >= 200 && response.statusCode! < 300) {
      return response.data;
    } else if (response.statusCode == 401) {
      throw ApiException(
        message: 'No autorizado. Por favor inicia sesión nuevamente.',
        statusCode: 401,
        data: response.data,
      );
    } else if (response.statusCode == 403) {
      throw ApiException(
        message: 'No tienes permisos para realizar esta acción.',
        statusCode: 403,
        data: response.data,
      );
    } else if (response.statusCode == 404) {
      throw ApiException(
        message: 'Recurso no encontrado.',
        statusCode: 404,
        data: response.data,
      );
    } else if (response.statusCode == 400) {
      final errorData = response.data;
      String errorMessage = 'Error en la solicitud';
      if (errorData is Map && errorData.containsKey('error')) {
        errorMessage = ApiException.cleanErrorMessage(errorData['error']);
      } else if (errorData is Map) {
        // Extraer errores de validación de Django
        final errors = <String>[];
        errorData.forEach((key, value) {
          if (value is List) {
            errors.add(_formatFieldError(key, value.join(', ')));
          } else {
            errors.add(_formatFieldError(key, value));
          }
        });
        if (errors.isNotEmpty) {
          errorMessage = errors.join('\n');
        }
      }
      throw ApiException(
        message: errorMessage,
        statusCode: 400,
        data: response.data,
      );
    } else {
      throw ApiException(
        message: 'Error del servidor (${response.statusCode})',
        statusCode: response.statusCode,
        data: response.data,
      );
    }
  }

  ApiException _handleDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        message: 'Tiempo de espera agotado. Intenta nuevamente.',
        statusCode: null,
      );
    }

    if (error.response != null) {
      return ApiException(
        message: _extractErrorMessage(
          error.response?.data,
          fallback: 'Error en la solicitud',
        ),
        statusCode: error.response?.statusCode,
        data: error.response?.data,
      );
    }

    return ApiException(
      message: 'Error de conexión: ${error.message}',
      statusCode: null,
    );
  }

  String _extractErrorMessage(dynamic data, {required String fallback}) {
    if (data is Map) {
      final direct = data['detail'] ?? data['error'] ?? data['message'];
      if (direct != null && direct.toString().trim().isNotEmpty) {
        return ApiException.cleanErrorMessage(direct);
      }

      final errors = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          errors.add(_formatFieldError(key, value.join(', ')));
        } else if (value != null) {
          errors.add(_formatFieldError(key, value));
        }
      });
      if (errors.isNotEmpty) return errors.join('\n');
    }

    if (data is String && data.trim().isNotEmpty) {
      final clean = data
          .replaceAll(RegExp(r'<[^>]*>'), ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final message = clean.length > 260
          ? '${clean.substring(0, 260)}...'
          : clean;
      return ApiException.cleanErrorMessage(message);
    }

    return fallback;
  }

  String _formatFieldError(dynamic key, dynamic value) {
    return ApiException.cleanErrorMessage(
      '${key.toString()}: ${value.toString()}',
    );
  }
}

// Singleton instance
final apiService = ApiService();
