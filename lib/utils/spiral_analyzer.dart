import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Spiral analysis result matching data engineer's code structure
class SpiralAnalysisResult {
  final double meanError;
  final double maxError;
  final String judgment; // Result message (focus on this instead of score)
  final double optimalFc;
  final double dominantTremorFreq;
  final List<Offset> filteredPoints;

  SpiralAnalysisResult({
    required this.meanError,
    required this.maxError,
    required this.judgment,
    required this.optimalFc,
    required this.dominantTremorFreq,
    required this.filteredPoints,
  });
}

/// Spiral Analyzer matching data engineer's MATLAB code structure
class SpiralAnalyzer {
  final double fs; // Sampling frequency (Hz)
  final double
      normalMeanThreshold; // Normal person's mean error threshold (pixels)
  final double differenceThreshold; // Judgment threshold (pixels)
  final int filterOrder;

  SpiralAnalyzer({
    required this.fs,
    this.normalMeanThreshold = 15.0, // Pixel unit example value
    this.differenceThreshold = 5.0, // Pixel unit example value
    this.filterOrder = 6,
  });

  /// Main analysis method matching data engineer's code
  SpiralAnalysisResult analyze({
    required List<Offset> refPoints,
    required List<Offset> userRawPoints,
    required double actualTime, // Test completion time (seconds)
    required double
        actualTremor, // Tremor intensity (px) - from app measurement
  }) {
    // 3.1 Raw data separation
    final xRaw = userRawPoints.map((p) => p.dx).toList();
    final yRaw = userRawPoints.map((p) => p.dy).toList();
    final numPoints = xRaw.length;

    // 3.2 FFT-based Fc auto-optimization (Section 3)
    final xSpectrum = _calculateFFT(xRaw);
    final ySpectrum = _calculateFFT(yRaw);
    final dominantFreq = _findDominantFreq(xSpectrum, ySpectrum);

    // Optimize Fc (cutoff frequency)
    double fcOptimized = math.max(dominantFreq - 1.0, 1.0);
    fcOptimized = math.min(fcOptimized, fs / 2 - 0.1);

    // Safety check: if Fc >= dominant freq, adjust
    if (fcOptimized >= dominantFreq) {
      fcOptimized = math.max(dominantFreq * 0.5, 2.0);
    }

    // 3.3 Filtering (Section 4)
    final xFiltered = _applyZeroPhaseFilter(xRaw, fcOptimized);
    final yFiltered = _applyZeroPhaseFilter(yRaw, fcOptimized);

    // 3.4 Data trimming (assuming filtfilt implementation)
    final trimSamples = filterOrder * 3;
    final startIdx = trimSamples;
    final endIdx = numPoints - trimSamples;

    if (endIdx <= startIdx || endIdx > xFiltered.length) {
      // Not enough data after trimming, use all data
      return _analyzeWithoutTrimming(
        refPoints,
        userRawPoints,
        xFiltered,
        yFiltered,
        fcOptimized,
        dominantFreq,
      );
    }

    final xUse = xFiltered.sublist(startIdx, endIdx);
    final yUse = yFiltered.sublist(startIdx, endIdx);
    final refXUse =
        refPoints.map((p) => p.dx).toList().sublist(startIdx, endIdx);
    final refYUse =
        refPoints.map((p) => p.dy).toList().sublist(startIdx, endIdx);

    // 3.5 Error calculation (Section 5)
    // For same-length data, directly compare
    final errors = <double>[];
    for (int i = 0; i < refXUse.length && i < xUse.length; i++) {
      final diffX = xUse[i] - refXUse[i];
      final diffY = yUse[i] - refYUse[i];
      errors.add(math.sqrt(diffX * diffX + diffY * diffY));
    }

    // 3.6 Statistics calculation (with NaN handling)
    final validErrors = errors.where((e) => !e.isNaN && e.isFinite).toList();
    final meanError = validErrors.isEmpty
        ? 0.0
        : validErrors.reduce((a, b) => a + b) / validErrors.length;
    final maxError = validErrors.isEmpty ? 0.0 : validErrors.reduce(math.max);

    // 3.7 Judgment logic (Section 7) - Focus on result message
    final judgment = _getJudgment(meanError);

    // 3.8 Convert filtered results to Offset list
    final filteredPoints = List.generate(
      xUse.length,
      (i) => Offset(xUse[i], yUse[i]),
    );

    return SpiralAnalysisResult(
      meanError: meanError,
      maxError: maxError,
      judgment: judgment,
      optimalFc: fcOptimized,
      dominantTremorFreq: dominantFreq,
      filteredPoints: filteredPoints,
    );
  }

  /// Fallback analysis when trimming would leave insufficient data
  SpiralAnalysisResult _analyzeWithoutTrimming(
    List<Offset> refPoints,
    List<Offset> userRawPoints,
    List<double> xFiltered,
    List<double> yFiltered,
    double fcOptimized,
    double dominantFreq,
  ) {
    final errors = <double>[];
    final minLength = math.min(
      math.min(refPoints.length, userRawPoints.length),
      math.min(xFiltered.length, yFiltered.length),
    );

    for (int i = 0; i < minLength; i++) {
      final diffX = xFiltered[i] - refPoints[i].dx;
      final diffY = yFiltered[i] - refPoints[i].dy;
      errors.add(math.sqrt(diffX * diffX + diffY * diffY));
    }

    final validErrors = errors.where((e) => !e.isNaN && e.isFinite).toList();
    final meanError = validErrors.isEmpty
        ? 0.0
        : validErrors.reduce((a, b) => a + b) / validErrors.length;
    final maxError = validErrors.isEmpty ? 0.0 : validErrors.reduce(math.max);

    final judgment = _getJudgment(meanError);

    final filteredPoints = List.generate(
      minLength,
      (i) => Offset(xFiltered[i], yFiltered[i]),
    );

    return SpiralAnalysisResult(
      meanError: meanError,
      maxError: maxError,
      judgment: judgment,
      optimalFc: fcOptimized,
      dominantTremorFreq: dominantFreq,
      filteredPoints: filteredPoints,
    );
  }

  // =========================================================================
  // 2. Signal Processing Core Functions
  // =========================================================================

  /// Calculate FFT and return [frequency, amplitude] pairs
  /// Uses existing FFT implementation from FFTAnalyzer
  List<MapEntry<double, double>> _calculateFFT(List<double> data) {
    if (data.isEmpty) return [];

    // Convert to complex numbers
    final List<ComplexNum> complexData =
        data.map((v) => ComplexNum(v, 0)).toList();

    // Use power-of-2 FFT
    final n = data.length;
    int fftSize = 1;
    while (fftSize < n) {
      fftSize *= 2;
    }

    // Pad to power of 2
    while (complexData.length < fftSize) {
      complexData.add(ComplexNum(0, 0));
    }

    // Perform FFT
    final fftResult = _fft(complexData);

    // Convert to magnitude spectrum (single-sided)
    final L = fftSize;
    final spectrum = <MapEntry<double, double>>[];

    // DC component
    spectrum.add(MapEntry(0.0, fftResult[0].magnitude / L));

    // Positive frequencies (single-sided)
    for (int i = 1; i < L ~/ 2; i++) {
      final freq = i * fs / L;
      final amplitude = 2 * fftResult[i].magnitude / L;
      spectrum.add(MapEntry(freq, amplitude));
    }

    // Nyquist frequency
    if (L % 2 == 0) {
      final nyquistFreq = fs / 2;
      final amplitude = fftResult[L ~/ 2].magnitude / L;
      spectrum.add(MapEntry(nyquistFreq, amplitude));
    }

    return spectrum;
  }

  /// Cooley-Tukey FFT algorithm (from FFTAnalyzer)
  List<ComplexNum> _fft(List<ComplexNum> x) {
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

  /// Apply zero-phase filter (Butterworth LPF approximation)
  /// Note: Full Butterworth implementation requires filter design library
  /// This is a simplified approximation using moving average for now
  List<double> _applyZeroPhaseFilter(List<double> data, double fc) {
    // Simplified implementation: moving average filter as approximation
    // In production, this should use proper Butterworth filter with filtfilt
    final windowSize = (fs / fc).round().clamp(3, data.length ~/ 4);
    return _movingAverageFilter(data, windowSize);
  }

  /// Moving average filter (temporary replacement)
  /// Note: This is less accurate than proper Butterworth filtfilt
  List<double> _movingAverageFilter(List<double> data, int window) {
    if (window <= 1 || data.isEmpty) return List<double>.from(data);

    final filtered = List<double>.filled(data.length, 0.0);
    final halfWindow = window ~/ 2;

    for (int i = 0; i < data.length; i++) {
      double sum = 0.0;
      int count = 0;

      for (int j = math.max(0, i - halfWindow);
          j < math.min(data.length, i + halfWindow + 1);
          j++) {
        sum += data[j];
        count++;
      }

      filtered[i] = count > 0 ? sum / count : data[i];
    }

    return filtered;
  }

  // =========================================================================
  // 4. Helper Functions
  // =========================================================================

  /// Find dominant tremor frequency from FFT spectrum
  double _findDominantFreq(
    List<MapEntry<double, double>> xSpectrum,
    List<MapEntry<double, double>> ySpectrum,
  ) {
    double dominantFreq = 0.0;
    double maxAmplitude = 0.0;
    const minFreq = 1.0; // Exclude low-frequency movement below 1Hz

    // Find peak in X-axis
    for (var entry in xSpectrum) {
      if (entry.key > minFreq && entry.value > maxAmplitude) {
        maxAmplitude = entry.value;
        dominantFreq = entry.key;
      }
    }

    // Find peak in Y-axis (update if stronger)
    for (var entry in ySpectrum) {
      if (entry.key > minFreq && entry.value > maxAmplitude) {
        maxAmplitude = entry.value;
        dominantFreq = entry.key;
      }
    }

    // If no dominant frequency found, return default
    if (dominantFreq == 0.0) {
      return 5.0; // Default tremor frequency (Hz)
    }

    return dominantFreq;
  }

  /// Get judgment message based on mean error
  /// Focus on result message rather than score
  String _getJudgment(double meanError) {
    if (meanError > (normalMeanThreshold + differenceThreshold)) {
      return '⚠️ 비정상 경로 패턴: 운동 기능 장애가 유의미하게 의심됩니다.';
    } else {
      return '⭕ 정상 범위: 통계적 유의미한 차이 없음';
    }
  }
}

/// Complex number class for FFT (from FFTAnalyzer)
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
}
