
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:travel_agency_app/core/storage/constant.dart';

part 'api_service.g.dart';

@RestApi(baseUrl: baseUrl)
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;
  @GET('/')
  Future<HttpResponse> checkHealth(); 
}