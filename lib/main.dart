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
  // final double latitude2 = -6.2333005612485435;
  // final double longitude2 = 106.72562947292523;
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
      //Get lat long dari GPS Geolocator
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      //Get lat long geocodin utk alamat secara manual (tester)
      // List<Placemark> placemarks = await placemarkFromCoordinates(
      //   latitude2, // Gunakan latitude manual
      //   longitude2, // Gunakan longitude manual
      // );

      Placemark place = placemarks[0];

      setState(() {
        // Get lat long dari GPS Geolocator
        currentposition = position;

        // Get lat long geolocator utk rumus secara manual (tester)
        // currentposition = Position(
        //     latitude: latitude2,
        //     longitude: longitude2,
        //     timestamp: DateTime
        //         .now(),
        //     accuracy: 0.0,
        //     altitude: 0.0,
        //     heading: 0.0,
        //     speed: 0.0,
        //     speedAccuracy:
        //         0.0
        //     );
        // _determinePosition();

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
            currentposition != null ? Text(manhattanDistanceText) : Container(),
            currentposition != null ? Text(euclideanDistanceText) : Container(),
            currentposition != null
                ? Column(
                    children: [
                      Text(haversineDistanceText),
                      calculateHaversineDistance(
                                  currentposition!.latitude,
                                  currentposition!.longitude,
                                  targetLat,
                                  targetLon) <=
                              500
                          ? Text('Kamu berada di jangkauan radius')
                          : Text('Kamu berada di luar jangkauan radius')
                    ],
                  )
                : Container(),
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

// Rumus Matematika Haversine
// haversine_distance = 2 * r * arcsin(sqrt(sin^2((lat2 - lat1)/2) + cos(lat1) * cos(lat2) * sin^2((lon2 - lon1)/2)))
// Fungsi untuk menghitung jarak menggunakan algoritma Haversine
double calculateHaversineDistance(
    double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // Radius of the Earth in meters

  // Convert latitude and longitude from degrees to radians
  double lat1Rad = degreesToRadians(lat1);
  double lon1Rad = degreesToRadians(lon1);
  double lat2Rad = degreesToRadians(lat2);
  double lon2Rad = degreesToRadians(lon2);

  double haversineDistance = 2 *
      earthRadius *
      asin(sqrt(sin((lat2Rad - lat1Rad) / 2) * sin((lat2Rad - lat1Rad) / 2) +
          cos(lat1Rad) *
              cos(lat2Rad) *
              sin((lon2Rad - lon1Rad) / 2) *
              sin((lon2Rad - lon1Rad) / 2)));

  return haversineDistance;
}

// Rumus Matematika Manhattan
// manhattan_distance = 𝑑(x, y) = ∑ |x − y| atau |x2 - x1| + |y2 - y1| atau
// manhattan_distance = |lat2 - lat1| + |lon2 - lon1|
// Fungsi untuk menghitung jarak menggunakan algoritma Manhattan
double calculateManhattanDistance(
    double lat1, double lon1, double lat2, double lon2) {
  final double latDiff = (lat2 - lat1).abs();
  final double lonDiff = (lon2 - lon1).abs();

  final double manhattanDistance = latDiff + lonDiff;

  return manhattanDistance * 111000; // (1 degree ≈ 111000 meters)
}

// Rumus Matematika Euclidian
// euclidian_distance = d(x, y) = √∑(x − y)^2 atau √[(x2 - x1)^2 + (y2 - y1)^2] atau
// euclidean_distance = √[(lat2 - lat1)^2 + (lon2 - lon1)^2]
// Fungsi untuk menghitung jarak menggunakan algoritma Euclidean
double calculateEuclideanDistance(
    double lat1, double lon1, double lat2, double lon2) {
  final double latDiff = lat2 - lat1;
  final double lonDiff = lon2 - lon1;

  final double euclideanDistance = sqrt(latDiff * latDiff + lonDiff * lonDiff);

  return euclideanDistance * 111000; // (1 degree ≈ 111000 meters)
}

// Fungsi untuk mengkonversi derajat menjadi radian
double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}
