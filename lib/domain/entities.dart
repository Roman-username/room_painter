import 'dart:math';

class Point {
  final double x;
  final double y;

  const Point(this.x, this.y);
}

class Line {
  final Point startPoint;
  final Point endPoint;

  const Line(this.startPoint, this.endPoint);

  double get length => sqrt(pow((startPoint.x - endPoint.x), 2) +
      pow((startPoint.y - endPoint.y), 2));
}

class Polygon {
  final List<Point> vertices;

  const Polygon(this.vertices);
}
