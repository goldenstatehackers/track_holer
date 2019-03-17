import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:geoflutterfire/geoflutterfire.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: FireMap());
  }
}

class FireMap extends StatefulWidget {
  @override
  State createState() => FireMapState();
}

class FireMapState extends State<FireMap> {
  GoogleMapController mapController;

  Location location = Location();

  Firestore firestore = Firestore.instance;
  Geoflutterfire geo = Geoflutterfire();

  Set<Marker> liked = new Set();

  @override
  Widget build(context) => Scaffold(
      appBar: AppBar(
        title: Text("Map"),
        actions: [
          IconButton(
            icon: Icon(Icons.list),
            onPressed: _goToSaved,
          )
        ],
      ),
      body: Stack(children: [
        GoogleMap(
          initialCameraPosition:
              CameraPosition(target: LatLng(24.150, -110.32), zoom: 10),
          onMapCreated: _onMapCreated,
          trackCameraPosition: true,
          myLocationEnabled: true,
        ),
        Positioned(
          bottom: 50,
          right: 10,
          child: FlatButton(
            onPressed: _addMarker,
            child: Icon(Icons.pin_drop),
            color: Colors.green,
          ),
        )
      ]));

  void _goToSaved() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext context) {
        var divided = ListTile.divideTiles(
          context: context,
          tiles: _buildTiles(),
        ).toList();

        return Scaffold(
          appBar: AppBar(),
          body: new ListView(
            children: divided,
          ),
        );
      },
    ));
  }

  Iterable<ListTile> _buildTiles() {
    return mapController.markers.map((Marker marker) {
      final title = marker.options.infoWindowText.title;
      final coord = marker.options.infoWindowText.snippet;
      final text = "$title: $coord";

      final bool alreadyLiked = liked.contains(marker);

      return ListTile(
        title: Text(text),
        trailing: Icon(
          Icons.thumb_up,
          color: alreadyLiked ? Colors.blue : null,
        ),
        onTap: () {
          setState(() {
            if (alreadyLiked) {
              liked.remove(marker);
            } else {
              liked.add(marker);
            }
          });
        },
      );
    });
  }

  void _addMarker() {
    var mapTarget = mapController.cameraPosition.target;
    final latitude = mapTarget.latitude;
    final longitude = mapTarget.longitude;

    final formattedLat = latitude.toStringAsFixed(2);
    final formattedLon = longitude.toStringAsFixed(2);
    final position = "Lat: $formattedLat, Lon: $formattedLon";

    mapController.addMarker(MarkerOptions(
        position: mapTarget,
//        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindowText: InfoWindowText("Crash", position)));

    GeoFirePoint point = geo.point(latitude: latitude, longitude: longitude);

    firestore
        .collection('locations')
        .add({'position': point.data, 'name': 'Pot hole'});
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      firestore
          .collection('locations')
          .getDocuments()
          .then((q) => q.documents.forEach(_addDoc));
    });
  }

  void _addDoc(DocumentSnapshot doc) {
    final latitude = doc.data['position']['geopoint'].latitude;
    final longitude = doc.data['position']['geopoint'].longitude;

    final formattedLat = latitude.toStringAsFixed(2);
    final formattedLon = longitude.toStringAsFixed(2);
    final position = "Lat: $formattedLat, Lon: $formattedLon";

    mapController.addMarker(MarkerOptions(
        position: LatLng(latitude, longitude),
        icon: BitmapDescriptor.defaultMarker,
        infoWindowText: InfoWindowText("Pot hole", position)));
  }
}
