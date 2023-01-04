library lat_lon_grid_plugin;

import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong2/latlong.dart';

/// LatLonGridLayerOptions
class LatLonGridLayerOptions {
  /// color of grid lines
  final Color lineColor;

  /// width of grid lines
  /// can be adjusted even down to 0.1 on high res displays for a light grid
  final double lineWidth;

  /// style of labels
  final TextStyle labelStyle;

  /// show cardinal directions instead of numbers only
  // prevents negative numbers, e.g. 45.5W instead of -45.5
  final bool showCardinalDirections;

  /// show cardinal direction as prefix, e.g. W45.5 instead of 45.5W
  final bool showCardinalDirectionsAsPrefix;

  /// enable labels
  final bool showLabels;

  /// rotate longitude labels 90 degrees
  /// mainly to prevent overlapping on high zoom levels
  final bool rotateLonLabels;

  /// center labels on lines instead of top edge alignment
  final bool placeLabelsOnLines;

  /// offset for longitude labels from the 'bottom' (north up)
  final double offsetLonLabelsBottom;

  /// offset for latitude labels from the 'left' (north up)
  final double offsetLatLabelsLeft;

  /// LatLonGridLayerOptions
  LatLonGridLayerOptions({
    required this.labelStyle,
    this.lineWidth = 0.5,
    this.lineColor = Colors.black,
    this.showCardinalDirections = true,
    this.showCardinalDirectionsAsPrefix = false,
    this.showLabels = true,
    this.rotateLonLabels = true,
    this.placeLabelsOnLines = true,
    this.offsetLonLabelsBottom = 50.0,
    this.offsetLatLabelsLeft = 75.0,
  });

  /// overscan ensures that labels are visible even if line is not already
  /// prevents label popup effect when sliding in
  /// default enabled
  final bool _enableOverscan = true;

  /// enable to do basic profiling for draw() function
  /// default disabled
  final bool _enableProfiling = false;
  int _time = 0;
  static const int _samples = 100;
  final List<int> _profilingVals = [_samples];
  int _profilingValCount = 0;

  /// flag to enable grouped label calls
  /// saves performance for rotated lon labels because canvas will be only
  /// rotated back and forth once
  /// default true (enabled)
  final bool _groupedLabelCalls = true;
}

/// LatLonGridLayer
class LatLonGridLayer extends StatelessWidget {
  /// LatLonGridLayerOptions
  final LatLonGridLayerOptions options;

  /// Plugin options
  LatLonGridLayer({super.key, required this.options});

  @override
  Widget build(BuildContext context) {
    final mapState = FlutterMapState.maybeOf(context)!;
    return Center(
      child: CustomPaint(
        // the child SizedBox.expand() ensures that CustomPainter gets a size
        // (not w=0 and h=0)
        child: SizedBox.expand(),
        painter: _LatLonPainter(options: options, mapState: mapState),
      ),
    );
  }
}

// GridLabel
class _GridLabel {
  double degree;
  int digits;
  double posx;
  double posy;
  bool isLat;
  String? label;
  late TextPainter textPainter;

  _GridLabel(this.degree, this.digits, this.posx, this.posy, this.isLat);
}

class _LatLonPainter extends CustomPainter {
  double w = 0.0;
  double h = 0.0;
  final LatLonGridLayerOptions options;
  final FlutterMapState mapState;
  final Paint mPaint = Paint();

  // list of grid labels for latitude and longitude
  final List<_GridLabel> lonGridLabels = [];
  final List<_GridLabel> latGridLabels = [];

  _LatLonPainter({required this.options, required this.mapState}) {
    mPaint.color = options.lineColor;
    mPaint.strokeWidth = options.lineWidth;
    mPaint.isAntiAlias = true; // default anyway
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (options._enableProfiling) {
      options._time = DateTime.now().microsecondsSinceEpoch;
    }

    w = size.width;
    h = size.height;

    final List<double> inc = getIncrementor(mapState.zoom.round());

    // store bounds
    // mapState.bounds cannot actually be null
    final north = mapState.bounds.north;
    final west = mapState.bounds.west;
    final south = mapState.bounds.south;
    final east = mapState.bounds.east;

    final bounds = mapState.getPixelBounds(mapState.zoom);
    final CustomPoint topLeftPixel = bounds.topLeft;

    // getting the dimensions for a maximal sized text label
    final TextPainter textPainterMax = getTextPaint('180W');
    // maximal width for this label text
    final double textPainterMaxW = textPainterMax.width;
    // height is equal for all not rotated labels
    final double textPainterH = textPainterMax.height;

    // draw north-south lines
    final List<double> lonPos = generatePositions(
        west, east, inc[0], options._enableOverscan, -180.0, 180.0);
    lonGridLabels.clear();
    for (int i = 0; i < lonPos.length; i++) {
      // convert point to pixels
      final CustomPoint projected =
          mapState.project(LatLng(north, lonPos[i]), mapState.zoom);
      final double pixelPos = projected.x - (topLeftPixel.x as double);

      // draw line
      final pTopNorth = Offset(pixelPos, 0.0);
      final pBottomSouth = Offset(pixelPos, h);
      // only draw visible lines, using one complete line width as buffer
      if (pixelPos + options.lineWidth >= 0.0 &&
          pixelPos - options.lineWidth <= w) {
        canvas.drawLine(pTopNorth, pBottomSouth, mPaint);
      }
      // label logic
      if (pixelPos + textPainterMaxW >= 0.0 &&
          pixelPos - textPainterMaxW <= w) {
        if (options.showLabels) {
          if (options._groupedLabelCalls) {
            // add to list
            lonGridLabels.add(_GridLabel(lonPos[i], inc[1].toInt(), pixelPos,
                h - options.offsetLonLabelsBottom - textPainterH, false));
          } else {
            // draw labels
            drawText(canvas, lonPos[i], inc[1].toInt(), pixelPos,
                h - options.offsetLonLabelsBottom - textPainterH, false);
          }
        }
      }
    }

    // draw west-east lines
    final List<double> latPos = generatePositions(
        south, north, inc[0], options._enableOverscan, -90.0, 90.0);
    latGridLabels.clear();
    for (int i = 0; i < latPos.length; i++) {
      // convert back to pixels
      final CustomPoint projected =
          mapState.project(LatLng(latPos[i], east), mapState.zoom);
      final double pixelPos = projected.y - (topLeftPixel.y as double);

      // draw line
      final pLeftWest = Offset(0.0, pixelPos);
      final pRightEast = Offset(w, pixelPos);
      // only draw visible lines, using one complete line width as buffer
      if (pixelPos + options.lineWidth >= 0.0 &&
          pixelPos - options.lineWidth <= h) {
        canvas.drawLine(pLeftWest, pRightEast, mPaint);
      }
      // label logic
      if (pixelPos - textPainterMaxW <= h && pixelPos + textPainterMaxW >= 0) {
        if (options.showLabels) {
          if (options._groupedLabelCalls) {
            // add to list
            latGridLabels.add(_GridLabel(latPos[i], inc[1].toInt(),
                options.offsetLatLabelsLeft, pixelPos, true));
          } else {
            // draw labels
            drawText(canvas, latPos[i], inc[1].toInt(),
                options.offsetLatLabelsLeft, pixelPos, true);
          }
        }
      }
    }

    // group label call
    if (options._groupedLabelCalls) {
      drawLabels(canvas, lonGridLabels);
      drawLabels(canvas, latGridLabels);
    }

    if (options._enableProfiling) {
      addTimeForProfiling(
          DateTime.now().microsecondsSinceEpoch - options._time);
    }
  }

  // add a value to the profiling array
  // search the console for the final results printed after sample count is collected
  void addTimeForProfiling(int time) {
    // do add / calc logic
    if (options._profilingValCount < LatLonGridLayerOptions._samples) {
      // add time
      options._profilingVals[options._profilingValCount] = time;
      options._profilingValCount++;
    } else {
      // calc median here, not using mean here
      // use "effective integer division" as suggested from IDE
      options._profilingVals.sort();
      final int median = options
          ._profilingVals[(LatLonGridLayerOptions._samples - 1) ~/ 2];

      // print median once to console
      print(
          'median of draw() is $median us (out of ${LatLonGridLayerOptions._samples} samples)');
      // reset counter
      options._profilingValCount = 0;
    }
  }

  // function gets a list of GridLabel objects
  // Used to group and reduce canvas draw() and rotate() calls.
  void drawLabels(Canvas canvas, List<_GridLabel> list) {
    // process items to generate text painter
    for (int i = 0; i < list.length; i++) {
      final sText = getText(list[i].degree, list[i].digits, list[i].isLat);
      list[i].textPainter = getTextPaint(sText);
    }

    // canvas call
    canvasCall(canvas, list);
  }

  // draw one text label
  void drawText(Canvas canvas, double degree, int digits, double posx,
      double posy, bool isLat) {
    final list = <_GridLabel>[];
    final label = _GridLabel(degree, digits, posx, posy, isLat);

    // generate textPainter object from input data
    final sText = getText(degree, digits, isLat);
    label.textPainter = getTextPaint(sText);

    // do the actual draw call, pass a list with one item
    list.add(label);
    canvasCall(canvas, list);
  }

  // can be used for a single item or list of items.
  void canvasCall(Canvas canvas, List<_GridLabel> list) {
    // check for at least on entry
    if (list.length == 0) {
      return;
    }

    // check for longitude and enabled rotation
    if (!list[0].isLat && options.rotateLonLabels) {
      // canvas is rotated around top left corner clock-wise
      // no other API call available
      // canvas.translate() is used for that use case, still keeping old code
      canvas.save();
      canvas.rotate(-90.0 / 180.0 * pi);

      // loop for draw calls
      for (int i = 0; i < list.length; i++) {
        // calc compensated position and draw
        final double xCompensated = -list[i].posy - list[i].textPainter.height;
        double yCompensated = list[i].posx;
        if (options.placeLabelsOnLines) {
          // apply additional offset
          yCompensated = list[i].posx - list[i].textPainter.height / 2;
        }
        list[i].textPainter.paint(canvas, Offset(xCompensated, yCompensated));
      }

      // restore canvas
      canvas.restore();
    } else {
      // loop for draw calls
      for (int i = 0; i < list.length; i++) {
        // calc offset to place labels on lines
        double offsetX = options.placeLabelsOnLines
            ? list[i].textPainter.width / 2
            : 0.0;
        double offsetY = options.placeLabelsOnLines
            ? list[i].textPainter.height / 2
            : 0.0;

        // reset unwanted offset depending on lat or lon
        list[i].isLat ? offsetX = 0.0 : offsetY = 0.0;

        // apply offset
        double x = list[i].posx - offsetX;
        double y = list[i].posy - offsetY;

        // draw text
        list[i].textPainter.paint(canvas, Offset(x, y));
      }
    }
  }

  String getText(double degree, int digits, bool isLat) {
    // add prefix if enabled
    String sAbbr = '';
    if (options.showCardinalDirections) {
      if (isLat) {
        if (degree > 0.0) {
          sAbbr = 'N';
        } else {
          degree *= -1.0;
          sAbbr = 'S';
        }
      } else {
        if (degree > 0.0) {
          sAbbr = 'E';
        } else {
          degree *= -1.0;
          sAbbr = 'W';
        }
      }
    }
    // convert degree value to text
    // with defined digits amount after decimal point
    final sDegree = '${degree.toStringAsFixed(digits)}°';

    // build text string
    String sText = '';
    if (!options.showCardinalDirections) {
      sText = sDegree;
    } else {
      // do not add for zero degrees
      if (degree != 0.0) {
        if (options.showCardinalDirectionsAsPrefix) {
          sText = sAbbr + sDegree;
        } else {
          sText = sDegree + sAbbr;
        }
      } else {
        // no leading minus sign before zero
        sText = '0°';
      }
    }

    return sText;
  }

  TextPainter getTextPaint(String text) {
    // setup all text painter objects
    final textSpan = TextSpan(style: options.labelStyle, text: text);
    return TextPainter(text: textSpan, textDirection: TextDirection.ltr)
      ..layout();
  }

  @override
  bool shouldRepaint(_LatLonPainter oldDelegate) {
    return false;
  }

  // Generate a list of doubles between start and end with spacing inc
  List<double> generatePositions(double start, double end, double inc,
      bool extendedRange, double lowerBound, double upperBound) {
    final list = <double>[];

    // find first value
    double currentPos = roundUp(start, inc);
    list.add(currentPos);

    // added assert statements for basic sanity check
    // upperLimit counter guarantees termination
    assert(inc > 1E-5);
    assert(start < end);
    // calc upper limit for iterations
    final double upperLimit = (end - start) / inc;
    int counter = 0;

    while (counter <= upperLimit.ceil()) {
      currentPos += inc;
      list.add(currentPos);
      if (currentPos >= end) {
        break;
      }
      counter++;
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
      final double sign = number > 0 ? 1 : -1;
      number *= sign;
      number /= fixedBase;
      final int fixedPoint = number.ceil().toInt();
      number = fixedPoint * fixedBase;
      number *= sign;
    }
    return number;
  }

  // Proven values taken from osmdroid LatLon function
  List<double> getIncrementor(int zoom) {
    final ret = <double>[];

    const lineSpacingDegrees = <double>[
      45.0,
      30.0,
      15.0,
      9.0,
      6.0,
      3.0,
      2.0,
      1.0,
      0.5,
      0.25,
      0.1,
      0.05,
      0.025,
      0.0125,
      0.00625,
      0.003125,
      0.0015625,
      0.00078125,
      0.000390625,
      0.0001953125,
      0.00009765625,
      0.000048828125,
      0.0000244140625
    ];

    // limit index
    int index = zoom;
    if (zoom <= 0) {
      index = 0;
    } else if (zoom > lineSpacingDegrees.length - 1) {
      index = lineSpacingDegrees.length - 1;
    }
    // pick the right spacing
    ret.add(lineSpacingDegrees[index]);

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
