import 'package:earthquake_map/controllers/earthquake_controller.dart';
import 'package:earthquake_map/screens/earthquake_card.dart';
import 'package:flutter/material.dart';
import 'package:earthquake_map/constants/appcolors.dart' as appcolors;
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final EarthQuake _earthQuake = Get.put(EarthQuake());
  String selectedFilter = "Today";
  DateTime? startDate;
  DateTime? endDate;
  Position? userLocation;
  @override
  void initState() {
    super.initState();
    getUserLocation();
  }

  Future getUserLocation() async {
    try {
      await EarthQuake().getUserLocation();
      setState(() {
        userLocation = _earthQuake.userLocation;
      });
    } catch ($e) {
      print($e.toString());
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
      print("Error fetching data: $e");
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
              var highestMangnitude = earthquakes.reduce((a, b) =>
                  a["properties"]["mag"] > b["properties"]["mag"] ? a : b);
              var nearestEarthquake;
              if (userLocation != null) {
                nearestEarthquake = earthquakes.reduce((a, b) {
                  double distanceA = _earthQuake.calculateDistance(
                      userLocation!.latitude,
                      userLocation!.longitude,
                      a["geometry"]["coordinates"][1],
                      a["geometry"]["coordinates"][0]);
                  double distanceB = _earthQuake.calculateDistance(
                      userLocation!.latitude,
                      userLocation!.longitude,
                      b["geometry"]["coordinates"][1],
                      b["geometry"]["coordinates"][0]);
                  return distanceA < distanceB ? a : b;
                });
                print("nearest ${nearestEarthquake["properties"]["mag"]}");
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
                  const Divider(),
                  Flex(direction: Axis.horizontal, children: [
                    Expanded(
                        child:
                            Text("${highestMangnitude["properties"]["mag"]}")),
                    Expanded(
                      child: Text(
                        nearestEarthquake != null &&
                                nearestEarthquake["properties"] != null
                            ? "${nearestEarthquake["properties"]["mag"]}"
                            : "Location disabled",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  ]),
                  const Divider(),
                  Expanded(child: EarthquakeCard(earthquake: earthquakes)),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
