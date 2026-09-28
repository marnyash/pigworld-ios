import 'package:dio/dio.dart';

import '../../../core/errors/error_handler.dart';

class SupportApi {
  SupportApi(this._dio);

  final Dio _dio;

  Future<void> sendMessage({
    required String farmId,
    required String message,
  }) async {
    try {
      await _dio.post<void>(
        '/farms/$farmId/support-conversation/messages',
        data: {'message': message},
      );
    } on DioException catch (error) {
      // Production may not have the new conversation routes deployed yet.
      if (error.response?.statusCode == 404) {
        try {
          await _dio.post<void>(
            '/farms/$farmId/notifications/messages',
            data: {'message': message},
          );
          return;
        } on DioException catch (legacyError) {
          throw ErrorHandler.from(legacyError);
        }
      }
      throw ErrorHandler.from(error);
    }
  }
}