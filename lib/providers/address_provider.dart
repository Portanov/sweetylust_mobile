import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/address_model.dart';
import '../services/address_service.dart';
import 'service_providers.dart';

class AddressState {
  final List<Address> addresses;
  final Address? selectedAddress;
  final Address? defaultAddress;
  final bool isLoading;
  final String? error;

  AddressState({
    this.addresses = const [],
    this.selectedAddress,
    this.defaultAddress,
    this.isLoading = false,
    this.error,
  });

  AddressState copyWith({
    List<Address>? addresses,
    Address? selectedAddress,
    Address? defaultAddress,
    bool? isLoading,
    String? error,
  }) {
    return AddressState(
      addresses: addresses ?? this.addresses,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  factory AddressState.initial() => AddressState();
  factory AddressState.loading() => AddressState(isLoading: true);
  factory AddressState.error(String message) => AddressState(error: message);
}

class AddressNotifier extends StateNotifier<AddressState> {
  final AddressService _service;

  AddressNotifier(this._service) : super(AddressState.initial());

  Future<void> fetchAddresses() async {
    state = AddressState.loading();

    try {
      final addresses = await _service.getMyAddresses();

      final defaultAddress = addresses.cast<Address?>().firstWhere(
        (addr) => addr?.isDefault ?? false,
        orElse: () => addresses.isNotEmpty ? addresses.first : null,
      );

      state = AddressState(
        addresses: addresses,
        defaultAddress: defaultAddress,
        selectedAddress: defaultAddress,
        isLoading: false,
      );
    } catch (e) {
      state = AddressState.error(e.toString());
    }
  }

  Future<bool> createAddress(CreateAddressRequest request) async {
    state = AddressState.loading();

    try {
      final newAddress = await _service.createAddress(request);

      List<Address> updatedAddresses;
      if (newAddress.isDefault) {
        updatedAddresses = state.addresses.map((addr) {
          if (addr.isDefault) {
            return addr.copyWith(isDefault: false);
          }
          return addr;
        }).toList();
        updatedAddresses.add(newAddress);
      } else {
        updatedAddresses = [...state.addresses, newAddress];
      }

      state = AddressState(
        addresses: updatedAddresses,
        defaultAddress: newAddress.isDefault
            ? newAddress
            : state.defaultAddress,
        selectedAddress: newAddress,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = AddressState.error(e.toString());
      return false;
    }
  }

  Future<bool> updateAddress(int id, UpdateAddressRequest request) async {
    state = AddressState.loading();

    try {
      final updatedAddress = await _service.updateAddress(id, request);

      final updatedAddresses = state.addresses.map((addr) {
        if (addr.id == id) {
          return updatedAddress;
        }

        if (updatedAddress.isDefault && addr.isDefault && addr.id != id) {
          return addr.copyWith(isDefault: false);
        }
        return addr;
      }).toList();

      state = AddressState(
        addresses: updatedAddresses,
        defaultAddress: updatedAddress.isDefault
            ? updatedAddress
            : state.defaultAddress,
        selectedAddress: updatedAddress,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = AddressState.error(e.toString());
      return false;
    }
  }

  Future<bool> deleteAddress(int id) async {
    try {
      await _service.deleteAddress(id);

      final updatedAddresses = state.addresses
          .where((addr) => addr.id != id)
          .toList();

      Address? newDefault = state.defaultAddress;
      Address? newSelected = state.selectedAddress;

      if (state.defaultAddress?.id == id) {
        newDefault = updatedAddresses.isNotEmpty
            ? updatedAddresses.first
            : null;
      }

      if (state.selectedAddress?.id == id) {
        newSelected =
            newDefault ??
            (updatedAddresses.isNotEmpty ? updatedAddresses.first : null);
      }

      state = AddressState(
        addresses: updatedAddresses,
        defaultAddress: newDefault,
        selectedAddress: newSelected,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = AddressState.error(e.toString());
      return false;
    }
  }

  void selectAddress(Address address) {
    state = state.copyWith(selectedAddress: address);
  }

  Future<bool> setDefaultAddress(int id) async {
    try {
      final addressToSet = state.addresses.firstWhere((addr) => addr.id == id);

      final request = UpdateAddressRequest(
        isDefault: true,
        recipientName: addressToSet.recipientName,
        recipientPhone: addressToSet.recipientPhone,
        street: addressToSet.street,
        extNumber: addressToSet.extNumber,
        intNumber: addressToSet.intNumber,
        neighborhood: addressToSet.neighborhood,
        city: addressToSet.city,
        state: addressToSet.state,
        postalCode: addressToSet.postalCode,
        references: addressToSet.references,
      );

      final updatedAddress = await _service.updateAddress(id, request);

      final updatedAddresses = state.addresses.map((addr) {
        if (addr.id == id) {
          return updatedAddress;
        }
        if (addr.isDefault) {
          return addr.copyWith(isDefault: false);
        }
        return addr;
      }).toList();

      state = AddressState(
        addresses: updatedAddresses,
        defaultAddress: updatedAddress,
        selectedAddress: updatedAddress,
        isLoading: false,
      );

      return true;
    } catch (e) {
      state = AddressState.error(e.toString());
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final addressNotifierProvider =
    StateNotifierProvider<AddressNotifier, AddressState>((ref) {
      final service = ref.watch(addressServiceProvider);
      return AddressNotifier(service);
    });

final addressesProvider = Provider<List<Address>>((ref) {
  return ref.watch(addressNotifierProvider).addresses;
});

final defaultAddressProvider = Provider<Address?>((ref) {
  return ref.watch(addressNotifierProvider).defaultAddress;
});

final selectedAddressProvider = Provider<Address?>((ref) {
  return ref.watch(addressNotifierProvider).selectedAddress;
});

final addressesListProvider = FutureProvider<List<Address>>((ref) async {
  final notifier = ref.watch(addressNotifierProvider.notifier);
  await notifier.fetchAddresses();
  return ref.watch(addressNotifierProvider).addresses;
});
