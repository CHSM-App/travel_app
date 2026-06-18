import 'package:vego/data/api/api_service.dart';
import 'package:vego/domain/models/reports_data.dart';
import 'package:vego/domain/repository/report_repo.dart';

class ReportImpl implements ReportRepository {
  final ApiService apiService;

  ReportImpl(this.apiService);

  @override
  Future<List<ReportData>> getReport(String agencyId, String reportType) async {
    return apiService.getReport(agencyId, reportType);
  }
}
