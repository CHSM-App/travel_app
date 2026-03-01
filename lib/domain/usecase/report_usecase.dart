
import 'package:travel_agency_app/domain/models/reports_data.dart';
import 'package:travel_agency_app/domain/repository/report_repo.dart';

class ReportUsecase {
  final ReportRepository reportRepository;
  ReportUsecase(this.reportRepository);
  Future<List<ReportData>> getReport(String agencyId, String reportType) {
    return reportRepository.getReport(agencyId, reportType);
  }
}
    
