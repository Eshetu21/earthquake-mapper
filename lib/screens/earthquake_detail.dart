import 'package:flutter/material.dart';
import 'package:earthquake_map/constants/appcolors.dart' as appcolors;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EarthquakeDetail extends StatefulWidget {
  final Map<String, dynamic> earthquake;
  final Map<String, dynamic> eqproperty;

  const EarthquakeDetail({
    super.key,
    required this.earthquake,
    required this.eqproperty,
  });

  @override
  State<EarthquakeDetail> createState() => _EarthquakeDetailState();
}

class _EarthquakeDetailState extends State<EarthquakeDetail> {
  @override
  void initState() {
    super.initState();
  }

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

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Failed to open url"), duration: Duration(seconds: 2)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appcolors.background,
      appBar: AppBar(
        title: const Text("Earthquake Detail"),
        backgroundColor: appcolors.primaryColor,
      ),
      body: Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: GoogleMap(
              key: UniqueKey(),
              initialCameraPosition: CameraPosition(
                target: LatLng(
                  widget.earthquake["coordinates"][1],
                  widget.earthquake["coordinates"][0],
                ),
                zoom: 1,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId("Earthquake"),
                  position: LatLng(
                    widget.earthquake["coordinates"][1],
                    widget.earthquake["coordinates"][0],
                  ),
                ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                        "📍 Location:", widget.eqproperty["place"] ?? "Null"),
                    _buildDetailRow("🌍 Magnitude:",
                        widget.eqproperty["mag"]?.toString() ?? "Null"),
                    _buildDetailRow("🌊 Depth:",
                        "${widget.earthquake["coordinates"][2]} KM"),
                    _buildDetailRow("👥 People Reported:",
                        widget.eqproperty["felt"]?.toString() ?? "Null"),
                    _buildDetailRow("🕒 Last Updated:",
                        getTimeDifference(widget.eqproperty["updated"])),
                    TextButton(
                        onPressed: () {
                          _launchUrl(widget.eqproperty["url"]);
                        },
                        child: const Text("More Details"))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(
              child:
                  Text(value, style: const TextStyle(color: Colors.black54))),
        ],
      ),
    );
  }
}
