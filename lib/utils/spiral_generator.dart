import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpiralGenerator {
  /// Generates a spiral path based on the baseline equation from fitting.java
  /// baseX[i] = t[i] * cos(2.5 * t[i])
  /// baseY[i] = t[i] * sin(2.5 * t[i])
  /// where t ranges from 0 to 4*PI
  static Path generateSpiralPath(double canvasSize) {
    const int numPoints = 500;
    const double tMin = 0.0;
    const double tMax = 4 * math.pi;

    final path = Path();
    final List<Offset> points = [];

    // Generate spiral points
    for (int i = 0; i < numPoints; i++) {
      final t = tMin + i * (tMax - tMin) / (numPoints - 1);
      final x = t * math.cos(2.5 * t);
      final y = t * math.sin(2.5 * t);
      points.add(Offset(x, y));
    }

    // Find bounds to scale and center the spiral
    double minX = points.first.dx;
    double maxX = points.first.dx;
    double minY = points.first.dy;
    double maxY = points.first.dy;

    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final maxRange = math.max(rangeX, rangeY);

    // Scale and center with padding
    const padding = 30.0;
    final scale = (canvasSize - 2 * padding) / maxRange;
    final centerX = canvasSize / 2;
    final centerY = canvasSize / 2;
    final offsetX = (minX + maxX) / 2;
    final offsetY = (minY + maxY) / 2;

    // Create path
    bool isFirst = true;
    for (final point in points) {
      final scaledX = centerX + (point.dx - offsetX) * scale;
      final scaledY = centerY + (point.dy - offsetY) * scale;

      if (isFirst) {
        path.moveTo(scaledX, scaledY);
        isFirst = false;
      } else {
        path.lineTo(scaledX, scaledY);
      }
    }

    return path;
  }

  /// Get baseline points for distance calculation
  static List<Offset> getSpiralPoints(double canvasSize, int numPoints) {
    const double tMin = 0.0;
    const double tMax = 4 * math.pi;

    final List<Offset> rawPoints = [];

    // Generate spiral points
    for (int i = 0; i < numPoints; i++) {
      final t = tMin + i * (tMax - tMin) / (numPoints - 1);
      final x = t * math.cos(2.5 * t);
      final y = t * math.sin(2.5 * t);
      rawPoints.add(Offset(x, y));
    }

    // Find bounds
    double minX = rawPoints.first.dx;
    double maxX = rawPoints.first.dx;
    double minY = rawPoints.first.dy;
    double maxY = rawPoints.first.dy;

    for (final point in rawPoints) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }

    final rangeX = maxX - minX;
    final rangeY = maxY - minY;
    final maxRange = math.max(rangeX, rangeY);

    // Scale and center
    const padding = 30.0;
    final scale = (canvasSize - 2 * padding) / maxRange;
    final centerX = canvasSize / 2;
    final centerY = canvasSize / 2;
    final offsetX = (minX + maxX) / 2;
    final offsetY = (minY + maxY) / 2;

    // Apply transformation
    final List<Offset> scaledPoints = [];
    for (final point in rawPoints) {
      final scaledX = centerX + (point.dx - offsetX) * scale;
      final scaledY = centerY + (point.dy - offsetY) * scale;
      scaledPoints.add(Offset(scaledX, scaledY));
    }

    return scaledPoints;
  }
}
