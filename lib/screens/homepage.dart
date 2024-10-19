import 'package:earthquake_map/controllers/location_controller.dart';
import 'package:earthquake_map/screens/earthquake_card.dart';
import 'package:earthquake_map/screens/earthquake_card2.dart';
import 'package:earthquake_map/services/services.dart';
import 'package:flutter/material.dart';
import 'package:earthquake_map/constants/appcolors.dart' as appcolors;
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final EarthQuake _earthQuake = Get.put(EarthQuake());
  final LocationServices _locationServices = Get.put(LocationServices.init());
  final LocationController _locationController =
      Get.put<LocationController>(LocationController());
  String selectedFilter = "Today";
  DateTime? startDate;
  DateTime? endDate;
  double? userLat;
  double? userLon;

  @override
  void initState() {
    super.initState();
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    await LocationServices.instance
        .getUserLocation(controller: _locationController);
    if (_locationController.userLocation != null) {
      setState(() {
        userLat = _locationController.userLocation.value?.latitude;
        userLon = _locationController.userLocation.value?.longitude;
      });
    } else {
      Get.snackbar("Failed", "Failed to get location data");
    }
  }

  Future<List> fetchEarthQuakes() async {
    try {
      return await _earthQuake.fetchEarthQuakes(
        filter: selectedFilter,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      Get.snackbar("Failed", "Error fetching data");
      return [];
    }
  }

  Future<void> selectDateRange(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked;
        endDate = picked;
        selectedFilter = "Custom";
      });
    }
  }

  Future<void> _refresh() async {
    await fetchEarthQuakes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appcolors.background,
      appBar: AppBar(
        backgroundColor: appcolors.background,
        elevation: 0,
        title: const Text(
          "EQ Map",
          style: TextStyle(fontSize: 20),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedFilter,
                dropdownColor: Colors.white,
                icon: const Icon(Icons.filter_list,
                    color: Colors.black, size: 20),
                items: ["Today", "This Week", "This Month", "Custom"]
                    .map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                      value,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
                onChanged: (newValue) async {
                  if (newValue == "Custom") {
                    await selectDateRange(context);
                  } else {
                    setState(() {
                      selectedFilter = newValue!;
                      startDate = null;
                      endDate = null;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
      body: LiquidPullToRefresh(
        onRefresh: _refresh,
        child: FutureBuilder<List>(
          future: fetchEarthQuakes(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                    color: Colors.grey, strokeWidth: 1),
              );
            } else if (snapshot.hasError) {
              return const Center(
                child: Text("Error fetching data"),
              );
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(
                child: Text("No data available"),
              );
            } else {
              List earthquakes = snapshot.data!;
              var highestMagnitude;
              if (earthquakes.isNotEmpty) {
                highestMagnitude = earthquakes.reduce((a, b) =>
                    a["properties"]["mag"] > b["properties"]["mag"] ? a : b);
              }

              var nearestEarthquake;
              if (userLat != null &&
                  userLon != null &&
                  earthquakes.isNotEmpty) {
                nearestEarthquake = earthquakes.reduce((a, b) {
                  double distanceA = _locationServices.calculateDistance(
                      userLat,
                      userLon,
                      a["geometry"]["coordinates"][1],
                      a["geometry"]["coordinates"][0]);
                  double distanceB = _locationServices.calculateDistance(
                      userLat,
                      userLon,
                      b["geometry"]["coordinates"][1],
                      b["geometry"]["coordinates"][0]);
                  return distanceA < distanceB ? a : b;
                });
                print("nearest ${nearestEarthquake["properties"]["place"]}");
              }

              return Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text(earthquakes.length.toString(),
                            style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.height * 0.08)),
                        Text("Earthquakes $selectedFilter")
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (highestMagnitude != null)
                            Expanded(
                              child: Card(
                                color: appcolors.audioBGreyBackground,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Most Significant $selectedFilter",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    EarthquakeCard2(
                                        earthquake: highestMagnitude),
                                  ],
                                ),
                              ),
                            ),
                          if (nearestEarthquake != null)
                            Expanded(
                              child: Card(
                                color: appcolors.audioBlueBackground,
                                child: Column(
                                  children: [
                                    const Text(
                                      "Nearest to you",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    EarthquakeCard2(
                                        earthquake: nearestEarthquake),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Divider(),
                  Expanded(
                    child: EarthquakeCard(earthquake: earthquakes),
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
