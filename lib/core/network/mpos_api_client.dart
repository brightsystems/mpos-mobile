import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:mpos_mobile/core/config/mpos_config.dart';
import 'package:mpos_mobile/core/network/api_response.dart';
import 'package:mpos_mobile/core/storage/session_storage.dart';

class MposApiClient {
  MposApiClient({required http.Client httpClient, required SessionStorage sessionStorage})
    : _httpClient = httpClient,
      _sessionStorage = sessionStorage;

  final http.Client _httpClient;
  final SessionStorage _sessionStorage;

  Uri _uri(String path) => Uri.parse('${MposConfig.baseUrl}${MposConfig.apiPrefix}$path');

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    T Function(Object? json)? fromJson,
  }) async {
    return _request('POST', path, body: body, authenticated: authenticated, fromJson: fromJson);
  }

  Future<ApiResponse<T>> get<T>(String path, {bool authenticated = false, T Function(Object? json)? fromJson}) async {
    return _request('GET', path, authenticated: authenticated, fromJson: fromJson);
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    T Function(Object? json)? fromJson,
  }) async {
    return _request('PUT', path, body: body, authenticated: authenticated, fromJson: fromJson);
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    bool authenticated = false,
    T Function(Object? json)? fromJson,
  }) async {
    return _request('DELETE', path, authenticated: authenticated, fromJson: fromJson);
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
    T Function(Object? json)? fromJson,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'X-App-Id': MposConfig.appId,
      'X-App-Secret': MposConfig.appSecret,
    };

    if (authenticated) {
      final session = await _sessionStorage.loadSession();

      if (session == null) {
        return const ApiResponse(success: false, message: 'Not authenticated.');
      }

      headers['Authorization'] = 'Bearer ${session.accessToken}';
      headers['X-Organization-Id'] = session.organizationId;
      headers['X-Branch-Id'] = session.branchId;
    }

    try {
      final request = http.Request(method, _uri(path))..headers.addAll(headers);
      if (body != null) {
        request.body = jsonEncode(body);
      }

      final response = await _httpClient.send(request).timeout(const Duration(seconds: 15));
      final responseBody = await response.stream.bytesToString().timeout(const Duration(seconds: 15));

      if (responseBody.isEmpty) {
        return ApiResponse(success: false, message: 'Empty response (${response.statusCode}).');
      }

      final decoded = jsonDecode(responseBody);
      if (decoded is! Map<String, dynamic>) {
        return ApiResponse(success: false, message: 'Unexpected response (${response.statusCode}).');
      }

      return ApiResponse.fromJson(decoded, (json) {
        if (fromJson == null) {
          return json as T;
        }

        return fromJson(json);
      });
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'API timed out. Check ${MposConfig.baseUrl} and that the phone is on the same Wi‑Fi.',
      );
    } on http.ClientException catch (e) {
      return ApiResponse(
        success: false,
        message: 'Cannot reach API at ${MposConfig.baseUrl}. ${e.message}',
      );
    } on FormatException {
      return const ApiResponse(success: false, message: 'API returned a non-JSON response.');
    } catch (e) {
      final message = e.toString();
      if (message.contains('SocketException') || message.contains('Failed host lookup')) {
        return ApiResponse(
          success: false,
          message: 'Cannot reach API at ${MposConfig.baseUrl}. $message',
        );
      }
      return ApiResponse(success: false, message: message);
    }
  }
}
