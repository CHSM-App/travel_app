
import 'package:vego/domain/models/reports_data.dart';
import 'package:vego/domain/repository/report_repo.dart';

class ReportUsecase {
  final ReportRepository reportRepository;
  ReportUsecase(this.reportRepository);
  Future<List<ReportData>> getReport(String agencyId, String reportType) {
    return reportRepository.getReport(agencyId, reportType);
  }
}
    
