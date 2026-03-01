
import 'package:travel_agency_app/domain/models/reports_data.dart';


abstract class ReportRepository {
    
  Future<List<ReportData>> getReport(String agencyId, String reportType);

}
