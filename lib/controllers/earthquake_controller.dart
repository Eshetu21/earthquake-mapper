import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EarthQuake extends GetxController {
  RxBool isfetching = false.obs;
  Position? userLocation;
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

  Future<void> getUserLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error("Location services are disabled");
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error("Location permission is denied");
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          "Location permission is permanently denied. We cannot request permission");
    }
    Position position = await Geolocator.getCurrentPosition();
    userLocation = position;
  }

  double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
}
