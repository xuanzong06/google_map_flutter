import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_map_flutter/location_service.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart'; //var location = new Location();
import 'package:http/http.dart' as http;
import 'package:decimal/decimal.dart';
import 'dart:math';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Google Maps Demo',
      home: MapSample(),
    );
  }
}

class MapSample extends StatefulWidget {
  @override
  State<MapSample> createState() => MapSampleState();
}

class MapSampleState extends State<MapSample> {
  // declare parameters --------------------------------------------------------------------------------------------
  Completer<GoogleMapController> _controller = Completer();
  TextEditingController _originController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  Set<Marker> _markers = Set<Marker>();
  Set<Polygon> _polygons = Set<Polygon>();
  Set<Polyline> _polylines = Set<Polyline>();
  List<LatLng> polygonsLatLngs = <LatLng>[];
  int _polygonIdCounter = 1;
  int _polylineIdCounter = 1;
  Location location = new Location();
  bool? _serviceEnabled;
  PermissionStatus? _permissionGranted;
  LocationData? _locationData;

  // I am going to make moveable cameraposition
  // step1 create googlemap controller
  GoogleMapController? _googleMapController;

  // declare parameters --------------------------------------------------------------------------------------------

  // set default coordination of CameraPosition --------------------------------------------------------------------
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(25.033980301361304, 121.56454178002542),
    //25.033980301361304, 121.56454178002542
    zoom: 14.4746,
  );

  // set default coordination of CameraPosition --------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _chkLocationService();
    _setMarker(LatLng(37.42796133580664, -122.085749655962));
    //_listeningPosition();
  }

  void _chkLocationService() async {
    //Check ------
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled!) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled!) {
        return;
      }
    }
    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    //Check ------
    _locationData = await location.getLocation();
    print(
        "------------------------------------------------------------------------------");
    print(_locationData);
    _originController.text = _locationData.toString();
    print(
        "------------------------------------------------------------------------------");

    _setMarker(LatLng(_locationData!.latitude!, _locationData!.longitude!));
    //CameraPosition _kGooglePlex2 = CameraPosition(target: LatLng(_locationData!.latitude!, _locationData!.longitude!), zoom: 15);

    location.onLocationChanged.listen((event) {
      print(_locationData);
    });
  }

  void _setMarker(LatLng point) {
    setState(() {
      _markers.add(
        Marker(
          markerId: MarkerId('marker'),
          position: point,
        ),
      );
    });
  }

  void _setPolygon() {
    final String polygonIdVal = 'polygon_$_polygonIdCounter';
    _polygonIdCounter++;

    _polygons.add(
      Polygon(
          polygonId: PolygonId(polygonIdVal),
          points: polygonsLatLngs,
          strokeWidth: 2,
          fillColor: Colors.transparent),
    );
  }

  void _setPolyline(List<PointLatLng> points) {
    final String polylineIdVal = 'polygon_$_polylineIdCounter';
    _polylineIdCounter++;

    _polylines.add(
      Polyline(
        polylineId: PolylineId(polylineIdVal),
        width: 2,
        color: Colors.blue,
        points: points
            .map(
              (point) => LatLng(point.latitude, point.longitude),
            )
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Google Maps'),
      ),
      body: Column(
        children: [
          Row(
            children: [
              // Expanded(
              //   child: Column(
              //     children: [
              //       TextFormField(
              //         controller: _originController,
              //         decoration: InputDecoration(hintText: 'Origin'),
              //         onChanged: (value) {
              //           print(value);
              //         },
              //       ),
              //       TextFormField(
              //         controller: _destinationController,
              //         decoration: InputDecoration(hintText: 'Destination'),
              //         onChanged: (value) {
              //           print(value);
              //         },
              //       ),
              //     ],
              //   ),
              // ),
              IconButton(
                onPressed: () async {
                  // var directions = await LocationService().getDirections(
                  //   _originController.text,
                  //   _destinationController.text,
                  // );
                  // _goToPlace(
                  //   directions['start_location']['lat'],
                  //   directions['start_location']['lng'],
                  //   directions['bounds_ne'],
                  //   directions['bounds_sw'],
                  // );
                  _getCurrentPosition(
                      _locationData!.latitude!, _locationData!.longitude!);
                  // _setPolyline(directions['polyline_decoded']);
                },
                icon: Icon(Icons.search),
              ),
            ],
          ),
          Expanded(
            child: GoogleMap(
              myLocationEnabled: true,
              //20220425 add
              mapType: MapType.normal,
              // 改變地圖樣式
              markers: _markers,
              polygons: _polygons,
              polylines: _polylines,
              initialCameraPosition: _kGooglePlex,
              //initialCameraPosition: CameraPosition(target: _initialcameraposition),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: (point) {
                setState(() {
                  polygonsLatLngs.add(point);
                  _setPolygon();
                });
              },
            ),
          ),
          OutlinedButton(
            onPressed: () {
              _updatePosition();
            },
            child: Text('Click Me'),
          ),
        ],
      ),
    );
  }

  Future<void> _goToPlace(
    double lat,
    double lng,
    Map<String, dynamic> boundsNe,
    Map<String, dynamic> boundsSw,
  ) async {
    // final lat = place['geometry']['location']['lat'];
    // final lng = place['geometry']['location']['lng'];
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 12),
      ),
    );
    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(boundsSw['lat'], boundsSw['lng']),
            northeast: LatLng(boundsNe['lat'], boundsNe['lng']),
          ),
          25),
    );
    _setMarker(LatLng(lat, lng));
  }

  Future<void> _getCurrentPosition(double lat, double lng) async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(target: LatLng(lat, lng), zoom: 15)));
  }

  Future<void> _listeningPosition() async {
    while (true) {
      _locationData = await location.getLocation();
      _originController.text = _locationData.toString();
      _getCurrentPosition(_locationData!.latitude!, _locationData!.longitude!);
      _setMarker(LatLng(_locationData!.latitude!, _locationData!.longitude!));
      await Future.delayed(Duration(seconds: 10));
    }
  }

  // Zac Test
  // DB Data Type
  // 1 t_dri_id int(11)
  // 2 t_locate_id int(11)
  // 3 t_locate_lat decimal(10,6)
  // 4 t_locate_lng decimal(10,6)
  // 5 t_locate_time timestamp
  // 6 t_box_id int(20)

  //ignored 5 timestamp

  _updatePosition() {
    Random random = Random();
    int driverID = random.nextInt(9999); //測試用隨機產生司機的ID
    int locateID = random.nextInt(9999);
    int boxID = random.nextInt(9999);
    updatePosition(driverID, locateID, Decimal.parse('2.001'),Decimal.parse('2.001'), boxID).then((result) {
      print(result);
      if ("success" == result) {
        print("Add coordinate Successed!!");
      }
    });
  }

  static Future<String> updatePosition(
      int driver_id, int locat_id, Decimal lat, Decimal lng, int box_id) async {
    try {
      var map = Map<String, dynamic>();
      map['action'] = "map";
      map['driver_id'] = driver_id.toString();
      map['locate_id'] = locat_id.toString();
      map['lat'] = lat.toString();
      map['lng'] = lng.toString();
      map['box_id'] = box_id.toString();
      final response = await http
          .post(Uri.parse('http://192.168.31.167:8888/testdb.php'), body: map);
      print('addEmployee Response: ${response.body}');
      if (200 == response.statusCode) {
        return response.body;
      } else {
        return "PHP1 : error";
      }
    } catch (e) {
      return "PHP2 : error: "+e.toString();
    }
  }
}
