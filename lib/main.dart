import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String currentAddress = 'My Address';
  Position? currentposition; // Initial value is null
  final double targetLat = -6.23428056838952; // Latitude titik SmileLaundry ,
  final double targetLon = 106.72582289599362; // Longitude titik SmileLaundry
  String haversineDistanceText = '';
  String manhattanDistanceText = '';
  String euclideanDistanceText = '';

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Fluttertoast.showToast(msg: 'Please enable Your Location Service');
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Fluttertoast.showToast(msg: 'Location permissions are denied');
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Fluttertoast.showToast(
          msg:
              'Location permissions are permanently denied, we cannot request permissions.');
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      Placemark place = placemarks[0];

      setState(() {
        currentposition = position;
        currentAddress =
            "${place.street}, ${place.subLocality}, ${place.locality}, ${place.subAdministrativeArea}, ${place.administrativeArea} ${place.country}, ${place.postalCode}";

        // Menghitung jarak antara posisi pengguna dan titik target menggunakan Haversine
        double haversineDistance = calculateHaversineDistance(
            currentposition!.latitude,
            currentposition!.longitude,
            targetLat,
            targetLon);

        // Menghitung jarak antara posisi pengguna dan titik target menggunakan Manhattan
        double manhattanDistance = calculateManhattanDistance(
            currentposition!.latitude,
            currentposition!.longitude,
            targetLat,
            targetLon);

        // Menghitung jarak antara posisi pengguna dan titik target menggunakan Euclidean
        double euclideanDistance = calculateEuclideanDistance(
            currentposition!.latitude,
            currentposition!.longitude,
            targetLat,
            targetLon);

        // Menampilkan hasil perhitungan jarak dalam meter
        haversineDistanceText =
            'Haversine Distance: ${haversineDistance.toStringAsFixed(2)} meters';
        manhattanDistanceText =
            'Manhattan Distance: ${manhattanDistance.toStringAsFixed(2)} meters';
        euclideanDistanceText =
            'Euclidean Distance: ${euclideanDistance.toStringAsFixed(2)} meters';
      });
    } catch (e) {
      print(e);
    }

    return position;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Location'),
      ),
      body: Center(
        child: Column(
          children: [
            Text(currentAddress),
            currentposition != null
                ? Text(
                    'Latitude = ${currentposition!.latitude}') // Use null-aware operator
                : Container(),
            currentposition != null
                ? Text(
                    'Longitude = ${currentposition!.longitude}') // Use null-aware operator
                : Container(),
            currentposition != null ? Text(haversineDistanceText) : Container(),
            currentposition != null ? Text(manhattanDistanceText) : Container(),
            currentposition != null ? Text(euclideanDistanceText) : Container(),
            TextButton(
              onPressed: () {
                _determinePosition();
              },
              child: Text('Locate me'),
            )
          ],
        ),
      ),
    );
  }
}

// Fungsi untuk menghitung jarak menggunakan algoritma Haversine
double calculateHaversineDistance(
    double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // Radius of the Earth in meters

  // Convert latitude and longitude from degrees to radians
  double lat1Rad = degreesToRadians(lat1);
  double lon1Rad = degreesToRadians(lon1);
  double lat2Rad = degreesToRadians(lat2);
  double lon2Rad = degreesToRadians(lon2);

  // Calculate the differences between the latitudes and longitudes
  double dLat = lat2Rad - lat1Rad;
  double dLon = lon2Rad - lon1Rad;

  // Haversine formula
  double a = pow(sin(dLat / 2), 2) +
      cos(lat1Rad) * cos(lat2Rad) * pow(sin(dLon / 2), 2);
  double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  double distance = earthRadius * c; // Distance in meters

  return distance;
}

// Fungsi untuk menghitung jarak menggunakan algoritma Manhattan
double calculateManhattanDistance(
    double lat1, double lon1, double lat2, double lon2) {
  // Convert latitude and longitude to radians
  double lat1Rad = degreesToRadians(lat1);
  double lon1Rad = degreesToRadians(lon1);
  double lat2Rad = degreesToRadians(lat2);
  double lon2Rad = degreesToRadians(lon2);

  // Calculate differences
  double latDiff = (lat2Rad - lat1Rad).abs();
  double lonDiff = (lon2Rad - lon1Rad).abs();

  // Calculate Manhattan distance
  double manhattanDistance = latDiff + lonDiff;

  return manhattanDistance *
      6371000; // Convert to meters (1 degree ≈ 111000 meters)
}

// Fungsi untuk menghitung jarak menggunakan algoritma Euclidean
double calculateEuclideanDistance(
    double lat1, double lon1, double lat2, double lon2) {
  // Convert latitude and longitude to radians
  double latDiff = degreesToRadians(lat2 - lat1);
  double lonDiff = degreesToRadians(lon2 - lon1);

  // Calculate Euclidean distance
  double euclideanDistance = sqrt(latDiff * latDiff + lonDiff * lonDiff);

  return euclideanDistance *
      6371000; // Convert to meters (1 degree ≈ 111000 meters)
}

// Fungsi untuk mengkonversi derajat menjadi radian
double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}
