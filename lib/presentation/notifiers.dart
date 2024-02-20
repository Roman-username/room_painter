import 'dart:ui';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vector_math/vector_math.dart';

import 'styles.dart';

part 'notifiers.g.dart';

typedef Cut = ({Offset tail, Offset head});

@riverpod
class PointsNotifier extends _$PointsNotifier {
  @override
  List<Offset> build() => [];

  Offset? _checkNewCutIntersections(Offset head1, List<Offset> points,
      {bool static = false}) {
    Offset tail1 = points[points.length - (static ? 1 : 2)];

    // Проверяем на пересечения новый отрезок с существующими от ПОСЛЕДНЕГО
    for (int i = points.length - 2; i >= 0; i--) {
      final tail2 = points[i];
      final head2 = points[i + 1];

      // конец отрезка tail1-head1 на отрезке tail2-head2 и сам им не является
      if (_pointOnCut(head1, tail2, head2) &&
          getPointIdx(head1) != getPointIdx(head2)) {
        return head1;
      }
      final interPoint = _getIntersectionPoint(
        (tail: tail1, head: head1),
        (tail: tail2, head: head2),
      );

      if (interPoint == null) continue;
      return interPoint;
    }
    return null;
  }

  Offset _getNearestValidPoint(Offset point, List<Offset> points,
      {bool static = false}) {
    if (point.dy < 0) point = Offset(point.dx, 0);
    if (points.length <= 1) return point;

    final interPoint = _checkNewCutIntersections(
      point,
      points,
      static: static,
    );
    if (interPoint == null) return point;

    const allowRadius = kWallWidth + kVertexRadius;
    final prevPoint = points[points.length - (static ? 1 : 2)];

    double x = interPoint.dx;
    if (prevPoint.dx > interPoint.dx) x += allowRadius;
    if (prevPoint.dx < interPoint.dx) x -= allowRadius;
    double y = interPoint.dy;
    if (prevPoint.dy > interPoint.dy) y += allowRadius;
    if (prevPoint.dy < interPoint.dy) y -= allowRadius;

    return Offset(x, y);
  }

  int? getPointIdx(Offset point) {
    final idx = state.indexWhere((Offset p) =>
        p.dx < point.dx + kCatchVertexRadius &&
        p.dx > point.dx - kCatchVertexRadius &&
        p.dy < point.dy + kCatchVertexRadius &&
        p.dy > point.dy - kCatchVertexRadius);
    return idx == -1 ? null : idx;
  }

  void add(Offset point) {
    if (isClosed()) return;
    final p = _getNearestValidPoint(point, state, static: true);
    final newState = state.toList();
    newState.add(p);
    state = newState;
  }

  void replaceEdgePoint(int fromIdx, Offset to) {
    final validPoint = _getNearestValidPoint(
      to,
      fromIdx == 0 ? state.reversed.toList() : state,
    );
    final newState = state.toList();
    newState[fromIdx] = validPoint;
    state = newState;
  }

  (Offset?, Offset?) _checkVertexSidesIntersections(
    Offset head1,
    int vertexIdx,
    List<Offset> points,
  ) {
    Offset tail11 = points[(vertexIdx - 1) % points.length];
    Offset tail12 = points[(vertexIdx + 1) % points.length];

    Offset? intersectionPoint1;
    Offset? intersectionPoint2;

    // Проверяем первое ребро вершины
    for (int i = points.length - 2; i >= 0; i--) {
      final tail2 = points[i];
      final head2 = points[i + 1];

      final isVertexEdge = i == vertexIdx || i + 1 == vertexIdx;
      if (isVertexEdge) continue;

      if (_pointOnCut(head1, tail2, head2)) {
        intersectionPoint1 = head1;
        break;
      }

      final interPoint = _getIntersectionPoint(
        (tail: tail11, head: head1),
        (tail: tail2, head: head2),
      );

      if (interPoint == null) continue;
      intersectionPoint1 = interPoint;
      break;
    }

    // Проверяем второе ребро вершины
    for (int i = points.length - 2; i >= 0; i--) {
      final tail2 = points[i];
      final head2 = points[i + 1];

      final isVertexEdge = i == vertexIdx || i + 1 == vertexIdx;
      if (isVertexEdge) continue;

      if (_pointOnCut(head1, tail2, head2)) {
        intersectionPoint2 = head1;
        break;
      }
      final interPoint = _getIntersectionPoint(
        (tail: tail12, head: head1),
        (tail: tail2, head: head2),
      );

      if (interPoint == null) continue;
      intersectionPoint2 = interPoint;
      break;
    }
    return (intersectionPoint1, intersectionPoint2);
  }

  Offset? _getNearestValidVertex(
    Offset point,
    int vertexIdx,
    List<Offset> points,
  ) {
    if (point.dy < 0) point = Offset(point.dx, 0);

    final (interPoint1, interPoint2) = _checkVertexSidesIntersections(
      point,
      vertexIdx,
      points,
    );
    if (interPoint1 == null && interPoint2 == null) return point;

    const allowRadius = (kWallWidth + kVertexRadius) / 2;

    if (interPoint1 != null && interPoint2 != null) {
      double x = interPoint1.dx - (interPoint1.dx - interPoint2.dx) / 2;
      double y = interPoint1.dy - (interPoint1.dy - interPoint2.dy) / 2;
      final prevPoint = points[(vertexIdx - 1) % points.length];
      final nextPoint = points[(vertexIdx + 1) % points.length];

      if (prevPoint.dx > x) x += allowRadius;
      if (prevPoint.dx < x) x -= allowRadius;
      if (prevPoint.dy > y) y += allowRadius;
      if (prevPoint.dy < y) y -= allowRadius;

      if (nextPoint.dx > x) x += allowRadius;
      if (nextPoint.dx < x) x -= allowRadius;
      if (nextPoint.dy > y) y += allowRadius;
      if (nextPoint.dy < y) y -= allowRadius;

      return Offset(x, y);
    }

    // Если есть только одна точка пересечения
    Offset intersectionPoint = interPoint1 ?? interPoint2!;

    final prevPoint = points[(vertexIdx - 1) % points.length];
    final nextPoint = points[(vertexIdx + 1) % points.length];

    double x = intersectionPoint.dx;
    if (prevPoint.dx > intersectionPoint.dx) x += allowRadius;
    if (prevPoint.dx < intersectionPoint.dx) x -= allowRadius;
    double y = intersectionPoint.dy;
    if (prevPoint.dy > intersectionPoint.dy) y += allowRadius;
    if (prevPoint.dy < intersectionPoint.dy) y -= allowRadius;

    if (nextPoint.dx > intersectionPoint.dx) x += allowRadius;
    if (nextPoint.dx < intersectionPoint.dx) x -= allowRadius;
    if (nextPoint.dy > intersectionPoint.dy) y += allowRadius;
    if (nextPoint.dy < intersectionPoint.dy) y -= allowRadius;

    return Offset(x, y);
  }

  void moveVertex({required int vertexIdx, required Offset to}) {
    final toPoint = _getNearestValidVertex(to, vertexIdx, state);
    if (toPoint == null) return;
    final newState = state.toList();
    newState[vertexIdx] = toPoint;
    if (isClosed() && (vertexIdx == 0 || vertexIdx == newState.length - 1)) {
      newState[0] = newState[newState.length - 1] = toPoint;
    }
    state = newState;
  }

  void close() {
    if (state.length < 3) return;
    if (getPointIdx(state.last) == 0) {
      final newState = state.toList();
      newState[newState.length - 1] = newState[0];
      state = newState;
    }
  }

  void clear() => state = [];

  bool isClosed() => state.length > 1 && state.first == state.last;
}

bool _pointOnCut(Offset point, Offset tail, Offset head) {
  // https://habr.com/ru/articles/148325/ задача 3
  final vTailHead = Vector2(head.dx - tail.dx, head.dy - tail.dy);
  final vTailPoint = Vector2(point.dx - tail.dx, point.dy - tail.dy);
  final cross = vTailHead.cross(vTailPoint);

  final vPointTail = Vector2(tail.dx - point.dx, tail.dy - point.dy);
  final vPointHead = Vector2(head.dx - point.dx, head.dy - point.dy);
  final dot = vPointTail.dot(vPointHead);

  // Длина перпендикуляра от point до tail-head
  final distance = cross.abs() / vTailHead.length;

  // Точка лежит между tail и head && на расстоянии толщины отрезка + погрешность
  if (dot <= 0 && distance <= kWallWidth + kInaccuracy) return true;
  return false;
}

Offset? _getIntersectionPoint(Cut cut1, Cut cut2) {
  // https://habr.com/ru/articles/148325/ задача 3
  // https://habr.com/ru/articles/267037/
  final (tail1, head1) = (cut1.tail, cut1.head);
  final (tail2, head2) = (cut2.tail, cut2.head);
  final vTail1Head1 = Vector2(head1.dx - tail1.dx, head1.dy - tail1.dy);
  final vTail1Tail2 = Vector2(tail2.dx - tail1.dx, tail2.dy - tail1.dy);
  final vTail1Head2 = Vector2(head2.dx - tail1.dx, head2.dy - tail1.dy);
  final z11 = vTail1Head1.cross(vTail1Tail2);
  final z12 = vTail1Head1.cross(vTail1Head2);
  if (z11 * z12 >= 0) return null;

  final vTail2Head2 = Vector2(head2.dx - tail2.dx, head2.dy - tail2.dy);
  final vTail2Tail1 = Vector2(tail1.dx - tail2.dx, tail1.dy - tail2.dy);
  final vTail2Head1 = Vector2(head1.dx - tail2.dx, head1.dy - tail2.dy);
  final z21 = vTail2Head2.cross(vTail2Tail1);
  final z22 = vTail2Head2.cross(vTail2Head1);
  if (z21 * z22 >= 0) return null;

  final x = tail2.dx + vTail2Head2.x * (z11 / (z12 - z11).abs()).abs();
  final y = tail2.dy + vTail2Head2.y * (z11 / (z12 - z11).abs()).abs();
  return Offset(x, y);
}
