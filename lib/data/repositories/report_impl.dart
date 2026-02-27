import 'package:travel_agency_app/data/api/api_service.dart';
import 'package:travel_agency_app/domain/models/reports_data.dart';
import 'package:travel_agency_app/domain/repository/report_repo.dart';

class ReportImpl implements ReportRepository {
  final ApiService apiService;

  ReportImpl(this.apiService);

  @override
  Future<List<ReportData>> getReport(String agencyId, String reportType) async {
    return apiService.getReport(agencyId, reportType);
  }
}
