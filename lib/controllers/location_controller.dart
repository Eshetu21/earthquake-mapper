import 'package:get/get.dart';
import 'package:location/location.dart';

class LocationController extends GetxController {
  final RxBool isAccessingLocation = false.obs;
  final RxString errorDescription = RxString("");
  Rx<LocationData?> userLocation = Rx<LocationData?>(null);

  void updateIsAccessingLocation(bool b) {
    isAccessingLocation.value = b;
  }

  void updateUserLocation(LocationData data) {
    userLocation.value = data;
  }
}
