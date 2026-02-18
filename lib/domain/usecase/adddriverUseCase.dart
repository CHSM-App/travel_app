import 'package:travel_agency_app/domain/models/drivers.dart';
import 'package:travel_agency_app/domain/repository/adddriverRepository.dart';

class AddDeiverUseCase {
  final Adddriverrepository adddriverrepository;

  AddDeiverUseCase(this.adddriverrepository);
  Future<dynamic> addDriver(Drivers driver) {
    return adddriverrepository.addDriver(driver);
  }

  Future<dynamic> updateDriver(Drivers driver)  {
    return adddriverrepository.updateDriver(driver);
  }
}