import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rooms_painter/presentation/notifiers.dart';
import 'package:rooms_painter/presentation/styles.dart';
import 'package:rooms_painter/presentation/widgets.dart';

import 'constants.dart';

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  int? capturedPointIdx;

  @override
  Widget build(BuildContext context) {
    AppBar appBar = AppBar(title: const Text('Demo'));
    double appBarHeight = appBar.preferredSize.height;
    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    final pointsNotifier = ref.watch(pointsNotifierProvider.notifier);
    List<Offset> points = ref.watch(pointsNotifierProvider);
    return Scaffold(
      appBar: appBar,
      body: Stack(children: [
        SizedBox(
          height: height - appBarHeight,
          width: width,
          child: GestureDetector(
            onPanDown: (details) {
              final point = details.localPosition;
              setState(
                  () => capturedPointIdx = pointsNotifier.getPointIdx(point));
              if (capturedPointIdx == null) pointsNotifier.add(point);
            },
            onPanUpdate: (details) async {
              var point = details.localPosition;
              if (capturedPointIdx == null &&
                  ref.read(pointsNotifierProvider).length == 1) {
                pointsNotifier.add(point);
                setState(() => capturedPointIdx =
                    ref.read(pointsNotifierProvider).length - 1);
                return;
              }
              if ((capturedPointIdx == 0 ||
                      capturedPointIdx ==
                          ref.read(pointsNotifierProvider).length - 1 ||
                      capturedPointIdx == null) &&
                  !pointsNotifier.isClosed()) {
                return pointsNotifier.replaceEdgePoint(
                  capturedPointIdx ??
                      ref.read(pointsNotifierProvider).length - 1,
                  point,
                );
              }
              if (capturedPointIdx != null && points.length > 2) {
                return pointsNotifier.moveVertex(
                  vertexIdx: capturedPointIdx == 0
                      ? ref.read(pointsNotifierProvider).length - 1
                      : capturedPointIdx!,
                  to: point,
                );
              }
            },
            onPanEnd: (details) {
              setState(() => capturedPointIdx = null);
              pointsNotifier.close();
            },
            child: CustomPaint(
              painter: BackgroundPainter(),
              foregroundPainter: RoomPainter(
                points: points,
                closed: pointsNotifier.isClosed(),
                polygonDirection: pointsNotifier.getPolygonDirection(),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: () => pointsNotifier.clear(),
          icon: const Icon(
            Icons.delete,
            color: Colors.red,
          ),
        )
      ]),
    );
  }
}

class RoomPainter extends CustomPainter {
  final List<Offset> points;
  final bool closed;
  final PolygonDirection polygonDirection;

  const RoomPainter({
    required this.points,
    required this.closed,
    required this.polygonDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isNotEmpty) drawRoom(canvas);
    drawPoint(canvas);
  }

  void drawRoom(Canvas canvas) {
    final path = Path();

    final wallsPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black
      ..strokeWidth = kWallWidth
      ..strokeCap = StrokeCap.round;

    if (closed) fillRoom(canvas);

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final finish = points[i + 1];
      path.moveTo(start.dx, start.dy);
      path.lineTo(finish.dx, finish.dy);
      drawLength(
        canvas: canvas,
        line: (start: start, finish: finish),
      );
    }
    canvas.drawPath(path, wallsPaint);
  }

  void fillRoom(Canvas canvas) {
    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;
    final Path filledArea = Path();
    filledArea.addPolygon(points, closed);
    canvas.drawPath(filledArea, fillPaint);
  }

  void drawLength({
    required Canvas canvas,
    required ({Offset start, Offset finish}) line,
  }) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    final (start, finish) = (line.start, line.finish);
    final length = (finish - start).distance;
    double angle = (finish - start).direction;

    textPainter.text = TextSpan(
      text: '${(length * kWallLengthScale).toStringAsFixed(2)} м.',
      style: kLengthTextStyle,
    );

    textPainter.layout();
    final lineCenter = Offset(
      (start.dx + finish.dx) / 2,
      (start.dy + finish.dy) / 2,
    );

    final yShift = switch (polygonDirection) {
      PolygonDirection.clockwise => -(textPainter.height + kWallWidth),
      PolygonDirection.counterclockwise => kWallWidth
    };

    Offset startText = lineCenter.translate(-textPainter.width / 2, yShift);

    // что бы текст не был вверх ногами
    if (angle >= pi / 2 && angle <= pi || angle >= -pi && angle <= -pi / 2) {
      angle += pi;
      startText = startText.translate(
        0,
        polygonDirection == PolygonDirection.clockwise
            ? textPainter.height + 2 * kWallWidth
            : -(textPainter.height + 2 * kWallWidth),
      );
    }

    canvas.save();

    canvas.translate(lineCenter.dx, lineCenter.dy);
    canvas.rotate(angle);
    canvas.translate(-lineCenter.dx, -lineCenter.dy);

    textPainter.paint(canvas, startText);

    canvas.restore();
  }

  void drawPoint(Canvas canvas) {
    const radius = kVertexRadius;
    for (int i = 0; i < points.length; i++) {
      canvas.drawCircle(
          points[i],
          radius,
          Paint()
            ..color =
                i == points.length - 1 ? Colors.green : kVerticesBorderColor);
      canvas.drawCircle(
          points[i], radius - 2, Paint()..color = kVerticesFillColor);
    }
  }

  @override
  bool shouldRepaint(covariant RoomPainter oldDelegate) {
    return !listEquals(oldDelegate.points, points) ||
        oldDelegate.closed != closed;
  }
}
