import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:lat_lon_grid_plugin/lat_lon_grid_plugin.dart';

void main() => runApp(MyApp());

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

class HomePage extends StatefulWidget {
  HomePage({Key key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MapController _mapController;
  String _sLatLonZoom = "unset";
  var _val = 0;

  _updateRotation(double valNew) {
    setState(() {
      _val = valNew.toInt();
    });
    _updateLabel();
    _mapController.rotate(valNew);
  }

  _updateLabel() {
    if (_mapController != null) {
      String lat = _mapController.center.latitude.toStringAsFixed(3).toString();
      String lon =
          _mapController.center.longitude.toStringAsFixed(3).toString();
      String zoom = _mapController.zoom.toStringAsFixed(2).toString();
      setState(() {
        _sLatLonZoom = ("lat: $lat lon: $lon\nzoom: $zoom rotation: $_val");
      });
    }
  }

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
            width: 250,
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
              center: LatLng(37.7, 13.5),
              zoom: 7.0,
              onPositionChanged: (position, hasGesture) => _updateLabel(),
              plugins: [
                MapPluginLatLonGrid(),
              ],
            ),
            layers: [
              TileLayerOptions(
                  urlTemplate:
                      "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                  subdomains: ['a', 'b', 'c']),
              MapPluginLatLonGridOptions(
                  lineColor: Colors.black,
                  lineWidth: 0.5,
                  textColor: Colors.white,
                  textBackgroundColor: Colors.black,
                  showCardinalDirections: true,
                  showCardinalDirectionsAsPrefix: false,
                  textSize: 12.0,
                  placeLabels: true,
                  placeLabelsOnLines: true,
                  rotateLonLabels: false,
                  enableOverscan: true),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 5.0, right: 5.0),
            child: Align(
              alignment: Alignment.topRight,
              child: SizedBox(
                height: 50,
                width: 200,
                child: Container(
                  color: Colors.blue,
                  child: Column(
                    children: <Widget>[
                      Slider(
                        activeColor: Colors.white,
                        inactiveColor: Colors.grey,
                        value: _val.toDouble(),
                        min: 0.0,
                        max: 360.0,
                        divisions: 360,
                        onChanged: (double valNew) => _updateRotation(valNew),
                        label: '$_val',
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
