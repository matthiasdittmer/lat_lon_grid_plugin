import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:lat_lon_grid_plugin/lat_lon_grid_plugin.dart';
import 'package:latlong2/latlong.dart';

void main() => runApp(MyApp());

/// Sample application
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lat lon grid example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

/// HomePage which shows the use of the plugin
class HomePage extends StatefulWidget {
  /// constructor for the HomePage widget
  HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MapController? _mapController;
  String _sLatLonZoom = '';

  void _resetRotation() {
    _mapController!.rotate(0);
    setState(_updateLabel);
  }

  void _updateLabel() {
    if (_mapController != null) {
      String lat = _mapController!.center.latitude.toStringAsFixed(3);
      String lon = _mapController!.center.longitude.toStringAsFixed(3);
      String zoom = _mapController!.zoom.toStringAsFixed(2);
      String rotation = _mapController!.rotation.toStringAsFixed(2);

      // don't trigger rebuild while building aka. when the first build didn't finish yet
      if (_sLatLonZoom == '') {
        _sLatLonZoom = 'lat: $lat lon: $lon\nzoom: $zoom rotation: $rotation';
      } else {
        setState(() {
          _sLatLonZoom = 'lat: $lat lon: $lon\nzoom: $zoom rotation: $rotation';
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // hacked together
    // https://stackoverflow.com/questions/49466556/flutter-run-method-on-widget-build-complete
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateLabel());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Example'),
        actions: <Widget>[
          SizedBox(
            height: 50.0,
            width: 250.0,
            child: Container(
              height: 80.0,
              color: Colors.blue,
              child: Column(
                children: <Widget>[
                  Text(
                    _sLatLonZoom,
                    style: TextStyle(color: Colors.white, fontSize: 17.0),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              center: LatLng(51.814, -2.170),
              zoom: 6.15,
              rotation: 0.0,
              onPositionChanged: (position, hasGesture) => _updateLabel(),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: ['a', 'b', 'c'],
              ),
              LatLonGridLayer(
                options: LatLonGridLayerOptions(
                  lineWidth: 0.5,
                  // apply alpha for grid lines
                  lineColor: Color.fromARGB(100, 0, 0, 0),
                  labelStyle: TextStyle(
                    color: Colors.white,
                    backgroundColor: Colors.black,
                    fontSize: 12.0,
                  ),
                  showCardinalDirections: true,
                  showCardinalDirectionsAsPrefix: false,
                  showLabels: true,
                  rotateLonLabels: true,
                  placeLabelsOnLines: true,
                  offsetLonLabelsBottom: 20.0,
                  offsetLatLabelsLeft: 20.0,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 5.0, right: 5.0),
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                height: 50.0,
                width: 200.0,
                child: Container(
                  color: Colors.white,
                  child: TextButton(
                    child: Text(
                      'Reset Rotation',
                      style: TextStyle(fontSize: 20.0),
                    ),
                    onPressed: _resetRotation,
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
