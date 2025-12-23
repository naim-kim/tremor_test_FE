import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;

class ApiClient {
  final String baseUrl;
  ApiClient(this.baseUrl) {
    debugPrint('ApiClient initialized with baseUrl: $baseUrl');
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
      };

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String loginProvider,
  }) async {
    final url = '$baseUrl/api/users';
    debugPrint('Creating user at: $url');
    
    try {
      final uri = Uri.parse(url);
      final resp = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'loginProvider': loginProvider,
        }),
      );

      debugPrint('Create user response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode != 201) {
        throw Exception(
            'Create user failed (${resp.statusCode}): ${resp.body}');
      }
      
      try {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('JSON decode error: $e');
        debugPrint('Response body: ${resp.body}');
        throw Exception('Invalid JSON response: ${resp.body}');
      }
    } catch (e) {
      debugPrint('Error creating user: $e');
      if (e is FormatException) {
        throw Exception('Invalid URL format: $url. Please check your API_BASE_URL in .env file.');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> saveTestCsv({
    required int userId,
    required String testType,
    double? overallScore,
    String? resultCategory,
    double? frequency,
    double? amplitude,
    double? deviationFromBaseline,
    double? testDuration,
    double? averageSpeed,
    double? mean,
    double? std,
    DateTime? performedAt,
    String? csvContent,
    List<int>? imageBytes,
  }) async {
    final url = '$baseUrl/api/tests/csv';
    debugPrint('Saving test CSV at: $url');
    
    try {
      final request = http.MultipartRequest('POST', Uri.parse(url));
      
      // Combine all metadata into a single JSON field to reduce multipart parts
      final metadata = <String, dynamic>{
        'userId': userId,
        'testType': testType,
        if (overallScore != null) 'overallScore': overallScore,
        if (resultCategory != null) 'resultCategory': resultCategory,
        if (frequency != null) 'frequency': frequency,
        if (amplitude != null) 'amplitude': amplitude,
        if (deviationFromBaseline != null) 'deviationFromBaseline': deviationFromBaseline,
        if (testDuration != null) 'testDuration': testDuration,
        if (averageSpeed != null) 'averageSpeed': averageSpeed,
        if (mean != null) 'mean': mean,
        if (std != null) 'std': std,
        if (performedAt != null) 'performedAt': performedAt.toIso8601String(),
        if (csvContent != null) 'csvContent': csvContent,
      };
      
      // Send metadata as single JSON field
      request.fields['metadata'] = jsonEncode(metadata);
      
      // Add image file if provided (for pentagon tests)
      if (imageBytes != null && imageBytes.isNotEmpty && testType == 'pentagon') {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            imageBytes,
            filename: 'pentagon_drawing.png',
          ),
        );
        debugPrint('Including PNG image (${imageBytes.length} bytes)');
      }
      
      final streamedResponse = await request.send();
      final resp = await http.Response.fromStream(streamedResponse);
      
      debugPrint('Save test response: ${resp.statusCode} - ${resp.body}');

      if (resp.statusCode != 201) {
        throw Exception(
            'Save test failed (${resp.statusCode}): ${resp.body}');
      }
      return jsonDecode(resp.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error saving test: $e');
      rethrow;
    }
  }

   Future<List<Map<String, dynamic>>> getUserTests({
    required int userId,
    String? testType,
  }) async {
    final uri = Uri.parse('$baseUrl/api/tests').replace(
      queryParameters: {
        'userId': userId.toString(),
        if (testType != null) 'testType': testType,
      },
    );

    final resp = await http.get(uri, headers: _headers);
    if (resp.statusCode != 200) {
      throw Exception(
          'Get tests failed (${resp.statusCode}): ${resp.body}');
    }
    final decoded = jsonDecode(resp.body);
    if (decoded is List) {
      return decoded.cast<Map<String, dynamic>>();
    }
    throw Exception('Unexpected response format from /api/tests');
  }
}



