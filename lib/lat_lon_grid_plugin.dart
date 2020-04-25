library lat_lon_grid_plugin;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'dart:math';

// MapPluginLatLonGridOptions
class MapPluginLatLonGridOptions extends LayerOptions {
  Color lineColor;
  Color textColor;
  Color textBackgroundColor;
  bool showCardinalDirections = false;
  bool showCardinalDirectionsAsPrefix = false;
  double textSize = 12.0;
  bool placeLabels = true;
  bool rotateLonLabels = true;
  bool placeLabelsOnLines = true;
  double offsetLonTextBottom = 50;
  double offsetLatTextLeft = 75;

  // overscan ensures that label are visible even if line is not already
  // prevents label popup effect when sliding in
  // TODO: not implemented right now
  bool enableOverscan = true;

  MapPluginLatLonGridOptions({this.lineColor = Colors.black,
    this.textColor = Colors.white,
    this.textBackgroundColor = Colors.black,
    this.showCardinalDirections = true,
    this.showCardinalDirectionsAsPrefix = false,
    this.textSize = 12.0,
    this.placeLabels = true,
    this.rotateLonLabels = true,
    this.placeLabelsOnLines = true,
    this.offsetLonTextBottom = 50,
    this.offsetLatTextLeft = 75,
    this.enableOverscan = true});
}

// MapPluginLatLonGrid
class MapPluginLatLonGrid implements MapPlugin {
  final MapPluginLatLonGridOptions options;

  MapPluginLatLonGrid({this.options});

  @override
  Widget createLayer(LayerOptions options, MapState mapState,
      Stream<Null> stream) {
    if (options is MapPluginLatLonGridOptions) {
      return Center(
        child: CustomPaint(
          // the child empty Container ensures that CustomPainter gets a size
          // (not w=0 and h=0)
          child: Container(),
          painter: LatLonPainter(options: options, mapState: mapState),
        ),
      );
    }

    throw Exception('Unknown options type for MyCustom'
        'plugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapPluginLatLonGridOptions;
  }
}

// GridLabel
// TODO: not used right now
class GridLabel {
  double val;
  int digits;
  double posx;
  double posy;
  bool isLat;

  GridLabel(this.val, this.digits, this.posx, this.posy, this.isLat);
}

class LatLonPainter extends CustomPainter {
  double mMultiplier = 1.0;
  double w = 0;
  double h = 0;
  MapPluginLatLonGridOptions options;
  MapState mapState;
  final Paint mPaint = new Paint();

  // TODO: not used right now
  List<GridLabel> lonGridLabels = new List();
  List<GridLabel> latGridLabels = new List();

  LatLonPainter({this.options, this.mapState}) {
    mPaint.color = options.lineColor;
    mPaint.strokeWidth = 0.5;
    mPaint.isAntiAlias = true; // default anyway
  }

  @override
  void paint(Canvas canvas, Size size) {
    w = size.width;
    h = size.height;

    List<double> inc = getIncrementor(mapState.zoom.round());

    // store bounds
    double north = mapState.bounds.north;
    double west = mapState.bounds.west;
    double south = mapState.bounds.south;
    double east = mapState.bounds.east;

    Bounds b = mapState.getPixelBounds(mapState.zoom);
    CustomPoint topLeftPixel = b.topLeft;

    // draw north-south lines
    List<double> lonPos = generatePositions(west, east, inc[0]);
    lonGridLabels.clear();
    for (int i = 0; i < lonPos.length; i++) {
      // convert point to pixels
      CustomPoint projected =
      mapState.project(LatLng(north, lonPos[i]), mapState.zoom);
      double pixelPos = projected.x - topLeftPixel.x;

      // draw line
      var pTopNorth = Offset(pixelPos, 0);
      var pBottomSouth = Offset(pixelPos, h);
      canvas.drawLine(pTopNorth, pBottomSouth, mPaint);

      if(options.placeLabels) {
        // add to list
        // TODO: not used right now
        lonGridLabels.add(GridLabel(lonPos[i], inc[1].toInt(), pixelPos,
            h - options.offsetLonTextBottom, false));

        // draw labels
        drawText(canvas, lonPos[i], inc[1].toInt(), pixelPos,
            h - options.offsetLonTextBottom, false);
      }
    }

    // draw west-east lines
    List<double> latPos = generatePositions(south, north, inc[0]);
    latGridLabels.clear();
    for (int i = 0; i < latPos.length; i++) {
      // convert back to pixels
      CustomPoint projected =
      mapState.project(LatLng(latPos[i], east), mapState.zoom);
      double pixelPos = projected.y - topLeftPixel.y;

      // draw line
      var pLeftWest = Offset(0, pixelPos);
      var pRightEast = Offset(w, pixelPos);
      canvas.drawLine(pLeftWest, pRightEast, mPaint);

      if(options.placeLabels) {
        // add to list
        // TODO: not used right now
        latGridLabels.add(
            GridLabel(latPos[i], inc[1].toInt(), options.offsetLatTextLeft,
                pixelPos, true));

        // draw labels
        drawText(canvas, latPos[i], inc[1].toInt(), options.offsetLatTextLeft,
              pixelPos, true);
      }
    }
  }

  // TODO: Refactor using lat/lon grid label variables
  // TODO: this function should get a list of text labels and a list of positions
  void drawText(Canvas canvas, double val, int digits, double posx, double posy,
      bool isLat) {

    // add prefix if enabled
    String sAbbr = "";
    if (options.showCardinalDirections) {
      if (isLat) {
        if (val > 0) {
          sAbbr = "N";
        } else {
          val *= -1;
          sAbbr = "S";
        }
      } else {
        if (val > 0) {
          sAbbr = "E";
        } else {
          val *= -1;
          sAbbr = "W";
        }
      }
    }
    // convert degree value to text
    // with defined digits amount after decimal point
    String sDegree = val.toStringAsFixed(digits).toString();

    // build text string
    String sText = "";
    if (!options.showCardinalDirections) {
      sText = sDegree;
    } else {
      // do not add for zero degrees
      if (val != 0) {
        if (options.showCardinalDirectionsAsPrefix) {
          sText = sAbbr + sDegree;
        } else {
          sText = sDegree + sAbbr;
        }
      } else {
        // no leading minus sign before zero
        sText = "0";
      }
    }

    // setup all text painter objects
    var textStyle = TextStyle(
        backgroundColor: options.textBackgroundColor,
        color: options.textColor,
        fontSize: options.textSize);
    var textSpan = TextSpan(style: textStyle, text: sText);
    var textPainter =
    TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();

    // calc offset to place labels on lines
    double offsetX = options.placeLabelsOnLines ? textPainter.width / 2 : 0;
    double offsetY = options.placeLabelsOnLines ? textPainter.height / 2 : 0;

    // reset unwanted offset depending on lat or lon
    isLat ? offsetX = 0 : offsetY = 0;

    // actual pixel draw positions
    double x = posx - offsetX;
    double y = posy - offsetY;

    // check for longitude and enabled rotation
    if (!isLat && options.rotateLonLabels) {
      // canvas is rotated around top left corner clock-wise
      // no other API call available
      canvas.save();
      canvas.rotate(-90.0 / 180.0 * pi);

      // TODO: get alignment 100% right with textPainter.height and .width
      // calc compensated position and draw
      double xCompensated = - y - textPainter.height;
      double yCompensated = x;
      textPainter.paint(canvas, Offset(xCompensated, yCompensated));

      // restore canvas
      canvas.restore();
    } else {
      // draw text
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(LatLonPainter oldDelegate) {
    return false;
  }

  // Generate a list of doubles between start and end with spacing inc.
  List<double> generatePositions(double start, double end, double inc) {
    List<double> list = new List();

    // find first long to draw from
    double currentPos = roundUp(start, inc);
    list.add(currentPos);

    // TODO: bad coding style, no explicit exit condition
    // tested on extreme zoom levels and rotation, working
    bool run = true;
    while (run) {
      currentPos += inc;
      list.add(currentPos);
      if (currentPos >= end) {
        run = false;
      }
    }
    return list;
  }

  // roundUp
  double roundUp(double number, double fixedBase) {
    if (fixedBase != 0 && number != 0) {
      double sign = number > 0 ? 1 : -1;
      number *= sign;
      number /= fixedBase;
      int fixedPoint = number.ceil().toInt();
      number = fixedPoint * fixedBase;
      number *= sign;
    }
    return number;
  }

  // Proven values taken from osmdroid LatLon function
  List<double> getIncrementor(int zoom) {
    List<double> ret = new List();

    // add the increment as first list item
    if (zoom < 0) {
      ret.add(45 * mMultiplier);
    } else {
      switch (zoom) {
        case 0:
          ret.add(45 * mMultiplier);
          break;
        case 1:
          ret.add(30 * mMultiplier);
          break;
        case 2:
          ret.add(15 * mMultiplier);
          break;
        case 3:
          ret.add(9 * mMultiplier);
          break;
        case 4:
          ret.add(6 * mMultiplier);
          break;
        case 5:
          ret.add(3 * mMultiplier);
          break;
        case 6:
          ret.add(2 * mMultiplier);
          break;
        case 7:
          ret.add(1 * mMultiplier);
          break;
        case 8:
          ret.add(0.5 * mMultiplier);
          break;
        case 9:
          ret.add(0.25 * mMultiplier);
          break;
        case 10:
          ret.add(0.1 * mMultiplier);
          break;
        case 11:
          ret.add(0.05 * mMultiplier);
          break;
        case 12:
          ret.add(0.025 * mMultiplier);
          break;
        case 13:
          ret.add(0.0125 * mMultiplier);
          break;
        case 14:
          ret.add(0.00625 * mMultiplier);
          break;
        case 15:
          ret.add(0.003125 * mMultiplier);
          break;
        case 16:
          ret.add(0.0015625 * mMultiplier);
          break;
        case 17:
          ret.add(0.00078125 * mMultiplier);
          break;
        case 18:
          ret.add(0.000390625 * mMultiplier);
          break;
        case 19:
          ret.add(0.0001953125 * mMultiplier);
          break;
        case 20:
          ret.add(0.00009765625 * mMultiplier);
          break;
        case 21:
          ret.add(0.000048828125 * mMultiplier);
          break;
        default:
          ret.add(0.0000244140625 * mMultiplier);
          break;
      }
    }

    // add decimal precision as second list value
    // hard coded from hand
    if (zoom <= 7) {
      ret.add(0);
    } else if (zoom == 8 || zoom == 10) {
      ret.add(1);
    } else if (zoom == 9) {
      ret.add(2);
    } else {
      // zoom >= 10
      ret.add(zoom - 10.0 + 1.0);
    }

    return ret;
  }
}
