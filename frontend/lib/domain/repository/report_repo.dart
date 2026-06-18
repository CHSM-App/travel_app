
import 'package:vego/domain/models/reports_data.dart';


abstract class ReportRepository {
    
  Future<List<ReportData>> getReport(String agencyId, String reportType);

}
