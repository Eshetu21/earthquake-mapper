import 'package:earthquake_map/screens/earthquake_detail.dart';
import 'package:flutter/material.dart';

class EarthquakeCard2 extends StatelessWidget {
  final Map<String, dynamic> earthquake;
  const EarthquakeCard2({super.key, required this.earthquake});

  String getTimeDifference(int timestamp) {
    final DateTime earthquakeTime =
        DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(earthquakeTime);
    if (difference.inMinutes < 60) {
      return "${difference.inMinutes} min ago";
    } else if (difference.inHours < 24) {
      return "${difference.inHours} hours ago";
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final earthquakelocation = earthquake["geometry"];
    final earthquakeDetails = earthquake["properties"];
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => EarthquakeDetail(
              earthquake: earthquakelocation,
              eqproperty: earthquakeDetails,
            ),
          ),
        );
      },
      child: Container(
        height: MediaQuery.of(context).size.height * 0.15,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            earthquakeDetails['place'] ?? 'Unknown Location',
            overflow: TextOverflow.visible,
          ),
          Text('Magnitude: ${earthquakeDetails['mag']}'),
          Text(getTimeDifference(earthquakeDetails['time'])),
        ]),
      ),
    );
  }
}
