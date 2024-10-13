import 'package:flutter/material.dart';
import 'package:earthquake_map/constants/appcolors.dart' as appcolors;

class EarthquakeCard extends StatefulWidget {
  final List<dynamic> earthquake;
  const EarthquakeCard({super.key, required this.earthquake});

  @override
  State<EarthquakeCard> createState() => _EarthquakeCardState();
}

class _EarthquakeCardState extends State<EarthquakeCard> {
  String getTimeDifference(int timestamp) {
    final DateTime earthquaketime =
        DateTime.fromMillisecondsSinceEpoch(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(earthquaketime);
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
    return ListView.builder(
      itemCount: widget.earthquake.length,
      itemBuilder: (context, index) {
        final earthquake = widget.earthquake[index]["properties"];
        return Card(
          color: appcolors.background,
          child: ListTile(
            title: Row(
              children: [
                Text(earthquake['place']),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Magnitude: ${earthquake['mag']}'),
                Text(getTimeDifference(earthquake['time'])),
              ],
            ),
          ),
        );
      },
    );
  }
}