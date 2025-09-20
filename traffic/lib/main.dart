import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

const String backendUrl = 'https://your-backend-server.com/api/emergency';

void main() {
  runApp(const EmergencyApp());
}

class EmergencyApp extends StatelessWidget {
  const EmergencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Green Corridor',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _makeCallAndNavigate(BuildContext context) async {
    const String emergencyNumber = 'tel:1000';
    final Uri phoneUri = Uri.parse(emergencyNumber);
    
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EmergencyFormScreen()),
          );
        }
      } else {
        throw Exception('Could not launch $emergencyNumber');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not initiate call: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Emergency Green Corridor',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[600],
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital,
                  size: 80,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Emergency Green Corridor',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Quick access to emergency services\nClear traffic path to hospital',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  gradient: LinearGradient(
                    colors: [Colors.red[600]!, Colors.red[800]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _makeCallAndNavigate(context),
                    borderRadius: BorderRadius.circular(35),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.phone,
                            size: 32,
                            color: Colors.white,
                          ),
                          SizedBox(width: 16),
                          Text(
                            'EMERGENCY CALL 1000',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 24),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'For genuine emergencies only.\nMisuse is punishable by law.',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EmergencyFormScreen extends StatefulWidget {
  const EmergencyFormScreen({super.key});

  @override
  State<EmergencyFormScreen> createState() => _EmergencyFormScreenState();
}

class _EmergencyFormScreenState extends State<EmergencyFormScreen> {
  final TextEditingController _vehicleNumberController = TextEditingController();
  final TextEditingController _emergencyTypeController = TextEditingController();
  File? _imageFile;
  Uint8List? _imageBytesWeb;
  bool _isLoading = false;
  LatLng? _currentLocation;
  final Location _location = Location();

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _vehicleNumberController.dispose();
    _emergencyTypeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          return;
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          return;
        }
      }

      LocationData locationData = await _location.getLocation();
      setState(() {
        _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _imageBytesWeb = bytes;
            _imageFile = null;
          });
        } else {
          setState(() {
            _imageFile = File(pickedFile.path);
            _imageBytesWeb = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_vehicleNumberController.text.isEmpty ||
        _emergencyTypeController.text.isEmpty ||
        (_imageFile == null && _imageBytesWeb == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields and take a photo.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_currentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Getting current location. Please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      await _getCurrentLocation();
      if (_currentLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get location. Please check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // For demo purposes, we'll use real location-based hospital finding
      final nearestHospital = await _findNearestHospital(_currentLocation!);
      await Future.delayed(const Duration(seconds: 2));
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MapScreen(
              userLocation: _currentLocation!,
              hospitalLocation: nearestHospital,
              vehicleNumber: _vehicleNumberController.text,
              emergencyType: _emergencyTypeController.text,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<List<LatLng>> _getNearbyHospitals(LatLng userLocation) async {
    // This is a simplified version. In a real app, you would use:
    // 1. Google Places API
    // 2. Overpass API (OpenStreetMap)
    // 3. Your own hospital database API

    try {
      // For now, we'll use a more comprehensive list based on your actual location
      // You can replace this with actual API calls
      final List<LatLng> allHospitals = [
        // Major hospitals across different cities in India
        // Delhi
        const LatLng(28.6139, 77.2090), // AIIMS Delhi
        const LatLng(28.5706, 77.2484), // Fortis Escorts Heart Institute
        const LatLng(28.5355, 77.2483), // Max Hospital Saket
        
        // Mumbai
        const LatLng(19.0760, 72.8777), // King Edward Memorial Hospital
        const LatLng(19.0596, 72.8295), // Tata Memorial Hospital
        const LatLng(19.1075, 72.8263), // Kokilaben Hospital
        
        // Bangalore
        const LatLng(12.9716, 77.5946), // Manipal Hospital
        const LatLng(12.9698, 77.6205), // Fortis Hospital Bannerghatta
        const LatLng(12.9352, 77.6245), // Apollo Hospital Bangalore
        
        // Chennai
        const LatLng(13.0827, 80.2707), // Apollo Hospital Chennai
        const LatLng(13.0850, 80.2800), // Fortis Malar Hospital
        const LatLng(13.0700, 80.2650), // Stanley Medical College
        
        // Hyderabad
        const LatLng(17.4435, 78.3772), // Apollo Hospital Hyderabad
        const LatLng(17.4399, 78.4983), // NIMS Hospital
        
        // Pune
        const LatLng(18.5679, 73.9143), // Ruby Hall Clinic
        const LatLng(18.5204, 73.8567), // Sassoon Hospital
        
        // Kolkata
        const LatLng(22.5726, 88.3639), // SSKM Hospital
        const LatLng(22.5744, 88.3656), // Medical College Hospital
        
        // Add more hospitals as needed
      ];

      // Filter hospitals within reasonable distance (50km radius)
      const distance = Distance();
      List<LatLng> nearbyHospitals = [];
      
      for (final hospital in allHospitals) {
        final distanceInMeters = distance.as(LengthUnit.Meter, userLocation, hospital);
        if (distanceInMeters <= 50000) { // 50km radius
          nearbyHospitals.add(hospital);
        }
      }
      
      // If no hospitals found within 50km, add closest 3 hospitals
      if (nearbyHospitals.isEmpty) {
        allHospitals.sort((a, b) {
          final distA = distance.as(LengthUnit.Meter, userLocation, a);
          final distB = distance.as(LengthUnit.Meter, userLocation, b);
          return distA.compareTo(distB);
        });
        nearbyHospitals = allHospitals.take(3).toList();
      }
      
      return nearbyHospitals;
    } catch (e) {
      // Fallback to a default hospital location
      return [const LatLng(28.6139, 77.2090)]; // AIIMS Delhi as fallback
    }
  }

  Future<LatLng> _findNearestHospital(LatLng userLocation) async {
    final nearbyHospitals = await _getNearbyHospitals(userLocation);
    
    if (nearbyHospitals.isEmpty) {
      // Emergency fallback
      return const LatLng(28.6139, 77.2090); // AIIMS Delhi
    }
    
    // Find the closest hospital
    double minDistance = double.infinity;
    LatLng nearestHospital = nearbyHospitals.first;
    const distance = Distance();

    for (final hospital in nearbyHospitals) {
      final currentDistance = distance.as(LengthUnit.Meter, userLocation, hospital);
      if (currentDistance < minDistance) {
        minDistance = currentDistance;
        nearestHospital = hospital;
      }
    }
    
    return nearestHospital;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Emergency Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.red[600],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_currentLocation != null)
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.green[600], size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Current Location Detected',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_car, color: Colors.blue[600], size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Vehicle Information',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _vehicleNumberController,
                      decoration: InputDecoration(
                        labelText: 'Vehicle Number',
                        hintText: 'e.g., TN01AB1234',
                        prefixIcon: const Icon(Icons.directions_car),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      textCapitalization: TextCapitalization.characters,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emergencyTypeController,
                      decoration: InputDecoration(
                        labelText: 'Emergency Type',
                        hintText: 'Medical Emergency, Accident, etc.',
                        prefixIcon: const Icon(Icons.warning),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.camera_alt, color: Colors.green[600], size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Vehicle Photo',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        color: Colors.grey[50],
                      ),
                      child: _buildImageWidget(),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 55,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [Colors.blue[600]!, Colors.blue[800]!],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _isLoading ? null : _pickImage,
                          borderRadius: BorderRadius.circular(12),
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.camera_alt, color: Colors.white),
                                SizedBox(width: 12),
                                Text(
                                  'Take Photo of Vehicle',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
            if (_isLoading)
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(
                        color: Colors.green,
                        strokeWidth: 4,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Processing Emergency Request...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 70,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),
                  gradient: LinearGradient(
                    colors: [Colors.green[600]!, Colors.green[800]!],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitForm,
                    borderRadius: BorderRadius.circular(35),
                    child: const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.send, size: 28, color: Colors.white),
                          SizedBox(width: 16),
                          Text(
                            'SUBMIT EMERGENCY REQUEST',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    if (kIsWeb && _imageBytesWeb != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(
          _imageBytesWeb!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else if (_imageFile != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          _imageFile!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No photo taken',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button below to take a photo',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      );
    }
  }
}

class MapScreen extends StatefulWidget {
  final LatLng userLocation;
  final LatLng hospitalLocation;
  final String vehicleNumber;
  final String emergencyType;

  const MapScreen({
    super.key,
    required this.userLocation,
    required this.hospitalLocation,
    required this.vehicleNumber,
    required this.emergencyType,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late LatLng _currentLocation;
  final Location _location = Location();
  StreamSubscription<LocationData>? _locationSubscription;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _currentLocation = widget.userLocation;
    _startLocationTracking();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    _locationSubscription = _location.onLocationChanged.listen((LocationData locationData) {
      if (mounted && locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
        });
        // Update map center to follow user
        _mapController.move(_currentLocation, _mapController.camera.zoom);
      }
    });
  }

  void _showReportCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 32),
              const SizedBox(width: 12),
              const Text('Report Completed'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Has the emergency been resolved?',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vehicle: ${widget.vehicleNumber}', 
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text('Emergency: ${widget.emergencyType}'),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _completeEmergencyReport();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Yes, Complete'),
            ),
          ],
        );
      },
    );
  }

  void _completeEmergencyReport() {
    // Show completion message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency report completed successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );

    // Navigate back to home and clear all previous screens
    Future.delayed(const Duration(milliseconds: 500), () {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (Route<dynamic> route) => false,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Green Corridor Active',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.green[600],
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showReportCompletedDialog,
            icon: const Icon(Icons.flag, color: Colors.white),
            tooltip: 'Complete Report',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tiles.stadiamaps.com/tiles/osm_bright/{z}/{x}/{y}{r}.png',
                userAgentPackageName: 'com.example.emergency_app',
                additionalOptions: const {
                  'attribution': '© Stadia Maps © OpenMapTiles © OpenStreetMap contributors',
                },
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    width: 80,
                    height: 80,
                    point: _currentLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  Marker(
                    width: 80,
                    height: 80,
                    point: widget.hospitalLocation,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.local_hospital,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_currentLocation, widget.hospitalLocation],
                    color: Colors.green,
                    strokeWidth: 6.0,
                  ),
                ],
              ),
            ],
          ),
          // Live tracking indicator
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green[600],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gps_fixed, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'LIVE TRACKING',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green[600],
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Green Corridor Activated',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vehicle: ${widget.vehicleNumber}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Emergency: ${widget.emergencyType}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Emergency services have been notified. Traffic authorities are clearing your route to the hospital. Your location is being tracked live.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.orange[600],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _showReportCompletedDialog,
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flag, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Complete Report',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.blue[600],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final url = 'https://www.google.com/maps/dir/?api=1&origin=${_currentLocation.latitude},${_currentLocation.longitude}&destination=${widget.hospitalLocation.latitude},${widget.hospitalLocation.longitude}&travelmode=driving';
                          final uri = Uri.parse(url);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.navigation, color: Colors.white, size: 24),
                              SizedBox(width: 8),
                              Text(
                                'Navigate',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}