import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:velbis_assignment7/screens/newscreen.dart';
 
class home extends StatefulWidget {
  home({Key? key}) : super(key: key);
 
  @override
  State<home> createState() => _homeState();
}
 
class _homeState extends State<home> {
  static final initialPosition = LatLng(16.0341, 120.4331);
  late GoogleMapController mapController;
 
  late TextEditingController nameController;
  late TextEditingController detailsController;
 
  Set<Marker> markers = {};
 
  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    detailsController = TextEditingController();
    getCurrentLocations();
    loadMarks();
  }
 
  @override
  void dispose() {
    nameController.dispose();
    detailsController.dispose();
    super.dispose();
  }
 
  void getCurrentLocations() async {
    if(!await checkServicePermission()){
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    mapController.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    )));
 
  }
  Future <bool> checkServicePermission() async {
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
 
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location Service is disabled")));
      return false;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permission is denied. Please accept the permission to use map.'),
          ),
        );
      }
      return false;
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permission is permanently denied. Please change it in settings to continue.'),
        ),
      );
      return false;
    }
    return true;
  }
 
  // Load ng Markers from Firebase
  Future<void> loadMarks() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('favoritePlace').get();
 
      markers.clear();
 
      querySnapshot.docs.forEach((doc) {
        dynamic position = doc['position'];
 
        if (position is GeoPoint) {
          // If the position is a GeoPoint, create a LatLng object from it
          LatLng markerPosition = LatLng(position.latitude, position.longitude);
 
          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: markerPosition,
              infoWindow: InfoWindow(
                title: doc['Name Place'] ?? 'Unknown Place',
                snippet: doc['detail'] ?? '',
              ),
            ),
          );
        } else if (position is LatLng) {
          markers.add(
            Marker(
              markerId: MarkerId(doc.id),
              position: position,
              infoWindow: InfoWindow(
                title: doc['Name Place'] ?? 'Unknown Place',
                snippet: doc['detail'] ?? '',
              ),
            ),
          );
        } else {
          print('Invalid position data in Firestore document: $position');
        }
      });
 
      setState(() {});
    } catch (e) {
      print('Error loading markers: $e');
    }
  }
  // End ng LoadMarks
 
 
 
  // Add ng Details sa Markers
  void addPlace(LatLng position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Place Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: 'Place Name'),
            ),
 
            Gap(10),
 
            TextField(
              controller: detailsController,
              decoration: InputDecoration(labelText: 'Place Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
 
          // Adding na tayo sa Firebase
          TextButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty && detailsController.text.isNotEmpty) {
                await FirebaseFirestore.instance.collection('favoritePlace').add({
                  'position': GeoPoint(position.latitude, position.longitude),
                  'Name Place': nameController.text,
                  'detail': detailsController.text,
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Place details successfully added'),
                  ),
                );
                nameController.clear();
                detailsController.clear();
                Navigator.pop(context);
                loadMarks();    
              }
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
  // End ng Details sa Markers
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading:
         IconButton(
            onPressed: loadMarks,
            icon: Icon(Icons.refresh),
          ),
        title: Text('Map'),
        actions: [
         
 
          IconButton(
            onPressed: (){
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => favorites()),
          ).then((value) {
              loadMarks();
          });
            },
            icon: Icon(Icons.favorite)
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child:GoogleMap(
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              mapController = controller;
            },
            onTap: addPlace,
            markers: markers,
          ),
        ),
      ),
    );
  }
}