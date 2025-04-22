import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_webservice/places.dart' as places;
import 'package:google_maps_webservice/directions.dart' as directions;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

void main() {
  // Ensure the app only runs on iOS and Android
  if (defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.android) {
    runApp(const MyApp());
  } else {
    print('This app is only supported on iOS and Android.');
    return;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with jusxt a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoadingPage(),
    );
  }
}

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  @override
  void initState() {
    super.initState();
    // Navigate to MyHomePage after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MyHomePage(title: 'Flutter Demo Home Page'),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              '../assets/images/logo.png', // Make sure to add your logo to assets
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 20),
            // App Name
            const Text(
              'Your App Name',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            // Loading Bar
            const SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Colors.grey,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(45.521563, -122.677433);
  Position? currentPosition;
  bool _isLoading = true;
  Set<Marker> _markers = {};
  Set<Marker> _savedMarkers = {};
  Set<Polyline> _polylines = {};
  LatLng? _selectedLocation;
  int _markerCounter = 0;
  final TextEditingController _searchController = TextEditingController();
  late places.GoogleMapsPlaces placesService;
  late directions.GoogleMapsDirections directionsService;
  bool _showSearchDialog = false;
  String? _selectedMarkerId;

  @override
  void initState() {
    super.initState();
    placesService = places.GoogleMapsPlaces(
      apiKey: 'AIzaSyD1hu5_nsOzoorl2IIspFdQJrr3XTeXvLk',
    );
    directionsService = directions.GoogleMapsDirections(
      apiKey: 'AIzaSyD1hu5_nsOzoorl2IIspFdQJrr3XTeXvLk',
    );
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() {
        currentPosition = position;
        _isLoading = false;
      });

      if (mapController != null) {
        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showInfoDialog(String title, String snippet, LatLng position) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(snippet),
              const SizedBox(height: 10),
              Text('Latitude: ${position.latitude.toStringAsFixed(6)}'),
              Text('Longitude: ${position.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _buildPathToLocation(position);
                },
                child: const Text('Get Directions'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedMarkerId = null;
      _selectedLocation = location;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: location,
          infoWindow: InfoWindow(
            title: 'Selected Location',
            snippet: 'Tap to get more information',
            onTap: () => _showInfoDialog(
              'Selected Location',
              'Tap "Get Directions" to build a path to this location',
              location,
            ),
          ),
          icon: BitmapDescriptor.defaultMarker,
        ),
      };
    });
  }

  Future<void> _buildPathToLocation(LatLng destination) async {
    if (currentPosition == null) return;

    try {
      final origin = places.Location(
        lat: currentPosition!.latitude,
        lng: currentPosition!.longitude,
      );
      final destinationLoc = places.Location(
        lat: destination.latitude,
        lng: destination.longitude,
      );

      final response = await directionsService.directionsWithLocation(
        origin,
        destinationLoc,
        travelMode: directions.TravelMode.driving,
      );

      if (response.isOkay) {
        final points = response.routes[0].overviewPolyline.points;
        final polylinePoints = PolylinePoints();
        final decodedPoints = polylinePoints.decodePolyline(points);

        setState(() {
          _polylines = {
            Polyline(
              polylineId: const PolylineId('route'),
              points: decodedPoints
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList(),
              color: Colors.blue,
              width: 5,
            ),
          };
        });
      }
    } catch (e) {
      print('Error building path: $e');
    }
  }

  void _onMarkerTapped(String markerId) {
    setState(() {
      _selectedMarkerId = markerId;
    });
  }

  void _addSavedMarker() {
    if (_selectedLocation != null) {
      setState(() {
        _markerCounter++;
        final markerId = 'saved_marker_$_markerCounter';
        final markerPosition = _selectedLocation!;
        _savedMarkers.add(
          Marker(
            markerId: MarkerId(markerId),
            position: markerPosition,
            infoWindow: InfoWindow(
              title: 'Saved Location $_markerCounter',
              snippet: 'Tap to get more information',
              onTap: () => _showInfoDialog(
                'Saved Location $_markerCounter',
                'This is a saved location. Tap "Get Directions" to build a path to this location.',
                markerPosition,
              ),
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            onTap: () => _onMarkerTapped(markerId),
          ),
        );
        _selectedLocation = null;
        _markers.clear();
      });
    }
  }

  void _removeSelectedMarker() {
    if (_selectedMarkerId != null) {
      setState(() {
        _savedMarkers.removeWhere(
            (marker) => marker.markerId.value == _selectedMarkerId);
        _polylines.clear();
        _selectedMarkerId = null;
      });
    }
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) return;

    try {
      places.PlacesSearchResponse response =
          await placesService.searchByText(query);
      if (response.results.isNotEmpty) {
        var place = response.results.first;
        LatLng location = LatLng(
          place.geometry!.location.lat,
          place.geometry!.location.lng,
        );

        setState(() {
          _selectedLocation = location;
          _markers = {
            Marker(
              markerId: const MarkerId('search_result'),
              position: location,
              infoWindow: InfoWindow(
                title: place.name,
                snippet: place.formattedAddress ?? 'No address available',
                onTap: () => _showInfoDialog(
                  place.name,
                  '${place.formattedAddress ?? 'No address available'}\nType: ${place.types?.join(', ') ?? 'Unknown'}',
                  location,
                ),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          };
        });

        mapController.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: location, zoom: 15),
          ),
        );
      }
    } catch (e) {
      print('Error searching places: $e');
    }
  }

  void _toggleSearchDialog() {
    setState(() {
      _showSearchDialog = !_showSearchDialog;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: currentPosition != null
                            ? LatLng(
                                currentPosition!.latitude,
                                currentPosition!.longitude,
                              )
                            : const LatLng(-6.200000, 106.816666),
                        zoom: 12,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      zoomGesturesEnabled: true,
                      scrollGesturesEnabled: true,
                      rotateGesturesEnabled: true,
                      tiltGesturesEnabled: true,
                      markers: {..._markers, ..._savedMarkers},
                      polylines: _polylines,
                      onMapCreated: (GoogleMapController controller) {
                        setState(() {
                          mapController = controller;
                        });
                      },
                      onTap: _onMapTapped,
                    ),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator()),
                    Positioned(
                      bottom: 100,
                      right: 20,
                      child: Column(
                        children: [
                          FloatingActionButton.small(
                            heroTag: 'zoomIn',
                            onPressed: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomIn(),
                              );
                            },
                            child: const Icon(Icons.add),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                          const SizedBox(height: 10),
                          FloatingActionButton.small(
                            heroTag: 'zoomOut',
                            onPressed: () {
                              mapController.animateCamera(
                                CameraUpdate.zoomOut(),
                              );
                            },
                            child: const Icon(Icons.remove),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),
                        ],
                      ),
                    ),
                    // Add path building button near markers
                    ..._savedMarkers.map((marker) {
                      return Positioned(
                        left: marker.position.longitude,
                        top: marker.position.latitude,
                        child: GestureDetector(
                          onTap: () => _buildPathToLocation(marker.position),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.directions,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleSearchDialog,
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _selectedMarkerId != null
                          ? _removeSelectedMarker
                          : (_selectedLocation != null
                              ? _addSavedMarker
                              : null),
                      icon: Icon(_selectedMarkerId != null
                          ? Icons.delete
                          : Icons.add_location),
                      label: Text(_selectedMarkerId != null
                          ? 'Delete Marker'
                          : 'Add Marker'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_showSearchDialog)
            GestureDetector(
              onTap: _toggleSearchDialog,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 100),
                    width: MediaQuery.of(context).size.width * 0.8,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search location...',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: () {
                                _searchPlaces(_searchController.text);
                                _toggleSearchDialog();
                              },
                            ),
                          ),
                          onSubmitted: (value) {
                            _searchPlaces(value);
                            _toggleSearchDialog();
                          },
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _toggleSearchDialog,
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
