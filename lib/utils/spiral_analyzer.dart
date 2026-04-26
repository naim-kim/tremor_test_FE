import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:scidart/numdart.dart';
import 'package:scidart/scidart.dart';

import '../models/test_result.dart';

/// Spiral analysis result following the updated MATLAB-aligned pipeline.
class SpiralAnalysisResult {
  final double meanError;
  final double maxError;
  final String judgment;
  final double pairingSlope; // Estimated a_ref from pairing module
  final double relativeMeanError; // Mean error normalized by spiral size
  final double relativeTremorAmplitude; // Tremor amp normalized by spiral size
  final double dominantTremorFreq;
  final double avgSpeed;
  final double totalTime;
  final double tremorAmplitude;
  final List<double> distanceErrors;
  final List<Offset> filteredPoints;
  final List<Offset> idealSpiral;

  const SpiralAnalysisResult({
    required this.meanError,
    required this.maxError,
    required this.judgment,
    required this.pairingSlope,
    required this.relativeMeanError,
    required this.relativeTremorAmplitude,
    required this.dominantTremorFreq,
    required this.avgSpeed,
    required this.totalTime,
    required this.tremorAmplitude,
    required this.distanceErrors,
    required this.filteredPoints,
    required this.idealSpiral,
  });
}

/// Spiral Analyzer that mirrors the MATLAB reference implementation.
class SpiralAnalyzer {
  final double upsampleFs; // Target sampling rate for interpolation (Hz)
  final double lowPassCutoffHz; // Low-pass filter cutoff
  final int butterworthOrder;
  final double normalMeanThreshold; // Normal mean error threshold (px)
  final double differenceThreshold; // Margin before flagging abnormality

  const SpiralAnalyzer({
    this.upsampleFs = 1000.0,
    this.lowPassCutoffHz = 3.0,
    this.butterworthOrder = 2,
    this.normalMeanThreshold = 15.0,
    this.differenceThreshold = 5.0,
  });

  static const double _virtualCanvasSize = 300.0;

  SpiralAnalysisResult analyze({
    required List<Offset> refPoints,
    required List<DrawingPoint> drawingPoints,
  }) {
    if (refPoints.isEmpty) {
      throw ArgumentError('Reference points cannot be empty');
    }
    if (drawingPoints.length < 5) {
      throw ArgumentError('At least 5 drawing points are required');
    }

    final rawData = _buildRawData(refPoints, drawingPoints);

    final refRawX = Array(rawData.map((e) => e[0]).toList());
    final refRawY = Array(rawData.map((e) => e[1]).toList());
    final userRawX = Array(rawData.map((e) => e[2]).toList());
    final userRawY = Array(rawData.map((e) => e[3]).toList());
    final timestamp = Array(rawData.map((e) => e[4]).toList());

    final tRawNorm =
        Array(timestamp.map((value) => value - timestamp[0]).toList());

    final double tEnd = tRawNorm.isEmpty ? 0 : tRawNorm.last;
    final double dtMs = 1000.0 / upsampleFs;
    final List<double> tUniformList = [];
    for (double t = 0; t <= tEnd; t += dtMs) {
      tUniformList.add(t);
    }
    if (tUniformList.length < 2) {
      tUniformList.add(tEnd + dtMs);
    }
    final tUniform = Array(tUniformList);

    final userXUp = _interp1(tRawNorm, userRawX, tUniform);
    final userYUp = _interp1(tRawNorm, userRawY, tUniform);

    final refIdxRaw = Array(
      List<double>.generate(refRawX.length, (i) => i.toDouble()),
    );
    final refIdxNew = _linspace(0, refRawX.length - 1.0, tUniform.length);
    final refXUp = _interp1(refIdxRaw, refRawX, refIdxNew);
    final refYUp = _interp1(refIdxRaw, refRawY, refIdxNew);

    final filterCoeffs = _designButterworthLowPass(
        butterworthOrder, lowPassCutoffHz, upsampleFs);
    final userXFilt = _filtfilt(filterCoeffs, userXUp);
    final userYFilt = _filtfilt(filterCoeffs, userYUp);

    final refXFilt = _filtfilt(filterCoeffs, refXUp);
    final refYFilt = _filtfilt(filterCoeffs, refYUp);

    final double refCenterX = (_arrayMax(refXFilt) + _arrayMin(refXFilt)) / 2;
    final double refCenterY = (_arrayMax(refYFilt) + _arrayMin(refYFilt)) / 2;

    final refX = _subtractScalar(refXFilt, refCenterX);
    final refY = _subtractScalar(refYFilt, refCenterY);
    final userX = _subtractScalar(userXFilt, refCenterX);
    final userY = _subtractScalar(userYFilt, refCenterY);

    final tremorX = _subtractScalar(userXUp, refCenterX);
    final tremorY = _subtractScalar(userYUp, refCenterY);

    final pairingRes = calcPairing(userX, userY, refX, refY);
    final speedRes = calcSpeed(userX, userY, tUniform);
    final tremorRes = calcTremor(tremorX, tremorY, upsampleFs);

    final Array distError = pairingRes['dist_error'] as Array;
    final List<double> distErrorList =
        List<double>.from(distError.map((e) => e));
    final double meanError = distErrorList.isEmpty
        ? 0.0
        : distErrorList.reduce((a, b) => a + b) / distErrorList.length;
    final double maxError =
        distErrorList.isEmpty ? 0.0 : distErrorList.reduce(math.max);

    final List<Offset> filteredPoints =
        List<Offset>.generate(userX.length, (i) => Offset(userX[i], userY[i]));

    final Array xPair = pairingRes['x_pair'] as Array;
    final Array yPair = pairingRes['y_pair'] as Array;
    final List<Offset> idealPoints =
        List<Offset>.generate(xPair.length, (i) => Offset(xPair[i], yPair[i]));

    // Use a typical spiral radius (max radius of ideal spiral) for
    // device- and size-independent normalization of error metrics.
    double typicalRadius = 0.0;
    for (final p in idealPoints) {
      final r = p.distance;
      if (r > typicalRadius) {
        typicalRadius = r;
      }
    }
    if (typicalRadius == 0.0) {
      typicalRadius =
          1.0; // Avoid division by zero; keeps relative metrics finite.
    }

    final double relativeMeanError = meanError / typicalRadius;
    final double relativeTremorAmplitude =
        (tremorRes['tremor_amp'] as double) / typicalRadius;

    final String judgment = _getJudgment(meanError);

    return SpiralAnalysisResult(
      meanError: meanError,
      maxError: maxError,
      judgment: judgment,
      pairingSlope: pairingRes['a_ref'] as double,
      relativeMeanError: relativeMeanError,
      relativeTremorAmplitude: relativeTremorAmplitude,
      dominantTremorFreq: tremorRes['peak_freq'] as double,
      avgSpeed: speedRes['avg_speed'] as double,
      totalTime: speedRes['total_time'] as double,
      tremorAmplitude: tremorRes['tremor_amp'] as double,
      distanceErrors: distErrorList,
      filteredPoints: filteredPoints,
      idealSpiral: idealPoints,
    );
  }

  List<List<double>> _buildRawData(
    List<Offset> refPoints,
    List<DrawingPoint> drawingPoints,
  ) {
    final resampledRef = _resampleReference(refPoints, drawingPoints.length);
    final rawData = <List<double>>[];
    for (int i = 0; i < drawingPoints.length; i++) {
      final ref = resampledRef[i];
      final user = drawingPoints[i];

      // Use normalized coordinates (0-1) mapped to a fixed virtual canvas.
      // This makes results device- and resolution-independent.
      final double userVirtualX = user.normalizedX * _virtualCanvasSize;
      final double userVirtualY = user.normalizedY * _virtualCanvasSize;

      rawData.add([
        ref.dx,
        ref.dy,
        userVirtualX,
        userVirtualY,
        user.timestamp.toDouble(),
      ]);
    }
    return rawData;
  }

  List<Offset> _resampleReference(List<Offset> refPoints, int targetLength) {
    if (targetLength <= 1) {
      return [refPoints.first];
    }

    final List<Offset> resampled = [];
    final int maxIndex = refPoints.length - 1;

    final int denominator = targetLength - 1;
    for (int i = 0; i < targetLength; i++) {
      final double ratio = denominator <= 0 ? 0.0 : i / denominator;
      final double scaled = ratio * maxIndex;
      final int low = scaled.floor().clamp(0, maxIndex).toInt();
      final int high = scaled.ceil().clamp(0, maxIndex).toInt();

      if (low == high) {
        resampled.add(refPoints[low]);
        continue;
      }

      final double t = scaled - low;
      final double x =
          refPoints[low].dx + (refPoints[high].dx - refPoints[low].dx) * t;
      final double y =
          refPoints[low].dy + (refPoints[high].dy - refPoints[low].dy) * t;
      resampled.add(Offset(x, y));
    }

    return resampled;
  }

  // --------------------------------------------------------------------------
  // MATLAB-aligned modules
  // --------------------------------------------------------------------------

  static Map<String, dynamic> calcPairing(
    Array userX,
    Array userY,
    Array refX,
    Array refY,
  ) {
    final thetaRef = _unwrap(_atan2(refY, refX));
    final rRef = _sqrt(_add(_multiply(refX, refX), _multiply(refY, refY)));

    List<bool> validIdx = thetaRef.map((t) => t.abs() > 0.5).toList();
    if (validIdx.where((v) => v).length < 10) {
      validIdx = List<bool>.filled(thetaRef.length, true);
    }

    double sumThetaR = 0.0;
    double sumTheta2 = 0.0;
    for (int i = 0; i < thetaRef.length; i++) {
      if (validIdx[i]) {
        sumThetaR += thetaRef[i] * rRef[i];
        sumTheta2 += thetaRef[i] * thetaRef[i];
      }
    }
    final double aRef = sumTheta2 == 0 ? 0.0 : sumThetaR / sumTheta2;

    final thetaUser = _unwrap(_atan2(userY, userX));
    final Array rPairIdeal =
        Array(thetaUser.map((t) => aRef * t).toList(growable: false));
    final Array xPair = _multiply(rPairIdeal, _cos(thetaUser));
    final Array yPair = _multiply(rPairIdeal, _sin(thetaUser));

    final diffX = _subtract(userX, xPair);
    final diffY = _subtract(userY, yPair);
    final distError =
        _sqrt(_add(_multiply(diffX, diffX), _multiply(diffY, diffY)));
    final double meanError = mean(distError);

    return {
      'mean_error': meanError,
      'dist_error': distError,
      'x_pair': xPair,
      'y_pair': yPair,
      'a_ref': aRef,
    };
  }

  static Map<String, dynamic> calcSpeed(
    Array userX,
    Array userY,
    Array tUniform,
  ) {
    final dtArray = _diff(tUniform);
    final double dt = dtArray.isEmpty ? 0.0 : mean(Array(dtArray)) / 1000.0;

    final vx = _gradient(userX, dt);
    final vy = _gradient(userY, dt);
    final speedVec = _sqrt(_add(_multiply(vx, vx), _multiply(vy, vy)));
    final double avgSpeed = mean(speedVec);
    final double totalTime =
        tUniform.isEmpty ? 0.0 : (tUniform.last - tUniform.first) / 1000.0;

    return {
      'avg_speed': avgSpeed.isNaN ? 0.0 : avgSpeed,
      'total_time': totalTime,
      'speed_vec': speedVec,
    };
  }

  static Map<String, dynamic> calcTremor(
    Array tremorX,
    Array tremorY,
    double fs,
  ) {
    var tremorSig =
        _sqrt(_add(_multiply(tremorX, tremorX), _multiply(tremorY, tremorY)));
    tremorSig = _detrend(tremorSig);

    final int n = tremorSig.length;
    final cSig = ArrayComplex(
      List.generate(n, (i) => Complex(real: tremorSig[i], imaginary: 0.0)),
    );
    final yFFT = fft(cSig);

    Array p2 = _absComplex(yFFT);
    p2 = _divideScalar(p2, n.toDouble());

    final int halfLen = (n / 2).floor() + 1;
    final p1 = Array(p2.sublist(0, halfLen));
    for (int i = 1; i < p1.length - 1; i++) {
      p1[i] = p1[i] * 2;
    }

    final f =
        Array(List<double>.generate(halfLen, (i) => fs * i.toDouble() / n));

    const double minFreq = 3.0;
    const double maxFreq = 20.0;

    double maxVal = 0.0;
    double peakFreq = 0.0;
    for (int i = 0; i < f.length; i++) {
      if (f[i] >= minFreq && f[i] <= maxFreq) {
        if (p1[i] > maxVal) {
          maxVal = p1[i];
          peakFreq = f[i];
        }
      }
    }

    return {
      'tremor_amp': maxVal,
      'peak_freq': peakFreq,
      'f': f,
      'P1': p1,
    };
  }

  // --------------------------------------------------------------------------
  // Helper utilities
  // --------------------------------------------------------------------------

  static Array _atan2(Array y, Array x) {
    return Array(
        List<double>.generate(y.length, (i) => math.atan2(y[i], x[i])));
  }

  static Array _sqrt(Array x) {
    return Array(x.map((value) => math.sqrt(value)).toList(growable: false));
  }

  static Array _cos(Array x) {
    return Array(x.map((value) => math.cos(value)).toList(growable: false));
  }

  static Array _sin(Array x) {
    return Array(x.map((value) => math.sin(value)).toList(growable: false));
  }

  static Array _unwrap(Array theta) {
    final diffs = _diff(theta);
    final unwrapped = List<double>.from(theta);
    double correction = 0.0;
    for (int i = 0; i < diffs.length; i++) {
      final double d = diffs[i];
      if (d > math.pi) correction -= 2 * math.pi;
      if (d < -math.pi) correction += 2 * math.pi;
      unwrapped[i + 1] += correction;
    }
    return Array(unwrapped);
  }

  static List<double> _diff(Array x) {
    final res = <double>[];
    for (int i = 0; i < x.length - 1; i++) {
      res.add(x[i + 1] - x[i]);
    }
    return res;
  }

  static Array _gradient(Array f, double h) {
    final g = List<double>.filled(f.length, 0.0);
    final int n = f.length;
    if (n > 1) {
      g[0] = h == 0 ? 0.0 : (f[1] - f[0]) / h;
      g[n - 1] = h == 0 ? 0.0 : (f[n - 1] - f[n - 2]) / h;
    }
    for (int i = 1; i < n - 1; i++) {
      g[i] = h == 0 ? 0.0 : (f[i + 1] - f[i - 1]) / (2 * h);
    }
    return Array(g);
  }

  static Array _interp1(Array x, Array y, Array xi) {
    final yi = <double>[];
    for (final val in xi) {
      int idx = -1;
      for (int i = 0; i < x.length - 1; i++) {
        if (val >= x[i] && val <= x[i + 1]) {
          idx = i;
          break;
        }
      }

      if (idx != -1) {
        final double denom = x[idx + 1] - x[idx];
        final double t = denom == 0 ? 0.0 : (val - x[idx]) / denom;
        yi.add(y[idx] + t * (y[idx + 1] - y[idx]));
      } else {
        if (val < x[0]) {
          yi.add(y[0]);
        } else {
          yi.add(y.last);
        }
      }
    }
    return Array(yi);
  }

  static Array _linspace(double start, double end, int num) {
    if (num <= 1) {
      return Array([start]);
    }
    final double step = (end - start) / (num - 1);
    return Array(
      List<double>.generate(num, (i) => start + i * step),
    );
  }

  static Array _detrend(Array y) {
    final int n = y.length;
    final x = Array(List<double>.generate(n, (i) => i.toDouble()));
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumX2 += x[i] * x[i];
    }
    final double denom = n * sumX2 - sumX * sumX;
    final double slope = denom == 0 ? 0.0 : (n * sumXY - sumX * sumY) / denom;
    final double intercept = (sumY - slope * sumX) / n;
    final trend = Array(List<double>.generate(n, (i) => slope * i + intercept));
    return _subtract(y, trend);
  }

  static Array _filtfilt(_BiquadCoefficients coeffs, Array data) {
    final int padLen = math.min(data.length - 1, 20);
    if (padLen <= 0) {
      final forward = _applyBiquad(data, coeffs);
      final revForward = Array(forward.reversed.toList());
      final backward = _applyBiquad(revForward, coeffs);
      return Array(backward.reversed.toList());
    }

    final startPad = _buildPadStart(data, padLen);
    final endPad = _buildPadEnd(data, padLen);
    final padded = [
      ...startPad,
      ...List<double>.from(data),
      ...endPad,
    ];

    final paddedArray = Array(padded);
    final forward = _applyBiquad(paddedArray, coeffs);
    final revForward = Array(forward.reversed.toList());
    final backward = _applyBiquad(revForward, coeffs);
    final filtered = Array(backward.reversed.toList());
    return Array(filtered.sublist(padLen, padLen + data.length));
  }

  static Array _applyBiquad(Array data, _BiquadCoefficients coeffs) {
    final output = List<double>.filled(data.length, 0.0);
    double x1 = 0.0, x2 = 0.0, y1 = 0.0, y2 = 0.0;
    for (int i = 0; i < data.length; i++) {
      final double x0 = data[i];
      final double y0 = coeffs.b0 * x0 +
          coeffs.b1 * x1 +
          coeffs.b2 * x2 -
          coeffs.a1 * y1 -
          coeffs.a2 * y2;
      output[i] = y0;
      x2 = x1;
      x1 = x0;
      y2 = y1;
      y1 = y0;
    }
    return Array(output);
  }

  static List<double> _buildPadStart(Array data, int padLen) {
    final pad = <double>[];
    for (int i = padLen; i >= 1; i--) {
      pad.add(2 * data[0] - data[i]);
    }
    return pad;
  }

  static List<double> _buildPadEnd(Array data, int padLen) {
    final pad = <double>[];
    for (int i = data.length - 2; i >= data.length - padLen - 1; i--) {
      pad.add(2 * data.last - data[i]);
    }
    return pad;
  }

  _BiquadCoefficients _designButterworthLowPass(
    int order,
    double cutoffHz,
    double fs,
  ) {
    if (order != 2) {
      throw ArgumentError('Only 2nd-order Butterworth filters are supported');
    }

    final double w0 = 2 * math.pi * cutoffHz / fs;
    final double cosw0 = math.cos(w0);
    final double sinw0 = math.sin(w0);
    final double q = math.sqrt(2) / 2;
    final double alpha = sinw0 / (2 * q);

    double b0 = (1 - cosw0) / 2;
    double b1 = 1 - cosw0;
    double b2 = (1 - cosw0) / 2;
    double a0 = 1 + alpha;
    double a1 = -2 * cosw0;
    double a2 = 1 - alpha;

    b0 /= a0;
    b1 /= a0;
    b2 /= a0;
    a1 /= a0;
    a2 /= a0;

    return _BiquadCoefficients(b0, b1, b2, a1, a2);
  }

  static Array _absComplex(ArrayComplex complexArray) {
    return Array(
      List<double>.generate(
        complexArray.length,
        (i) {
          final value = complexArray[i];
          return math.sqrt(
              value.real * value.real + value.imaginary * value.imaginary);
        },
      ),
    );
  }

  static Array _subtractScalar(Array data, double scalar) {
    return Array(data.map((value) => value - scalar).toList(growable: false));
  }

  static Array _subtract(Array a, Array b) {
    return Array(
      List<double>.generate(a.length, (i) => a[i] - b[i]),
    );
  }

  static double _arrayMin(Array data) {
    double minValue = data[0];
    for (int i = 1; i < data.length; i++) {
      if (data[i] < minValue) {
        minValue = data[i];
      }
    }
    return minValue;
  }

  static double _arrayMax(Array data) {
    double maxValue = data[0];
    for (int i = 1; i < data.length; i++) {
      if (data[i] > maxValue) {
        maxValue = data[i];
      }
    }
    return maxValue;
  }

  static Array _add(Array a, Array b) {
    return Array(
      List<double>.generate(a.length, (i) => a[i] + b[i]),
    );
  }

  static Array _multiply(Array a, Array b) {
    return Array(
      List<double>.generate(a.length, (i) => a[i] * b[i]),
    );
  }

  static Array _divideScalar(Array a, double scalar) {
    if (scalar == 0) {
      return Array(List<double>.filled(a.length, 0.0));
    }
    return Array(
      List<double>.generate(a.length, (i) => a[i] / scalar),
    );
  }

  String _getJudgment(double meanError) {
    if (meanError > (normalMeanThreshold + differenceThreshold)) {
      return '⚠️ 비정상 경로 패턴: 운동 기능 장애가 유의미하게 의심됩니다.';
    }
    return '⭕ 정상 범위: 통계적 유의미한 차이 없음';
  }
}

class _BiquadCoefficients {
  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;

  const _BiquadCoefficients(
    this.b0,
    this.b1,
    this.b2,
    this.a1,
    this.a2,
  );
}
