[![Pub](https://img.shields.io/pub/v/lat_lon_grid_plugin.svg)](https://pub.dev/packages/lat_lon_grid_plugin)

# lat_lon_grid_plugin

Adds a latitude / longitude grid as plugin to the [flutter_map](https://github.com/johnpryan/flutter_map/).

# Getting Started

Example application under `/example/`:

![Example](lat_lon_grid_plugin_example.png)

# Usage

```yaml
dependencies:
  flutter_map: any
  lat_lon_grid_plugin: any
```

Include the `FlutterMap` into your widget tree.

Please note: Make sure to place the `MapPluginLatLonGridOptions()` right after `TileLayerOptions()` so it does not consume touch events from other layer widgets.

```dart
  FlutterMap(
    mapController: _mapController,
    options: MapOptions(
      center: LatLng(37.7, 13.5),
      zoom: 7.0,
      plugins: [
        MapPluginLatLonGrid(),
      ],
    ),
    layers: [
      TileLayerOptions(
        urlTemplate:
            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        subdomains: ['a', 'b', 'c'],
      ),
      MapPluginLatLonGridOptions(
        lineWidth: 0.5,
        // apply alpha for grid lines
        lineColor: Color.fromARGB(100, 0, 0, 0),
        textColor: Colors.white,
        textBackgroundColor: Colors.black,
        showCardinalDirections: true,
        showCardinalDirectionsAsPrefix: false,
        textSize: 12.0,
        showLabels: true,
        rotateLonLabels: true,
        placeLabelsOnLines: true,
        offsetLonTextBottom: 20.0,
        offsetLatTextLeft: 20.0,
      ),
    ],
  ),
```
