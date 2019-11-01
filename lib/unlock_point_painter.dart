import 'package:flutter/material.dart';

import 'gesture_unlock_view.dart';
import 'unlock_point.dart';

class UnlockPointPainter extends CustomPainter {
  final UnlockType type;
  final List<UnlockPoint> points;
  final double radius;
  final double solidRadius;
  final double lineWidth;
  final Color defaultColor;
  final Color selectedColor;
  final Color failedColor;
  final Color disableColor;

  UnlockPointPainter(
      {this.type,
      this.points,
      this.radius,
      this.solidRadius,
      this.lineWidth,
      this.defaultColor,
      this.selectedColor,
      this.failedColor,
      this.disableColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (radius == null) return;
    var paint = Paint();

    if (type == UnlockType.solid) {
      ///画圆
      _paintPoint(canvas, paint);
    } else {
      _paintPointWithHollow(canvas, paint);
    }
  }

  void _paintPointWithHollow(Canvas canvas, Paint paint) {
    paint.strokeWidth = lineWidth;
    for (UnlockPoint point in points) {
      switch (point.status) {
        case UnlockStatus.normal:
          {
            paint.color = defaultColor;
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.success:
          {
            paint.style = PaintingStyle.fill;
            paint.color = selectedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.failed:
          {
            paint.style = PaintingStyle.fill;
            paint.color = failedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.style = PaintingStyle.stroke;
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.disable:
          {
            paint.color = disableColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            break;
          }
      }
    }
  }

  void _paintPoint(Canvas canvas, Paint paint) {
    for (UnlockPoint point in points) {
      switch (point.status) {
        case UnlockStatus.normal:
          {
            paint.color = defaultColor;
            paint.style = PaintingStyle.fill;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            break;
          }
        case UnlockStatus.success:
          {
            paint.color = selectedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.color = selectedColor.withAlpha(14);
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.failed:
          {
            paint.color = failedColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            paint.color = failedColor.withAlpha(14);
            canvas.drawCircle(point.toOffset(), radius, paint);
            break;
          }
        case UnlockStatus.disable:
          {
            paint.color = disableColor;
            canvas.drawCircle(point.toOffset(), solidRadius, paint);
            break;
          }
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
