library lat_lon_grid_plugin;

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

// MapPluginLatLonGridOptions
class MapPluginLatLonGridOptions extends LayerOptions {
  // color of grid lines
  Color lineColor;
  // width of grid lines
  // can be adjusted even down to 0.1 on high res displays for a light grid
  double lineWidth = 0.5;
  // color of grid labels
  Color textColor;
  // background color of labels
  Color textBackgroundColor;
  // show cardinal directions instead of numbers only
  // prevents negative numbers, e.g. 45.5W instead of -45.5
  bool showCardinalDirections = false;
  // show cardinal direction as prefix, e.g. W45.5 instead of 45.5W
  bool showCardinalDirectionsAsPrefix = false;
  // text size for labels
  double textSize = 12.0;
  // enable labels
  bool showLabels = true;
  // rotate longitude labels 90 degrees
  // mainly to prevent overlapping on high zoom levels
  bool rotateLonLabels = true;
  // center labels on lines instead of top edge alignment
  bool placeLabelsOnLines = true;
  // offset for longitude labels from the 'bottom' (north up)
  double offsetLonTextBottom = 50;
  // offset for latitude labels from the 'left' (north up)
  double offsetLatTextLeft = 75;
  // overscan ensures that labels are visible even if line is not already
  // prevents label popup effect when sliding in
  bool enableOverscan = true;

  MapPluginLatLonGridOptions({
    this.lineColor = Colors.black,
    this.textColor = Colors.white,
    this.lineWidth = 0.5,
    this.textBackgroundColor = Colors.black,
    this.showCardinalDirections = true,
    this.showCardinalDirectionsAsPrefix = false,
    this.textSize = 12.0,
    this.showLabels = true,
    this.rotateLonLabels = true,
    this.placeLabelsOnLines = true,
    this.offsetLonTextBottom = 50,
    this.offsetLatTextLeft = 75,
    this.enableOverscan = true,
  });
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

    throw Exception('Unknown options type for MyCustom plugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MapPluginLatLonGridOptions;
  }
}

// GridLabel
class GridLabel {
  double val;
  int digits;
  double posx;
  double posy;
  bool isLat;
  String label;

  GridLabel(this.val, this.digits, this.posx, this.posy, this.isLat);
}

class LatLonPainter extends CustomPainter {
  double mMultiplier = 1.0;
  double w = 0;
  double h = 0;
  MapPluginLatLonGridOptions options;
  MapState mapState;
  final Paint mPaint = Paint();

  // enable to do basic profiling for draw() function
  // default disabled
  bool enableProfiling = false;
  int time = 0;

  // not used right now, left in code
  List<GridLabel> lonGridLabels = List();
  List<GridLabel> latGridLabels = List();

  LatLonPainter({this.options, this.mapState}) {
    mPaint.color = options.lineColor;
    mPaint.strokeWidth = options.lineWidth;
    mPaint.isAntiAlias = true; // default anyway
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (enableProfiling) {
      time = DateTime.now().microsecondsSinceEpoch;
    }

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
    List<double> lonPos = generatePositions(west, east, inc[0], options.enableOverscan, -180.0, 180.0);
    lonGridLabels.clear();
    for (int i = 0; i < lonPos.length; i++) {
      // convert point to pixels
      CustomPoint projected =
          mapState.project(LatLng(north, lonPos[i]), mapState.zoom);
      double pixelPos = projected.x - topLeftPixel.x;

      // draw line
      Offset pTopNorth = Offset(pixelPos, 0);
      Offset pBottomSouth = Offset(pixelPos, h);
      canvas.drawLine(pTopNorth, pBottomSouth, mPaint);

      if (options.showLabels) {
        // add to list
        /*
        lonGridLabels.add(GridLabel(lonPos[i], inc[1].toInt(), pixelPos,
            h - options.offsetLonTextBottom, false));
        */

        // draw labels
        drawText(canvas, lonPos[i], inc[1].toInt(), pixelPos,
            h - options.offsetLonTextBottom, false);
      }
    }

    // draw west-east lines
    List<double> latPos = generatePositions(south, north, inc[0], options.enableOverscan, -90.0, 90.0);
    latGridLabels.clear();
    for (int i = 0; i < latPos.length; i++) {
      // convert back to pixels
      CustomPoint projected =
          mapState.project(LatLng(latPos[i], east), mapState.zoom);
      double pixelPos = projected.y - topLeftPixel.y;

      // draw line
      Offset pLeftWest = Offset(0, pixelPos);
      Offset pRightEast = Offset(w, pixelPos);
      canvas.drawLine(pLeftWest, pRightEast, mPaint);

      if (options.showLabels) {
        // add to list
        /*
        latGridLabels.add(
            GridLabel(latPos[i], inc[1].toInt(), options.offsetLatTextLeft,
                pixelPos, true));
        */

        // draw labels
        drawText(canvas, latPos[i], inc[1].toInt(), options.offsetLatTextLeft,
              pixelPos, true);
      }
    }

    if(enableProfiling) {
      print('paint() processed in ${DateTime.now().microsecondsSinceEpoch - time} us');
    }
  }

  // function gets a list of GridLabel objects
  // Not used right now. Could be used to group and reduce canvas draw()
  // and rotate() calls. Profiling shows no need for that right now.
  void drawLabels(Canvas canvas, List<GridLabel> list) {
    // not implemented right now
  }

  // draw one text label
  void drawText(Canvas canvas, double val, int digits, double posx, double posy,
      bool isLat) {
    // add prefix if enabled
    String sAbbr = '';
    if (options.showCardinalDirections) {
      if (isLat) {
        if (val > 0) {
          sAbbr = 'N';
        } else {
          val *= -1;
          sAbbr = 'S';
        }
      } else {
        if (val > 0) {
          sAbbr = 'E';
        } else {
          val *= -1;
          sAbbr = 'W';
        }
      }
    }
    // convert degree value to text
    // with defined digits amount after decimal point
    String sDegree = val.toStringAsFixed(digits).toString();

    // build text string
    String sText = '';
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
        sText = '0';
      }
    }

    // setup all text painter objects
    TextStyle textStyle = TextStyle(
        backgroundColor: options.textBackgroundColor,
        color: options.textColor,
        fontSize: options.textSize);
    TextSpan textSpan = TextSpan(style: textStyle, text: sText);
    TextPainter textPainter =
        TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

    // check for longitude and enabled rotation
    if (!isLat && options.rotateLonLabels) {
      // canvas is rotated around top left corner clock-wise
      // no other API call available
      canvas.save();
      canvas.rotate(-90.0 / 180.0 * pi);

      // calc compensated position and draw
      double xCompensated = - posy - textPainter.height;
      double yCompensated = posx;
      if(options.placeLabelsOnLines) {
        // apply additional offset
        yCompensated = posx - textPainter.height / 2;
      }
      textPainter.paint(canvas, Offset(xCompensated, yCompensated));

      // restore canvas
      canvas.restore();
    } else {
      // calc offset to place labels on lines
      double offsetX = options.placeLabelsOnLines ? textPainter.width / 2 : 0;
      double offsetY = options.placeLabelsOnLines ? textPainter.height / 2 : 0;

      // reset unwanted offset depending on lat or lon
      isLat ? offsetX = 0 : offsetY = 0;

      // apply offset
      double x = posx - offsetX;
      double y = posy - offsetY;

      // draw text
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  @override
  bool shouldRepaint(LatLonPainter oldDelegate) {
    return false;
  }

  // Generate a list of doubles between start and end with spacing inc
  List<double> generatePositions(double start, double end, double inc,
      bool extendedRange, double lowerBound, double upperBound) {
    List<double> list = List();

    // find first value
    double currentPos = roundUp(start, inc);
    list.add(currentPos);

    // bad coding style, use with caution
    // added assert statements for basic sanity check
    // does still not guarantee termination for edge case values from inc
    assert(inc > 0);
    assert(start < end);
    bool run = true;
    while (run) {
      currentPos += inc;
      list.add(currentPos);
      if (currentPos >= end) {
        run = false;
      }
    }

    // check for extended range
    if (extendedRange) {
      // add extra lower entry
      if (list[0] - inc > lowerBound) {
        list.insert(0, list[0] - inc);
      }
      // add extra upper entry
      if (list.last + inc < upperBound) {
        list.add(list.last + inc);
      }
    }

    return list;
  }

  // roundUp
  // Taken from here: https://stackoverflow.com/questions/3407012/c-rounding-up-to-the-nearest-multiple-of-a-number
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
    List<double> ret = List();

    // add the increment as first list item
    if (zoom <= 0) {
      ret.add(45 * mMultiplier);
    } else {
      switch (zoom) {
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
