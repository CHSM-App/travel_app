
import 'package:travel_agency_app/domain/models/reports_data.dart';

import '../models/token_response.dart';

abstract class ReportRepository {
    
  Future<List<ReportData>> getReport(String agencyId, String reportType);

}
