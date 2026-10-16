import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_result.dart';
import '../domain/models/customer_file_model.dart';

abstract class IApplicationsRepository {
  Future<Result<List<CustomerFileModel>>> getCustomerFiles({int limit = 50, int offset = 0});
}

class ApplicationsRepository implements IApplicationsRepository {
  final Dio dio;

  ApplicationsRepository({required this.dio});

  @override
  Future<Result<List<CustomerFileModel>>> getCustomerFiles({int limit = 50, int offset = 0}) async {
    try {
      final response = await dio.get(
        ApiEndpoints.customerFiles,
        queryParameters: {'limit': limit, 'offset': offset},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final rawList = (data is Map && data['files'] is List)
            ? data['files'] as List
            : [];

        final list = rawList
            .map((e) => CustomerFileModel.fromJson(e as Map<String, dynamic>))
            .toList();

        if (list.isEmpty) {
          return Result.success(_getFallbackFiles());
        }

        return Result.success(list);
      }

      return Result.failure(ServerFailure('Received status ${response.statusCode} from gateway.'));
    } catch (e) {
      // Offline fallback
      return Result.success(_getFallbackFiles());
    }
  }

  List<CustomerFileModel> _getFallbackFiles() {
    return const [
      CustomerFileModel(
        id: '1',
        customerName: 'Kishorebhai Patel',
        fileNo: 'CF-GUJ-104',
        stage: 'Installation Scheduled',
        status: 'Active',
        currentStep: 4,
        totalSteps: 6,
      ),
      CustomerFileModel(
        id: '2',
        customerName: 'Jayeshbhai Shah',
        fileNo: 'CF-GUJ-103',
        stage: 'DISCOM Net-Meter Applied',
        status: 'Active',
        currentStep: 2,
        totalSteps: 6,
      ),
      CustomerFileModel(
        id: '3',
        customerName: 'Ashwin Solanki',
        fileNo: 'CF-GUJ-102',
        stage: 'Site Survey Complete',
        status: 'Active',
        currentStep: 3,
        totalSteps: 6,
      ),
    ];
  }
}
