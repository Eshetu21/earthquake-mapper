import 'package:earthquake_map/controllers/earthquake_controller.dart';
import 'package:earthquake_map/screens/earthquake_card.dart';
import 'package:flutter/material.dart';
import 'package:earthquake_map/constants/appcolors.dart' as appcolors;
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  String selectedFilter = "Today";
  DateTime? startDate;
  DateTime? endDate;

  Future<List> fetchEarthQuakes() async {
    try {
      return await EarthQuake().fetchEarthQuakes(
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
        selectedFilter = "Custom Range";
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
          "Earthquake Mapper",
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
                items: ["Today", "This Week", "This Month", "Custom Range"]
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
                  if (newValue == "Custom Range") {
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
      body: Column(
        children: [
          Expanded(
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
                  return LiquidPullToRefresh(
                      onRefresh: _refresh,
                      child: EarthquakeCard(earthquake: earthquakes));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
