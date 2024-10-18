import 'package:earthquake_map/controllers/location_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class EarthQuake {
  Future<List> fetchEarthQuakes(
      {required String filter, DateTime? startDate, DateTime? endDate}) async {
    String apiUrl;
    DateTime today = DateTime.now();
    String formattedToday =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}T00:00:00";
    String formattedEndOfToday =
        "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}T23:59:59";

    if (filter == "Today") {
      apiUrl =
          "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=$formattedToday&endtime=$formattedEndOfToday";
    } else if (filter == "This Week") {
      DateTime oneWeekAgo = today.subtract(Duration(days: 7));
      String formattedWeek =
          "${oneWeekAgo.year}-${oneWeekAgo.month.toString().padLeft(2, '0')}-${oneWeekAgo.day.toString().padLeft(2, '0')}T00:00:00";
      apiUrl =
          "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=$formattedWeek&endtime=$formattedEndOfToday";
    } else if (filter == "This Month") {
      DateTime startOfMonth = DateTime(today.year, today.month, 1);
      String formattedStartOfMonth =
          "${startOfMonth.year}-${startOfMonth.month.toString().padLeft(2, '0')}-${startOfMonth.day.toString().padLeft(2, '0')}T00:00:00";
      apiUrl =
          "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=$formattedStartOfMonth&endtime=$formattedEndOfToday";
    } else if (filter == "Custom" && startDate != null && endDate != null) {
      String formattedStartDate =
          "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}T00:00:00";
      String formattedEndDate =
          "${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}T23:59:59";
      apiUrl =
          "https://earthquake.usgs.gov/fdsnws/event/1/query?format=geojson&starttime=$formattedStartDate&endtime=$formattedEndDate";
    } else {
      throw Exception("Invalid filter or date range");
    }
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        return jsonDecode(response.body)["features"];
      } else {
        throw Exception("Failed to fetch earthquake data");
      }
    } catch (e) {
      throw Exception("failed to fetch $e");
    }
  }
}

class LocationServices {
  LocationServices.init();
  static LocationServices instance = LocationServices.init();

  Location _location = Location();

  Future<bool> checkForServiceAvailability() async {
    bool isEnabled = await _location.serviceEnabled();
    if (isEnabled) {
      return Future.value(true);
    }
    isEnabled = await _location.requestService();
    if (isEnabled) {
      return Future.value(true);
    }
    return Future.value(false);
  }

  Future<bool> checkForPermission() async {
    PermissionStatus status = await _location.hasPermission();
    if (status == PermissionStatus.denied) {
      status = await _location.requestPermission();
      if (status == PermissionStatus.granted) {
        return true;
      }
      return false;
    }
    if (status == PermissionStatus.deniedForever) {
      Get.snackbar("Permission Needed",
          "We use permission to get your location in order to give you full experience",
          onTap: (snack) {
        handler.openAppSettings();
      }).show();
      return false;
    }
    return Future.value(true);
  }

  Future<void> getUserLocation({required LocationController controller}) async {
    controller.updateIsAccessingLocation(true);
    if (!(await checkForServiceAvailability())) {
      controller.errorDescription.value = "Service not enabled";
      controller.updateIsAccessingLocation(false);
      return;
    }
    if (!(await checkForPermission())) {
      controller.errorDescription.value = "Permission denied";
      controller.updateIsAccessingLocation(false);
      return;
    }
    final LocationData data = await _location.getLocation();
    controller.updateUserLocation(data);
    controller.updateIsAccessingLocation(false);

    print(data.latitude);
    print(data.longitude);
  }

  double calculateDistance(
      double? lat1, double? lon1, double? lat2, double? lon2) {
    return Geolocator.distanceBetween(lat1!, lon1!, lat2!, lon2!);
  }
}
