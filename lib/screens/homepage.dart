import 'package:earthquake_map/controllers/earthquake_controller.dart';
import 'package:flutter/material.dart';

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
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
        selectedFilter = "Custom Range";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        margin: const EdgeInsets.only(top: 25),
        child: Column(
          children: [
            DropdownButton<String>(
              value: selectedFilter,
              items: ["Today", "This Week", "This Month", "Custom Range"]
                  .map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
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
            Expanded(
              child: FutureBuilder<List>(
                future: fetchEarthQuakes(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
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
                    return ListView.builder(
                      itemCount: earthquakes.length,
                      itemBuilder: (context, index) {
                        final earthquake = earthquakes[index]["properties"];
                        return ListTile(
                          title: Text(earthquake['place']),
                          subtitle: Text('Magnitude: ${earthquake['mag']}'),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
