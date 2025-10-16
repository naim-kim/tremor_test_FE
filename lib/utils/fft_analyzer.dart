import 'dart:math' as math;
import 'dart:ui';
import '../models/test_result.dart';

/// FFT-based tremor analysis (converted from Java implementation)
class FFTAnalyzer {
  static const int sampleRate = 50; // 50Hz

  /// Perform FFT analysis on drawing points
  static Future<TremorMetrics> analyze(List<DrawingPoint> points) async {
    if (points.isEmpty) {
      return TremorMetrics(
        frequency: 0,
        amplitude: 0,
        deviationFromBaseline: 0,
        testDuration: 0,
        averageSpeed: 0,
        mean: 0,
        std: 0,
      );
    }

    // Extract X and Y coordinates and fill nulls
    final List<double> orgX = points.map((p) => p.x).toList();
    final List<double> orgY = points.map((p) => p.y).toList();
    final List<int> timeList = points.map((p) => p.timestamp).toList();

    final n = points.length;

    // Fill null values (interpolation)
    final filledX = _fillNull(orgX);
    final filledY = _fillNull(orgY);

    // Convert to complex numbers
    final List<ComplexNum> x = filledX.map((v) => ComplexNum(v, 0)).toList();
    final List<ComplexNum> y = filledY.map((v) => ComplexNum(v, 0)).toList();

    // Slice data into power-of-2 segments
    final slices = _dataSlice(n);
    final m = slices.length;

    if (m == 0) {
      // Not enough data
      return _calculateBasicMetrics(points);
    }

    int totalL = 0;
    final List<List<double>> resultX = [];
    final List<List<double>> resultY = [];

    int start = 0;

    // Perform FFT on each segment
    for (int k = 0; k < m; k++) {
      final length = math.pow(2, slices[k]).toInt();
      totalL += length;

      // Extract segment
      final List<ComplexNum> xi =
          x.sublist(start, math.min(start + length, x.length));
      final List<ComplexNum> yi =
          y.sublist(start, math.min(start + length, y.length));

      // Pad to power of 2 if needed
      while (xi.length < length) {
        xi.add(ComplexNum(0, 0));
      }
      while (yi.length < length) {
        yi.add(ComplexNum(0, 0));
      }

      start += length;

      // Perform FFT
      final fftX = _fft(xi);
      final fftY = _fft(yi);

      // Convert to magnitude
      final List<double> absFftX = List.filled(length ~/ 2, 0);
      final List<double> absFftY = List.filled(length ~/ 2, 0);

      absFftX[0] = fftX[0].magnitude / length;
      absFftY[0] = fftY[0].magnitude / length;

      for (int i = 1; i < length ~/ 2; i++) {
        absFftX[i] = 2 * fftX[i].magnitude / length;
        absFftY[i] = 2 * fftY[i].magnitude / length;
      }

      // Calculate frequency indices
      final List<double> index = List.generate(
        length ~/ 2,
        (j) => sampleRate * j / length.toDouble(),
      );

      // Analyze frequency data
      resultX.add(_analyzeFrequency(absFftX, index));
      resultY.add(_analyzeFrequency(absFftY, index));
    }

    // Combine results with weighted average
    final List<double> freqResult = List.filled(5, 0.0);
    for (int j = 0; j < 5; j++) {
      for (int i = 0; i < m; i++) {
        final ratio = math.pow(2, slices[i]) / totalL;
        freqResult[j] += (resultX[i][j] + resultY[i][j]) * ratio * 0.5;
      }
    }

    // Calculate test metrics
    final testDuration = timeList.last / 1000.0; // Convert to seconds
    final totalDistance = _calculateTotalDistance(points);
    final averageSpeed = totalDistance / testDuration;

    return TremorMetrics(
      frequency: freqResult[4], // Hz
      amplitude: freqResult[3], // amp
      deviationFromBaseline: 0, // Will be calculated separately for spiral
      testDuration: testDuration,
      averageSpeed: averageSpeed,
      mean: freqResult[0],
      std: freqResult[1],
    );
  }

  /// Fill null/zero values with interpolation
  static List<double> _fillNull(List<double> input) {
    final n = input.length;
    final List<double> result = List.from(input);

    int nStart = 0;
    int nEnd = 0;
    bool flag = true;

    for (int i = 0; i < n; i++) {
      if (input[i] != 0) {
        if (!flag) {
          nEnd = i;
          final gap = (input[nEnd] - input[nStart]) / (nEnd - nStart);
          final start = input[nStart];
          for (int j = nStart; j < nEnd; j++) {
            result[j] = start + gap * (j - nStart);
          }
          flag = true;
        }
        result[i] = input[i];
        continue;
      }

      if (flag) {
        nStart = i - 1;
        flag = false;
      }
    }

    return result;
  }

  /// Slice data into power-of-2 segments
  static List<int> _dataSlice(int m) {
    final List<int> session = [];
    int n = m;

    while (m > sampleRate * 3) {
      int k = n;
      int i = 0;

      while (k != 1) {
        k = k ~/ 2;
        i++;
      }

      final value = math.pow(2, i).toInt();
      if (value < sampleRate * 2) {
        break;
      } else {
        session.add(i);
      }
      n = n - value;
    }

    return session;
  }

  /// Cooley-Tukey FFT algorithm
  static List<ComplexNum> _fft(List<ComplexNum> x) {
    final n = x.length;

    // Base case
    if (n == 1) return [x[0]];

    // Check if power of 2
    if (n % 2 != 0) {
      throw ArgumentError('n is not a power of 2');
    }

    // FFT of even terms
    final List<ComplexNum> even = [];
    for (int k = 0; k < n ~/ 2; k++) {
      even.add(x[2 * k]);
    }
    final List<ComplexNum> q = _fft(even);

    // FFT of odd terms
    final List<ComplexNum> odd = [];
    for (int k = 0; k < n ~/ 2; k++) {
      odd.add(x[2 * k + 1]);
    }
    final List<ComplexNum> r = _fft(odd);

    // Combine
    final List<ComplexNum> y = List.filled(n, ComplexNum(0, 0));
    for (int k = 0; k < n ~/ 2; k++) {
      final kth = -2 * k * math.pi / n;
      final wk = ComplexNum(math.cos(kth), math.sin(kth));
      y[k] = q[k] + (wk * r[k]);
      y[k + n ~/ 2] = q[k] - (wk * r[k]);
    }

    return y;
  }

  /// Analyze frequency data
  static List<double> _analyzeFrequency(
      List<double> result, List<double> index) {
    final mean = _mean(result);
    final std = _standardDeviation(result);
    final standard = mean + 2 * std;

    // Filter between 3Hz and 15Hz
    int filterS = 0;
    int filterE = result.length - 1;

    for (int i = 0; i < index.length && index[i] <= 3; i++) {
      filterS = i;
    }
    for (int i = 0; i < index.length && index[i] <= 15; i++) {
      filterE = i;
    }

    // Find max amplitude in filtered range
    int maxIndex = filterS;
    for (int i = filterS; i <= math.min(filterE, result.length - 1); i++) {
      if (result[i] >= result[maxIndex]) {
        maxIndex = i;
      }
    }

    final amp = result[maxIndex];
    final hz = index[maxIndex];

    return [mean, std, standard, amp, hz];
  }

  /// Calculate mean
  static double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  /// Calculate standard deviation
  static double _standardDeviation(List<double> values) {
    if (values.length < 2) return 0;
    final mean = _mean(values);
    final sumSquares = values.fold<double>(
      0,
      (sum, value) => sum + math.pow(value - mean, 2),
    );
    return math.sqrt(sumSquares / (values.length - 1));
  }

  /// Calculate total distance traveled
  static double _calculateTotalDistance(List<DrawingPoint> points) {
    if (points.length < 2) return 0;

    double distance = 0;
    for (int i = 1; i < points.length; i++) {
      final dx = points[i].x - points[i - 1].x;
      final dy = points[i].y - points[i - 1].y;
      distance += math.sqrt(dx * dx + dy * dy);
    }
    return distance;
  }

  /// Calculate basic metrics when FFT cannot be performed
  static TremorMetrics _calculateBasicMetrics(List<DrawingPoint> points) {
    final testDuration = points.last.timestamp / 1000.0;
    final totalDistance = _calculateTotalDistance(points);
    final averageSpeed = totalDistance / testDuration;

    return TremorMetrics(
      frequency: 0,
      amplitude: 0,
      deviationFromBaseline: 0,
      testDuration: testDuration,
      averageSpeed: averageSpeed,
      mean: 0,
      std: 0,
    );
  }

  /// Calculate deviation from baseline (for spiral test)
  static double calculateDeviationFromBaseline(
    List<DrawingPoint> userPoints,
    List<Offset> baselinePoints,
  ) {
    if (userPoints.isEmpty || baselinePoints.isEmpty) return 0;

    final List<double> distances = [];

    for (final userPoint in userPoints) {
      // Find closest baseline point
      double minDistance = double.infinity;
      for (final basePoint in baselinePoints) {
        final dx = userPoint.x - basePoint.dx;
        final dy = userPoint.y - basePoint.dy;
        final distance = math.sqrt(dx * dx + dy * dy);
        if (distance < minDistance) {
          minDistance = distance;
        }
      }
      distances.add(minDistance);
    }

    // Return mean distance
    return _mean(distances);
  }
}

/// Complex number class for FFT
class ComplexNum {
  final double real;
  final double imaginary;

  ComplexNum(this.real, this.imaginary);

  double get magnitude => math.sqrt(real * real + imaginary * imaginary);

  double get phase => math.atan2(imaginary, real);

  ComplexNum operator +(ComplexNum other) {
    return ComplexNum(real + other.real, imaginary + other.imaginary);
  }

  ComplexNum operator -(ComplexNum other) {
    return ComplexNum(real - other.real, imaginary - other.imaginary);
  }

  ComplexNum operator *(ComplexNum other) {
    return ComplexNum(
      real * other.real - imaginary * other.imaginary,
      real * other.imaginary + imaginary * other.real,
    );
  }

  ComplexNum scale(double factor) {
    return ComplexNum(real * factor, imaginary * factor);
  }

  ComplexNum get conjugate => ComplexNum(real, -imaginary);
}
