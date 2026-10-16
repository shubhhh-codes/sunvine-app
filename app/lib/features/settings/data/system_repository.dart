import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_result.dart';

abstract class ISystemRepository {
  Future<Result<Map<String, dynamic>>> checkHealth();
}

class SystemRepository implements ISystemRepository {
  final Dio dio;

  SystemRepository({required this.dio});

  @override
  Future<Result<Map<String, dynamic>>> checkHealth() async {
    try {
      final res = await dio.get(ApiEndpoints.health);
      if (res.statusCode == 200 && res.data != null) {
        return Result.success(res.data as Map<String, dynamic>);
      }
      return Result.failure(ServerFailure('Health endpoint returned status ${res.statusCode}'));
    } catch (e) {
      return Result.failure(NetworkFailure('Gateway is unreachable or offline: $e'));
    }
  }
}
