import '../models/address_model.dart';
import 'base_service.dart';

class AddressService extends BaseService {
  AddressService({required super.httpClient, required super.apiUrl});

  @override
  String get basePath => '/addresses';

  Future<List<Address>> getMyAddresses() {
    return getList<Address>(
      '', // endpoint vacío porque basePath ya es /addresses
      fromJson: (json) => Address.fromJson(json),
    );
  }

  Future<Address> createAddress(CreateAddressRequest request) {
    return post<Address>(
      '',
      fromJson: (json) => Address.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<Address> updateAddress(int id, UpdateAddressRequest request) {
    return put<Address>(
      '/$id',
      fromJson: (json) => Address.fromJson(json),
      body: request.toJson(),
    );
  }

  Future<void> deleteAddress(int id) {
    return delete('/$id');
  }
}
