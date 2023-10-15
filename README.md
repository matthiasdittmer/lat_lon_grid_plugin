[![Pub](https://img.shields.io/pub/v/lat_lon_grid_plugin.svg)](https://pub.dev/packages/lat_lon_grid_plugin)

# lat_lon_grid_plugin

Adds a latitude / longitude grid as plugin to the [flutter_map](https://github.com/johnpryan/flutter_map/).

Supported [flutter_map versions](https://github.com/fleaflet/flutter_map/releases):
* Supports flutter_map version 3.0.0 (tested in October 2022).
* Supports flutter_map versions 3.1.0 and 4.0.0 (tested in May 2023).
* Supports flutter_map version 5.0.0 (tested in June 2023).

Notes for new flutter_map 6.0.0 release:
* Does **not** support flutter_map version 6.0.0 yet (tested in October 2023). 
* Migration of plugin to flutter_map 6.0.0 include breaking changes which makes the plugin incompatible with all previous flutter_map versions.
* Minimal required flutter_map version will move up to 6.0.0.
* Migration work and testing will be done on a separate branch for now.
* Migration work does include major changes concerning the rotation logic. 
* With 6.0.0 the rotation logic is broken. The lines and label do not rotate.

# Getting Started

Example application under `/example/`:

<img src="https://github.com/matthiasdittmer/lat_lon_grid_plugin/blob/master/lat_lon_grid_plugin_example.png?raw=true" 
     alt="screenshot" height="1000"/>

# Usage

```yaml
dependencies:
  flutter_map: any
  lat_lon_grid_plugin: any
```

Include the `FlutterMap` into your widget tree.

```dart
  FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      center: LatLng(51.814, -2.170),
      zoom: 6.15,
      rotation: 0.0,
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
```
